----limit.lua
local _M = {}
local rediscmd = require('utils.rediscmd')
local config = require('config.init')
local check = require('utils.check')
local log = require('utils.files')

local limit_server = function(opt)
	if opt.servermod == 'scmccClient' then
		log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|','a+')
		ngx.redirect("/limit_json")
	elseif opt.servermod == 'scmccClientWap' then
		log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|','a+')
		ngx.redirect('/limit_static/index.html')
	elseif opt.servermod == 'scmccCampaign' then
		log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|','a+')
		ngx.redirect('/limit_static/index.html')
	elseif opt.servermod == 'scmcc' then
		log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|','a+')
		ngx.redirect('/limit_static/index.html')
	end
end

local carry_redis = function (opt)
	local status = check:checkredis()
	if not status then
		if opt.status == 'limit' then
			limit_server(opt,'limit')
		elseif opt.status == 'pass' then
			log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|','a+')
		end
	end
	if opt.id == 'scmcc' then
		log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|','a+')
		return
	else
		local ok,err = rediscmd:exists(opt.id)
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
			elseif opt.status == 'pass' then
				log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|','a+')
			end
		elseif ok == 1 then
			local ok,err = rediscmd:hget(opt.id,"status")
			if ok == 'limit' then
				opt.status = 'limit'
				limit_server(opt)
			elseif ok == 'pass' then
				opt.status = 'pass'
				if opt.id == 'xwtec' then
					log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|','a+')
					return
				else
					local ok,err = rediscmd:hincrby(opt.id,opt.url,1)
					if ok >= 20 then
						local ok,err = rediscmd:hset(opt.id,'status','limit')
						if not ok then return end
						log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|','a+')
					else
						log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|','a+')
					end
				end
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
	else
		carry_redis(info_pass)
	end
end

return _M