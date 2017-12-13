----limit.lua
local _M = {}
local rediscmd = require('interface.utils.rediscmd')
local socket = require("socket")

local key = 'limit'

local limitlog = '/data/webapp/openresty/nginx/logs/lua-'..os.date("%Y")..os.date("%m")..os.date("%d")..os.date("%H")..'.log'
local limitinfo = '['..os.date()..']'

local function writefile(filename, info)
    local wfile=io.open(filename, "a+")
    assert(wfile)
    wfile:write(info,'\n')
    wfile:close()
end

local limit_server = function(self,opt)
	if opt.servermod == 'scmccClient' then
		writefile(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
		ngx.redirect("/limit_json")
		return
	elseif opt.servermod == 'scmccClientWap' then
		writefile(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
		ngx.redirect('/limit_static/index.html')
		return
	elseif opt.servermod == 'scmccCampaign' then
		writefile(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
		ngx.redirect('/limit_static/index.html')
		return
	elseif opt.servermod == 'scmcc' then
		writefile(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
		ngx.redirect('/limit_static/index.html')
		return
	end
end
local carry_redis = function (self,opt)
	local ok,err = rediscmd:exists(opt.id)
	if err == 'ERR handle response, backend conn reset' then
		if opt.status == 'limit' then
			limit_server(opt)
			return
		elseif opt.status == 'pass' then
			writefile(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
			return
		end
	end
	if ok == 0  then
		local ok,err = rediscmd:hset(opt.id,'status',opt.status)
		if not ok then return end
		local ok,err = rediscmd:hset(opt.id,opt.url,1)
		if not ok then return end
		local ok,err = rediscmd:hset(opt.id,'ACTIVE',opt.active)
		if not ok then return end
		local ok,err = rediscmd:expire(opt.id,120)
		if not ok then return end
		if opt.status == 'limit' then
			limit_server(opt)
			return
		elseif opt.status == 'pass' then
			writefile(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
			return
		end
	elseif ok == 1 then
		local ok,err = rediscmd:hget(opt.id,"status")
		if ok == 'limit' then
			opt.status = 'limit'
			limit_server(opt)
		elseif ok == 'pass' then
			opt.status = 'pass'
			local ok,err = rediscmd:hincrby(opt.id,opt.url,1)
			if ok >= 50 then
				local ok,err = rediscmd:hset(opt.id,'status','limit')
				if not ok then return end
				writefile(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
				writefile(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..'The next request will be rejected'..'|')
				return
			else
				writefile(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
				return
			end
		end
	end
end
_M.limit = function(self,info_pass,info_limit)
	if info_pass.active >= 500 and info_pass.active < 600 then
		if  info_pass.rdm <= info_pass.grade1 then
			carry_redis(info_limit)
			return
		else
			carry_redis(info_pass)
			return
		end
	elseif info_pass.active >= 600 and info_pass.active < 800 then
		if  info_pass.rdm <= info_pass.grade2 then
			carry_redis(info_limit)
			return
		else
			carry_redis(info_pass)
			return
		end
	elseif info_pass.active >= 800 and info_pass.active < 1000 then
		if  info_pass.rdm <= info_pass.grade3 then
			carry_redis(info_limit)
			return
		else
			carry_redis(info_pass)
			return
		end
	elseif info_pass.active >=1100 then
			carry_redis(info_limit)
			return
	end
end

return _M