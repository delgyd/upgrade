--proxy
local _M = {}

local rediscmd = require('interface.utils.rediscmd')
local up_upstream = require('interface.upgrade.upstream')
local limit_mode = require('interface.limit.limitindex')
local key = 'upgrade'

local function StrToTable(str)
    if str == nil or type(str) ~= "string" then
        return
    end
    return loadstring("return " .. str)()
end

_M.proxy_ip = function(self,option,IP,info_pass,info_limit) --{'192.168.1.200'}
	local OtoT = StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == IP then
			up_upstream:upstream()
		else
			limit_mode:limit(info_pass,info_limit)
		end
	end
end

_M.proxy_head = function(self,option,CHANNEL,info_pass,info_limit) --{'xwtec'}
	local OtoT = StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == CHANNEL then
			up_upstream:upstream()
		else
			limit_mode:limit(info_pass,info_limit)
		end
	end
end

_M.proxy_phone = function(self,option,PHONE,info_pass,info_limit) --{'13693464'}
	local OtoT = StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == PHONE then
			up_upstream:upstream()
		else
			limit_mode:limit(info_pass,info_limit)
		end
	end
end

_M.proxy_version = function(self,option,VERSION,info_pass,info_limit) --{'3.4.0'}
	local OtoT = StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == VERSION then
			up_upstream:upstream()
		else
			limit_mode:limit(info_pass,info_limit)
		end
	end
end

_M.proxy_association = function(self,option,REQINFO,info_pass,info_limit) --proxy {'ip','phone','version','head'}多策略组合平滑升级 --{'ip','phone'}
		local PP = {}
		for pk,pv in pairs(option) do
			local ok,err = rediscmd:hget(key,pv)
			local oktotable = StrToTable(ok)
			if type(oktotable) == 'table' then
				for okk,okv in pairs(oktotable) do
					table.insert(PP,okv)
				end
			else
					table.insert(PP,okv)
			end
		end

		local temp = {}
		for kR,vR in pairs(REQINFO) do
			for kP,vP in pairs(PP) do
				if vR == vP then
					table.insert(temp,vR)
				end
			end
		end

		local tlen = table.getn(temp)
		local olen = table.getn(option)
		if tlen >= olen then
			up_upstream:upstream(info_pass,info_limit)
		else
			limit_mode:limit(info_pass,info_limit)
		end	
end
return _M