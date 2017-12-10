--upgrade入口　
local _M = {}
local rediscmd = require('interface.utils.rediscmd')
local ProxyMod = require('interface.upgrade.proxy')
-- local limit = require('interface.limit.limit')
-- local socket = require("socket")

local log = ngx.log
local ERR = ngx.ERR

local headers = ngx.req.get_headers()
local IP = headers['X_FORWARDED_FOR'] or ngx.var.remote_addr
local CHANNEL = headers['channel']
local VERSION = headers['version']
local PHONE = ngx.var['cookie_SmsNoPwdLoginCookie']
if not (IP and CHANNEL and VERSION and PHONE) then return end

-- if type(IP) ~= 'table' then  --多NAT后,源IP有多个,类型为table
-- 	log(ERR,IP..'|'..CHANNEL..'|'..VERSION..'|'..PHONE)
-- end
local key = 'upgrade'
_M.upgrade_switch = function(self)
	local status,err = rediscmd:hget(key,'switch')
	if not status or status == 'off' then
		return nil
	end
	return true
end
_M.upgrade_proxy = function(self)
	local proxy,err = rediscmd:hget(key,'proxy')
	if not proxy then
		return nil
	end
	return proxy
end

local function StrToTable(str)
    if str == nil or type(str) ~= "string" then
        return
    end
    return loadstring("return " .. str)()
end

_M.upgrade = function(self,option,info_pass,info_limit)
	local tproxy = StrToTable(option)
	local field = {}
	if type(tproxy) == 'table' then
		for k,v  in pairs(tproxy) do
			table.insert(field,table.concat({'proxy',v},"_" ))
		end
	else
		table.insert(field,table.concat({'proxy',option},'_'))
	end
	if table.getn(field) == 1 then
		local ok,err = rediscmd:hget(key,field[1])
		if not ok then
			return
		end
		if field[1] == 'proxy_ip' then
			if type(IP) ~= 'table' then
				ProxyMod:proxy_ip(ok,IP,info_pass,info_limit)
			else
				return
			end
		elseif field[1] == 'proxy_head' then
			ProxyMod:proxy_head(ok,CHANNEL,info_pass,info_limit)
		elseif field[1] == 'proxy_phone' then
			ProxyMod:proxy_phone(ok,PHONE,info_pass,info_limit)
		elseif field[1] == 'proxy_version' then
			ProxyMod:proxy_version(ok,VERSION,info_pass,info_limit)
		else
			return
		end
	else
		local REQINFO = {IP,CHANNEL,VERSION,PHONE}
		local serverip,serr = rediscmd:hget('upgrade','update')
		-- ngx.say(info_pass.status,info_limit.status)
		ProxyMod:proxy_association(field,REQINFO,info_pass,info_limit)
	end
end

return _M