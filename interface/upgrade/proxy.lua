--proxy
local _M = {}

local rediscmd = require('utils.rediscmd')
local up_upstream = require('interface.upgrade.upstream')
local limitcmd = require('interface.limit.limitindex')
local retype = require('utils.type-conv')

_M.proxy_ip = function(self,option,IP,info_pass,info_limit) --{'192.168.1.200'}
	local OtoT = retype:StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == IP then
			up_upstream:upstream(info_pass,info_limit)
		else
			limitcmd:limit(info_pass,info_limit)
		end
	end
end

_M.proxy_head = function(self,option,CHANNEL,info_pass,info_limit) --{'xwtec'}
	local OtoT = retype:StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == CHANNEL then
			up_upstream:upstream(info_pass,info_limit)
		else
			limitcmd:limit(info_pass,info_limit)
		end
	end
end

_M.proxy_phone = function(self,option,PHONE,info_pass,info_limit) --{'13693464'}
	local OtoT = retype:StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == PHONE then
			up_upstream:upstream(info_pass,info_limit)
		else
			limitcmd:limit(info_pass,info_limit)
		end
	end
end

_M.proxy_version = function(self,option,VERSION,info_pass,info_limit) --{'3.4.0'}
	local OtoT = retype:StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == VERSION then
			up_upstream:upstream(info_pass,info_limit)
		else
			limitcmd:limit(info_pass,info_limit)
		end
	end
end

_M.proxy_association = function(self,option,REQINFO,info_pass,info_limit,uniq) --proxy {'ip','phone','version','head'}多策略组合平滑升级 --{'ip','phone'}
		local PP = {}
		local key = info_pass.Upgradekey
		for pk,pv in pairs(option) do
			local ok,err = rediscmd:hget(key,pv)
			local oktotable = retype:StrToTable(ok)
			if type(oktotable) == 'table' then
				for okk,okv in pairs(oktotable) do
					table.insert(PP,okv)
				end
			else
					table.insert(PP,ok)
			end
		end
		if uniq == 'off' then
			local temp = {}
			for kR,vR in pairs(REQINFO) do
				for kP,vP in pairs(PP) do
					if vR == vP then
						table.insert(temp,vR)
					end
				end
			end
			local tlen = table.getn(temp)
			if tlen >= 1 then
				up_upstream:upstream(info_pass,info_limit)
			else
				limitcmd:limit(info_pass,info_limit)
			end
		else
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
				limitcmd:limit(info_pass,info_limit)
			end
		end	
end
return _M