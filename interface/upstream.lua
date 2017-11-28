--从缓存中获取upstream配置并重新加载nginx
local _M = {}
local socket = require("socket")
function GetAdd(hostname)
	local ip, resolved = socket.dns.toip(hostname)
	local ListTab = {}
	for k, v in ipairs(resolved.ip) do
		table.insert(ListTab, v)
	end
	return ListTab
end
function writefile(filename, info)
	local wfile=io.open(filename, "w+")
	assert(wfile)
	wfile:write(info,'\n')
	wfile:close()
end
function readfile(filename)
	local file = io.open(filename,"r")
	local read = file:read("*a")
	file:close()
	return read
end

_M.upstream = function(self)
	local hostip = unpack(GetAdd(socket.dns.gethostname()))
	local rediscmd = require('interface.utils.rediscmd')
	local serverip,err = rediscmd:hget('upgrade','update')
	if not serverip then return end
	if hostip == serverip then
		local ok,err = rediscmd:hget('upgrade',serverip)
		if ok == 'begin' then
		local upstream = readfile("/data/webapp/openresty/nginx/conf/online.conf")
			local ok,err = rediscmd:hset('upgrade','upstream_online',upstream)
			if not ok then return end
			local ok,err =  rediscmd:hget('upgrade','upstream_upgrade')
			if ok then
				writefile('/data/webapp/openresty/nginx/conf/upgrade.conf',ok)	
			end
			local ok,err = rediscmd:hget('upgrade','upstream_transfer')
			if ok then
				writefile('/data/webapp/openresty/nginx/conf/online.conf',ok)
			end
			local ok,err = rediscmd:hset('upgrade',serverip,'updating')
			if not ok then return end
			os.execute('sh /data/webapp/openresty/nginx/conf/lua_conf/reload.sh')
		elseif ok == 'end' then
			local ok,err = rediscmd:hget('upgrade','upstream_online')
			if ok then
				writefile('/data/webapp/openresty/nginx/conf/online.conf',ok)
			end
			local ok,err = rediscmd:hdel('upgrade',serverip)
			if not ok then return end
			os.execute('sh /data/webapp/openresty/nginx/conf/lua_conf/reload.sh')	
		end
	else
		local hok,herr = rediscmd:hget('upgrade',hostip)
		if hok == ngx.null then hok = nil end
		local sok,herr = rediscmd:hget('upgrade',serverip)
		if sok == ngx.null then sok = nil end
		if not hok then
			if sok == 'begin' or sok == 'updating' then
				local ok,err =  rediscmd:hget('upgrade','upstream_upgrade')
				if ok == ngx.null then ok = nil end
				if ok then
					writefile('/data/webapp/openresty/nginx/conf/upgrade.conf',ok)
					local ok,err = rediscmd:hset('upgrade',hostip,'updating')
					if ok == ngx.null then ok = nil end
					if not ok then return end
					os.execute('sh /data/webapp/openresty/nginx/conf/lua_conf/reload.sh')
				end
			-- else
			-- 	local ok,err = rediscmd:hdel('upgrade',hostip)
			-- 	if ok == ngx.null then ok = nil end
			-- 	if not ok then return end
			end
		else
			if sok == 'end' or herr then
				local ok,err = rediscmd:hdel('upgrade',hostip)
				if ok == ngx.null then ok = nil end
				if not ok then return end
			end
		end
	end
end
return _M