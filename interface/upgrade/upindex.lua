--upgrade入口　
local _M = {}
local rediscmd = require('utils.rediscmd')
local ProxyMod = require('interface.upgrade.proxy')
local retype = require('utils.type-conv')


_M.upgrade = function(self,option,info_pass,info_limit,uniq)
	local tproxy = retype:StrToTable(option)
	local field = {}
	if type(tproxy) == 'table' then
		for k,v  in pairs(tproxy) do
			table.insert(field,table.concat({'proxy',v},"_" ))
		end
	else
		table.insert(field,table.concat({'proxy',option},'_'))
	end
	if table.getn(field) == 1 then
		local ok,err = rediscmd:hget('upgrade',field[1])
		if not ok then
			return
		end
		if field[1] == 'proxy_ip' then
			if type(info_pass.IP) ~= 'table' then
				ProxyMod:proxy_ip(ok,info_pass.IP,info_pass,info_limit)
			end
		elseif field[1] == 'proxy_head' then
			ProxyMod:proxy_head(ok,info_pass.CHANNEL,info_pass,info_limit)
		elseif field[1] == 'proxy_phone' then
			ProxyMod:proxy_phone(ok,info_pass.PHONE,info_pass,info_limit)
		elseif field[1] == 'proxy_version' then
			ProxyMod:proxy_version(ok,info_pass.VERSION,info_pass,info_limit)
		end
	else
		local REQINFO = {info_pass.IP,info_pass.CHANNEL,info_pass.VERSION,info_pass.PHONE}
		ProxyMod:proxy_association(field,REQINFO,info_pass,info_limit,uniq)
	end
end

return _M