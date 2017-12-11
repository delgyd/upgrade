----limit.lua
local _M = {}
local rediscmd = require('interface.utils.rediscmd')
-- local upgrade = require('interface.upgrade.upindex')
local socket = require("socket")

local key = 'limit'

--local limitlog = '/data/webapp/logs/limit_log/lua-'..os.date("%Y")..os.date("%m")..os.date("%d")..os.date("%H")..'.log'
local limitlog = '/data/webapp/openresty/nginx/logs/lua-'..os.date("%Y")..os.date("%m")..os.date("%d")..os.date("%H")..'.log'
local limitinfo = '['..os.date()..']'

local function writefile(filename, info)
    local wfile=io.open(filename, "a+")
    assert(wfile)
    wfile:write(info,'\n')
    wfile:close()
end

local limit_server = function(self)
	if self.servermod == 'scmccClient' then
		writefile(limitlog,limitinfo..'|'..self.url..'|'..self.active..'|'..self.id..'|'..self.status..'|')
		ngx.redirect("/limit_json")
	elseif self.servermod == 'scmccClientWap' then
		writefile(limitlog,limitinfo..'|'..self.url..'|'..self.active..'|'..self.id..'|'..self.status..'|')
		ngx.redirect('/limit_static/index.html')
	elseif self.servermod == 'scmccCampaign' then
		writefile(limitlog,limitinfo..'|'..self.url..'|'..self.active..'|'..self.id..'|'..self.status..'|')
		ngx.redirect('/limit_static/index.html')
	elseif self.servermod == 'scmcc' then
		writefile(limitlog,limitinfo..'|'..self.url..'|'..self.active..'|'..self.id..'|'..self.status..'|')
		ngx.redirect('/limit_static/index.html')
	end
end
local carry_redis = function (self)
	local ok,err = rediscmd:exists(self.id)
	if err == 'ERR handle response, backend conn reset' then
		if self.status == 'limit' then
			limit_server(self)
		elseif self.status == 'pass' then
			writefile(limitlog,limitinfo..'|'..self.url..'|'..self.active..'|'..self.id..'|'..self.status..'|')
		end
	end
	if ok == 0  then
		local ok,err = rediscmd:hset(self.id,'status',self.status)
		if not ok then return end
		local ok,err = rediscmd:hset(self.id,self.url,1)
		if not ok then return end
		local ok,err = rediscmd:hset(self.id,'ACTIVE',self.active)
		if not ok then return end
		local ok,err = rediscmd:expire(self.id,60)
		if not ok then return end
		if self.status == 'limit' then
			limit_server(self)
		elseif self.status == 'pass' then
			writefile(limitlog,limitinfo..'|'..self.url..'|'..self.active..'|'..self.id..'|'..self.status..'|')
		end
	elseif ok == 1 then
		local ok,err = rediscmd:hget(self.id,"status")
		if ok == 'limit' then
			self.status = 'limit'
			limit_server(self)
		elseif ok == 'pass' then
			self.status = 'pass'
			local ok,err = rediscmd:hincrby(self.id,self.url,1)
			if ok >= 30 then
				local ok,err = rediscmd:hset(self.id,'status','limit')
				if not ok then return end
				writefile(limitlog,limitinfo..'|'..self.url..'|'..self.active..'|'..self.id..'|'..self.status..'|')
				writefile(limitlog,limitinfo..'|'..self.url..'|'..self.active..'|'..self.id..'|'..'The next request will be rejected'..'|')
			else
				writefile(limitlog,limitinfo..'|'..self.url..'|'..self.active..'|'..self.id..'|'..self.status..'|')
				return
			end
		end
	end
end
_M.limit = function(self,info_pass,info_limit)
	if info_pass.active >= 1 and info_pass.active < 600 then
		if  info_pass.rdm <= info_pass.grade1 then
			carry_redis(info_limit)
		else
			carry_redis(info_pass)
		end
	elseif info_pass.active >= 600 and info_pass.active < 800 then
		if  info_pass.rdm <= info_pass.grade2 then
			carry_redis(info_limit)
		else
			carry_redis(info_pass)
		end
	elseif info_pass.active >= 800 and info_pass.active < 1000 then
		if  info_pass.rdm <= info_pass.grade3 then
			carry_redis(info_limit)
		else
			carry_redis(info_pass)
		end
	elseif info_pass.active >=1100 then
			carry_redis(info_limit)
	end
end

return _M