--从缓存中获取upstream配置并重新加载nginx
local _M = {}
local log = ngx.log
local ERR = ngx.ERR
local rediscmd = require('interface.utils.rediscmd')
local socket = require("socket")
local key = 'upgrade'

--获取本机IP
function GetAdd(hostname)
	local ip, resolved = socket.dns.toip(hostname)
	local ListTab = {}
	for k, v in ipairs(resolved.ip) do
		table.insert(ListTab, v)
	end
	return ListTab
end
--字符串转table
local function StrToTable(str)
    if str == nil or type(str) ~= "string" then
        return
    end
    return loadstring("return " .. str)()
end

--读写nginx配置文件
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
	--获取本服务器IP
	local hostip = unpack(GetAdd(socket.dns.gethostname()))
	local hostname = socket.dns.gethostname()
	--获取当前正在升级服务器的IP
	local serverip,serr = rediscmd:hget(key,'update')
	--获取本机与当前正在更新服务器的更新状态
	local h_status,herr = rediscmd:hget(key,hostip)
	local s_status,serr = rediscmd:hget(key,serverip)
	--判断是否为当前设置的更新服务器
	if serverip == hostip then
		--根据更新状态,备份online-upstream配置各重置配置,并更改更新状态重新加载nginx,当状态为end后,恢复online-upstream配置,并清理更新状态
		if s_status == 'begin' then
			local upstream = readfile("/data/webapp/openresty/nginx/conf/online.conf")
			local ok,err = rediscmd:hset(key,'upstream_online',upstream)
			if not ok then return end
			local ok,err =  rediscmd:hget(key,'upstream_transfer')
			if ok then
				writefile('/data/webapp/openresty/nginx/conf/online.conf',ok)
			end
			local ok,err =  rediscmd:hget(key,'upstream_upgrade')
			if ok then 
				writefile('/data/webapp/openresty/nginx/conf/upgrade.conf',ok)
			end
			local ok,err = rediscmd:hset(key,serverip,'updating')
			if ok then
				os.execute('sh /data/webapp/openresty/nginx/conf/lua_conf/reload.sh')
			end
		elseif s_status == 'end' then
			local ok,err = rediscmd:hget(key,'upstream_online')
			if ok then
				writefile('/data/webapp/openresty/nginx/conf/online.conf',ok)
			end
			local ok,err = rediscmd:hdel(key,serverip)
			if ok then
				os.execute('sh /data/webapp/openresty/nginx/conf/lua_conf/reload.sh')
			end
		elseif s_status == 'updating' then
			ngx.exec('@proxyB')
		end
	else
		--非设置为当前正在的更新服务器,需要根据当前正在更新服务器的状态进行一致为更新中,第一次进来,需要设置本机的更新状态,并拉取upgrade-upstream配置,并且加载nginx
		if not h_status then
			if s_status == 'updating' then
				local ok,err =  rediscmd:hget(key,'upstream_upgrade')
				if ok then
					writefile('/data/webapp/openresty/nginx/conf/upgrade.conf',ok)
				end
				local ok,err = rediscmd:hset(key,hostip,'updating')
				if ok then
					os.execute('sh /data/webapp/openresty/nginx/conf/lua_conf/reload.sh')
				end
			end
		else
			--与正在更新服务器的状态一致
			if h_status == 'updating' and s_status == 'updating' then
				ngx.exec('@proxyB')
			--正在更新服务器的状为end或者已经被清理后,主动清理本机状态
			elseif s_status == 'end' or serr == nil then
				local ok,err = rediscmd:hdel(key,hostip)
			end
		end
	end
end
return _M