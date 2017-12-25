--从缓存中获取upstream配置并重新加载nginx
local _M = {}

local rediscmd = require('interface.utils.rediscmd')
local limitcmd = require('interface.limit.limitindex')
local file = require('utils.files')
local socket = require("socket")


_M.upstream = function(info_pass,info_limit)
-- ngx.say(type(info_limit),type(info_pass))
	-- --获取本服务器IP
	-- local hostip = unpack(GetAdd(socket.dns.gethostname()))
	--获取当前正在升级服务器的IP
	local serverip,serr = rediscmd:hget(info_pass.Upgradekey,'update')
	--获取本机与当前正在更新服务器的更新状态
	local h_status,herr = rediscmd:hget(info_pass.Upgradekey,info_pass.hostip)
	local s_status,serr = rediscmd:hget(info_pass.Upgradekey,serverip)
	--判断是否为当前设置的更新服务器
	if serverip == info_pass.hostip then
		--根据更新状态,备份online-upstream配置各重置配置,并更改更新状态重新加载nginx,当状态为end后,恢复online-upstream配置,并清理更新状态
		if s_status == 'begin' then
			local upstream = file:read("/data/webapp/openresty/nginx/conf/upstream_conf/online.conf",'r')
			local ok,err = rediscmd:hset(info_pass.Upgradekey,'upstream_online',upstream)
			if not ok then return end
			local ok,err =  rediscmd:hget(info_pass.Upgradekey,'upstream_transfer')
			if ok then
				file:write('/data/webapp/openresty/nginx/conf/upstream_conf/online.conf',ok,'w+')
			end
			local ok,err =  rediscmd:hget(info_pass.Upgradekey,'upstream_upgrade')
			if ok then 
				file:write('/data/webapp/openresty/nginx/conf/upstream_conf/upgrade.conf',ok,'w+')
			end
			local ok,err = rediscmd:hset(info_pass.Upgradekey,serverip,'updating')
			if ok then
				os.execute('sh /data/webapp/openresty/nginx/conf/lua_conf/reload.sh')
			end
		elseif s_status == 'end' then
			local ok,err = rediscmd:hget(info_pass.Upgradekey,'upstream_online')
			if ok then
				file:write('/data/webapp/openresty/nginx/conf/upstream_conf/online.conf',ok,'w+')
			end
			local ok,err = rediscmd:hdel(info_pass.Upgradekey,serverip)
			if ok then
				os.execute('sh /data/webapp/openresty/nginx/conf/lua_conf/reload.sh')
			end
		elseif s_status == 'updating' then
			ngx.exec('@proxyB')
		else
			limitcmd:limit(info_pass,info_limit)
			return
		end
	else
		--非设置为当前正在的更新服务器,需要根据当前正在更新服务器的状态进行一致为更新中,第一次进来,需要设置本机的更新状态,并拉取upgrade-upstream配置,并且加载nginx
		if not h_status then
			if s_status == 'updating' then
				local ok,err =  rediscmd:hget(info_pass.Upgradekey,'upstream_upgrade')
				if ok then
					file:write('/data/webapp/openresty/nginx/conf/upstream_conf/upgrade.conf',ok,'w+')
				end
				local ok,err = rediscmd:hset(info_pass.Upgradekey,info_pass.hostip,'updating')
				if ok then
					limitcmd:limit(info_pass,info_limit)
					os.execute('sh /data/webapp/openresty/nginx/conf/lua_conf/reload.sh')
				end
			elseif s_status == 'end' or s_status == nil then
				limitcmd:limit(info_pass,info_limit)
			end
		else
			--与正在更新服务器的状态一致
			if h_status == 'updating' and s_status == 'updating' then
				ngx.exec('@proxyB')
			--正在更新服务器的状为end或者已经被清理后,主动清理本机状态
			elseif s_status == 'end' or serr == nil then
				local ok,err = rediscmd:hdel(info_pass.Upgradekey,info_pass.hostip)
				limitcmd:limit(info_pass,info_limit)
			else
				limitcmd:limit(info_pass,info_limit)
			end
		end
	end
end
return _M