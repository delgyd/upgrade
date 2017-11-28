--proxy
local _M = {}
local log = ngx.log
local ERR = ngx.ERR
local INFO = ngx.INFO
local WARN = ngx.WARN
local DEBUG = ngx.DEBUG

local headers = ngx.req.get_headers()

local conf = require('interface.init')
local redisconf = conf.Redis
local rediscmd = require('interface.utils.rediscmd')
local redis = require('interface.utils.redismod')
local up_upstream = require('interface.upstream')


local function StrToTable(str)
    if str == nil or type(str) ~= "string" then
        return
    end
    return loadstring("return " .. str)()
end

_M.proxy_ip = function(self,option) --{'192.168.1.200'}
	local IP = headers['X_FORWARDED_FOR'] or ngx.var.remote_addr
	local OtoT = StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == IP then
			up_upstream:upstream()
		end
	end
end

_M.proxy_head = function(self,option) --{'xwtec'}
	local CHANNEL = headers['channel']
	local OtoT = StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == CHANNEL then
			up_upstream:upstream()
		end
	end
end

_M.proxy_phone = function(self,option) --{'13693464'}
	local PHONE = ngx.var['cookie_SmsNoPwdLoginCookie']
	local OtoT = StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == PHONE then
			up_upstream:upstream()
		end
	end
end

_M.proxy_version = function(self,option) --{'3.4.0'}
	local VERSION = headers['version']
	local OtoT = StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == VERSION then
			up_upstream:upstream()
		end
	end
end

_M.proxy_association = function(self,option) --proxy {'ip','phone','version','head'}多策略组合平滑升级 --{'ip','phone'}
		local IP = headers['X_FORWARDED_FOR'] or ngx.var.remote_addr
		local CHANNEL = headers['channel']
		local VERSION = headers['version']
		local PHONE = ngx.var['cookie_SmsNoPwdLoginCookie']
		local REQINFO = {IP,CHANNEL,VERSION,PHONE}
		local PP = {}
		for pk,pv in pairs(option) do
			local ok,err = rediscmd:hget('upgrade',pv)
			if not ok then ngx.say('redis bad') end
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
					up_upstream:upstream("key")
		else
			return
		end	
		--]]
end
return _M