--upgrade入口　
local _M = {}
local rediscmd = require('interface.utils.rediscmd')
local ProxyMod = require('interface.upgrade.proxy')

local key = 'upgrade'
_M.upgrade_switch = function(self,field)
	local status,err = rediscmd:hget(key,field)
	if not status or status == 'off' then
		return 'off'
	end
	return 'on'
end
_M.upgrade_proxy = function(self,field)
	local proxy,err = rediscmd:hget(key,field)
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
			if type(info_pass.IP) ~= 'table' then
				ProxyMod:proxy_ip(ok,info_pass.IP,info_pass,info_limit)
				return
			else
				return
			end
		elseif field[1] == 'proxy_head' then
			ProxyMod:proxy_head(ok,info_pass.CHANNEL,info_pass,info_limit)
			return
		elseif field[1] == 'proxy_phone' then
			ProxyMod:proxy_phone(ok,info_pass.PHONE,info_pass,info_limit)
			return
		elseif field[1] == 'proxy_version' then
			ProxyMod:proxy_version(ok,info_pass.VERSION,info_pass,info_limit)
			return
		else
			return
		end
	else
		local REQINFO = {info_pass.IP,info_pass.CHANNEL,info_pass.VERSION,info_pass.PHONE}
		ProxyMod:proxy_association(field,REQINFO,info_pass,info_limit)
		return
	end
end

return _M