--主入口
local rediscmd = require('utils.rediscmd')
local config = require('config.init')
local check = require('utils.check')
local headers = ngx.req.get_headers()
local limitcmd = require('interface.limit.limitindex')
local upgradecmd = require('interface.upgrade.upindex')

local socket = require("socket")


--获取请求url
local url = ngx.var.uri
if url == '/scmccClient/servlet/chargeNotify.do' then --充值回调直接返回
	return
end
--获取当前web服务连接数
local active = tonumber(ngx.var.connections_active)
if not active then
    active = 0
end
--获取源地址，当多NAT后只取最后一组（公网IP）
local IP = headers['X_FORWARDED_FOR'] or ngx.var.remote_addr
if type(IP) == 'table' then
	local tlen = table.getn(IP)
	IP = IP[tlen]
end


--根据缓存可用性选用随机精确值
local status = check:checkredis()
if not status then
--获取请求随机数毫秒级，可用于防刷操作
	math.randomseed(tostring(socket.gettime()):reverse():sub(1, 10)) 
	rdm = math.random(1,100)
	local grade1,err = rediscmd:hget('limit','grade1')
	local grade2,err = rediscmd:hget('limit','grade2')
	local grade3,err = rediscmd:hget('limit','grade3')
else
--获取请求随机数秒级
	math.randomseed(tostring(os.time()):reverse():sub(1, 10))
	rdm = math.random(1,100)
end

local ckv = ngx.var["cookie_SmsNoPwdLoginCookie"]
if not ckv then
	ckv = 'xwtec'
end

local info = {
	['id'] = ckv,
	['active'] = active,
	['url'] = url,
	['grade1'] = tonumber(grade1) or 30,
	['grade2'] = tonumber(grade1) or 60,
	['grade3'] = tonumber(grade1) or 90,
	['rdm'] = rdm,
	['hostip'] = config.Service.hostip,
	['IP'] = IP or '192.168.1.33',
	['CHANNEL'] = headers['channel'] or 'xwtec',
	['VERSION'] = headers['version'] or '0.0.1',
	['PHONE'] = ngx.var['cookie_SmsNoPwdLoginCookie'] or '10086',
	['Date'] = os.date(),
	['Time'] = os.date("%Y")..os.date("%m")..os.date("%d")..os.date("%H"),
	['Limitkey'] = 'limit',
	['Upgradekey'] = 'upgrade',
}
local info_limit = setmetatable({['status'] = 'limit'},{__index = info})
local info_pass = setmetatable({['status'] = 'pass'},{__index = info})

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

local status = check:checkredis()
if not status then
	limitcmd:limit(info_pass,info_limit)
else
	local switch,err = rediscmd:hget('upgrade','switch')
	local proxy,err = rediscmd:hget('upgrade','proxy')
	if switch == 'on' and proxy then
		upgradecmd:upgrade(proxy,info_pass,info_limit)
	else
		limitcmd:limit(info_pass,info_limit)
	end
end

--]]