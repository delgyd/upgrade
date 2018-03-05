----limit.lua
local _M = {}
local rediscmd = require('utils.rediscmd')
local config = require('config.init')
local check = require('utils.check')
local log = require('utils.files')

local limit_server = function(opt)
	if opt.servermod == 'scmccClient' then
		log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|'..opt.IP..'|','a+')
		ngx.redirect("/limit_json")
	elseif opt.servermod == 'scmccClientWap' then
		log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|'..opt.IP..'|','a+')
		ngx.redirect('/limit_static/index.html')
	elseif opt.servermod == 'scmccCampaign' then
		log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|'..opt.IP..'|','a+')
		ngx.redirect('/limit_static/index.html')
	elseif opt.servermod == 'scmcc' then
		log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|'..opt.IP..'|','a+')
		ngx.redirect('/limit_static/index.html')
	else
		log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|'..opt.IP..'|','a+')
		ngx.redirect('/limit_static/index.html')
	end
end

local carry_redis = function (opt)
	if opt.Redis_status == 'off' then
		if opt.status == 'limit' then
			limit_server(opt,'limit')
		elseif opt.status == 'pass' then
			log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|'..opt.IP..'|','a+')
		end
	else
		if opt.id == 'scmcc' then
			log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|'..opt.IP..'|','a+')
			return
		else
			local ok,err = rediscmd:exists(opt.id)
			if ok == 0  then
				local ok,err = rediscmd:hmset(opt.id,'status',opt.status,opt.url,1,'ACTIVE',opt.active,'HOST',opt.hostip,'Time',opt.Date)
				local ok,err = rediscmd:expire(opt.id,120)
				if opt.status == 'limit' then
					limit_server(opt)
				elseif opt.status == 'pass' then
					log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|'..opt.IP..'|','a+')
				end
			elseif ok == 1 then
				local ok,err = rediscmd:hget(opt.id,"status")
				if ok == 'limit' then
					local ok,err = rediscmd:ttl(opt.id)
					if ok < 0 then
						local ok,err = rediscmd:expire(opt.id,5)
					end
					opt.status = 'limit'
					limit_server(opt)
				elseif ok == 'pass' then
					opt.status = 'pass'
					if opt.brushproof == 'on' then
						local ok,err = rediscmd:hincrby(opt.id,opt.url,1)
						if ok >= 120 then
							local ok,err = rediscmd:hset(opt.id,'status','limit')
							if not ok then return end
							log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|'..opt.IP..'|','a+')
						else
							log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|'..opt.IP..'|','a+')
						end
					else
						local ok,err = rediscmd:hincrby(opt.id,opt.url,1)
						log:write(config.Outfile.limitlog..opt.Time,opt.Date..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|'..opt.IP..'|','a+')
					end
				end
			end
		end
	end
end
_M.limit = function(self,info_pass,info_limit)
	if info_pass.active >= 700 and info_pass.active < 800 then
		if  info_pass.rdm <= info_pass.grade1 then
			carry_redis(info_limit)
		else
			carry_redis(info_pass)
		end
	elseif info_pass.active >= 800 and info_pass.active < 900 then
		if  info_pass.rdm <= info_pass.grade2 then
			carry_redis(info_limit)
		else
			carry_redis(info_pass)
		end
	elseif info_pass.active >= 900 and info_pass.active < 1000 then
		if  info_pass.rdm <= info_pass.grade3 then
			carry_redis(info_limit)
		else
			carry_redis(info_pass)
		end
	elseif info_pass.active >=1000 then
		limit_server(info_limit)
	else
		carry_redis(info_pass)
	end	
end

return _M