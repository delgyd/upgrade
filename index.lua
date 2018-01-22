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

--[[
--获取本机IP函数方法
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

--根据缓存可用性选用随机精确值
local status = check:checkredis()
if not status then
--获取请求随机数毫秒级，可用于防刷操作
	math.randomseed(tostring(socket.gettime()):reverse():sub(1, 10)) 
	rdm = math.random(1,100)
else
--获取请求随机数秒级
	math.randomseed(tostring(os.time()):reverse():sub(1, 10))
	rdm = math.random(1,100)
end

local ckv = ngx.var["cookie_SmsNoPwdLoginCookie"]
if not ckv or ckv == ngx.null or ckv == "" then
	ckv = 'scmcc'
end

local info = {
	['id'] = ckv,
	['active'] = active,
	['url'] = url,
	-- ['grade1'] = tonumber(grade1) or 30,
	-- ['grade2'] = tonumber(grade1) or 60,
	-- ['grade3'] = tonumber(grade1) or 90,
	['grade1'] = tonumber(config.Limit.L1) or 30,
	['grade2'] = tonumber(config.Limit.L2) or 60,
	['grade3'] = tonumber(config.Limit.L3) or 90,
	['rdm'] = rdm,
	['hostip'] = config.Service.hostip,
	-- ['hostip'] = hostip,
	['IP'] = IP or '192.168.1.33',
	['CHANNEL'] = headers['channel'] or 'xwtec',
	['VERSION'] = headers['version'] or '0.0.1',
	['PHONE'] = ngx.var['cookie_SmsNoPwdLoginCookie'] or '10086',
	['Date'] = os.date(),
	['Time'] = os.date("%Y")..os.date("%m")..os.date("%d")..os.date("%H"),
	['Limitkey'] = 'limit',
	['Upgradekey'] = 'upgrade',
	['servermod'] = config.Service.service,
}
local info_limit = setmetatable({['status'] = 'limit'},{__index = info})
local info_pass = setmetatable({['status'] = 'pass'},{__index = info})

local status = check:checkredis()
if not status then
	info_pass['Redis_status'] = 'off'
	info_limit['Redis_status'] = 'off'
	limitcmd:limit(info_pass,info_limit)
else
	local brushproof,err = rediscmd:hget('limit','brushproof')
	if brushproof then
		info_pass['brushproof'] = brushproof
		info_limit['brushproof'] = brushproof
	else
		info_pass['brushproof'] = 'off'
		info_limit['brushproof'] = 'off'
	end
	info_pass['Redis_status'] = 'on'
	info_limit['Redis_status'] = 'on'
	local id_active,err = rediscmd:hget(info_pass.id,'ACTIVE')
	if id_active == nil then 
		limitcmd:limit(info_pass,info_limit)
	else
		if tonumber(id_active) < 300  and active < 300 then
			local switch,err = rediscmd:hget('upgrade','switch')
			local proxy,err = rediscmd:hget('upgrade','proxy')
			if switch == 'on' and proxy then
				upgradecmd:upgrade(proxy,info_pass,info_limit)
			else
				limitcmd:limit(info_pass,info_limit)
			end
		else
			limitcmd:limit(info_pass,info_limit)
		end
	end
end