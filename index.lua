----lua_index.lua
--1、判断限流，为常开
--2、判断平滑，为可选
local rediscmd = require('interface.utils.rediscmd')
local limit_mode = require('interface.limit.limitindex')
local upgrade = require('interface.upgrade.upindex')
local socket = require("socket")

local function writefile_log(filename, info)
    local wfile=io.open(filename, "a+")
    assert(wfile)
    wfile:write(info,'\n')
    wfile:close()
end
local limitlog = '/data/webapp/openresty/nginx/logs/lua-'..os.date("%Y")..os.date("%m")..os.date("%d")..os.date("%H")..'.log'
local limitinfo = '['..os.date()..']'
writefile_log(limitlog,'xxxxx')


local url = ngx.var.uri
if url == '/scmccClient/servlet/chargeNotify.do' then --充值回调
	return
end
--[[
-影响执行性能
--获取本机IP
local function GetAdd(hostname)
	local ip, resolved = socket.dns.toip(hostname)
	local ListTab = {}
	for k, v in ipairs(resolved.ip) do
		table.insert(ListTab, v)
	end
	return ListTab
end
	--获取本服务器IP
local hostip = unpack(GetAdd(socket.dns.gethostname()))
--]]

--获取当前连接数
local active = tonumber(ngx.var.connections_active)
if not active then
    active = 0
end
--根据缓存可用性选用随机精确值
local ok,err = rediscmd:ping()
if ok == 'PONG' then
	--获取请求随机数毫秒级，可用于防刷操作
	math.randomseed(tostring(socket.gettime()):reverse():sub(1, 10)) 
	rdm = math.random(1,100)
else
	--获取请求随机数秒级
	math.randomseed(tostring(os.time()):reverse():sub(1, 10))
	rdm = math.random(1,100)
end

--获取用户ID
local ckv = ngx.var["cookie_SmsNoPwdLoginCookie"]
if not ckv then return end

local headers = ngx.req.get_headers()
local IP = headers['X_FORWARDED_FOR'] or ngx.var.remote_addr
if type(IP) == 'table' then return end

local grade1,err = rediscmd:hget('limit','grade1')
local grade2,err = rediscmd:hget('limit','grade2')
local grade3,err = rediscmd:hget('limit','grade3')

local info_limit = {
	['id'] = ckv,
	['status'] = 'limit',
	['active'] = active,
	['url'] = url,
	['grade1'] = tonumber(grade1) or 30,
	['grade2'] = tonumber(grade1) or 60,
	['grade3'] = tonumber(grade1) or 90,
	['rdm'] = rdm,
	['hostip'] = ngx.var.serverip,
	['IP'] = IP or '192.168.1.33',
	['CHANNEL'] = headers['channel'] or 'xwtec',
	['VERSION'] = headers['version'] or '0.0.1',
	['PHONE'] = ngx.var['cookie_SmsNoPwdLoginCookie'] or '10086',
}
local info_pass = {
	['id'] = ckv,
	['status'] = 'pass',
	['active'] = active,
	['url'] = url,
	['grade1'] = tonumber(grade1) or 30,
	['grade2'] = tonumber(grade1) or 60,
	['grade3'] = tonumber(grade1) or 90,
	['rdm'] = rdm,
	['hostip'] = ngx.var.serverip,
	['IP'] = IP or '192.168.1.33',
	['CHANNEL'] = headers['channel'] or 'xwtec',
	['VERSION'] = headers['version'] or '0.0.1',
	['PHONE'] = ngx.var['cookie_SmsNoPwdLoginCookie'] or '10086',
}

--获取黑白名单；黑名单请求限制访问，白名单请求，只直接跳过,黑名单将info_pass状态重置为limit

local whiteid,err = rediscmd:sismember('limit_white_list',ckv)
local whiteurl,err = rediscmd:sismember('limit_white_list',url)
if whiteid == 1 or whiteurl == 1 then
	writefile(limitlog,limitinfo..'|'..url..'|'..active..'|'..ckv..'|'..'pass'..'白名单请求')
	return
end
local blackid,err = rediscmd:sismember('limit_black_list',ckv)
local blackurl,err = rediscmd:sismember('limit_black_list',url)
if blackid == 1 or blackurl == 1 then
	info_pass['status'] = 'limit'
	writefile(limitlog,limitinfo..'|'..url..'|'..active..'|'..ckv..'|'..'limit'..'黑名单请求')
end

--根据url匹配业务模块scmccClient/scmccClientWap/scmccCampaign/xxxxx
if url == "/scmccClient/action.dox" or url == "/scmccClient/action.dox?" then
	info_limit['servermod'] = 'scmccClient'
	info_pass['servermod'] = 'scmccClient'
elseif string.find(url,"scmccClientWap") then
	info_limit['servermod'] = 'scmccClientWap'
	info_pass['servermod'] = 'scmccClientWap'
elseif string.find(url,"scmccCampaign") then
	info_limit['servermod'] = 'scmccCampaign'
	info_pass['servermod'] = 'scmccCampaign'
else
	info_limit['servermod'] = 'scmcc'
	info_pass['servermod'] = 'scmcc'
end

local upgrade_switch,err = upgrade:upgrade_switch('switch') -- on/off/nil
local upgrade_proxy,err = upgrade:upgrade_proxy('proxy') --true/nil
if upgrade_switch == 'off' or upgrade_switch == nil then
	limit_mode:limit(info_pass,info_limit)
elseif upgrade_switch == 'on' and upgrade_proxy then
		upgrade:upgrade(upgrade_proxy,info_pass,info_limit)
else
	limit_mode:limit(info_pass,info_limit)
end