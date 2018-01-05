----limitandupgrade.lua
local rediscmd = require('interface.utils.rediscmd')
local headers = ngx.req.get_headers()
local socket = require("socket")

--日志输出
local function writefile_log(filename, info)
    local wfile=io.open(filename, "a+")
    assert(wfile)
    wfile:write(info,'\n')
    wfile:close()
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

local function StrToTable(str)
    if str == nil or type(str) ~= "string" then
        return
    end
    return loadstring("return " .. str)()
end

local limitlog = '/data/webapp/openresty/nginx/logs/lua-'..os.date("%Y")..os.date("%m")..os.date("%d")..os.date("%H")..'.log'
local limitinfo = '['..os.date()..']'

local url = ngx.var.uri
if url == '/scmccClient/servlet/chargeNotify.do' then --充值回调
	return
end

local active = tonumber(ngx.var.connections_active)
if not active then
    active = 0
end
--根据缓存可用性选用随机精确值
local redispin,err = rediscmd:ping()
if redispin == 'PONG' then
	--获取请求随机数毫秒级，可用于防刷操作
	math.randomseed(tostring(socket.gettime()):reverse():sub(1, 10)) 
	rdm = math.random(1,100)
else
	--获取请求随机数秒级
	math.randomseed(tostring(os.time()):reverse():sub(1, 10))
	rdm = math.random(1,100)
end

--获取用户ID
local ckv = ngx.var["cookie_SmsNoPwdLoginCookie"]
-- if not ckv then return end
local IP = headers['X_FORWARDED_FOR'] or ngx.var.remote_addr
if type(IP) == 'table' then
	local tlen = table.getn(IP)
	IP = IP[tlen]
end

if not ckv or type(IP) == 'table' then return end

local info = {
	['id'] = ckv,
	['active'] = active,
	['url'] = url,
	['grade1'] = 30,
	['grade2'] = 60,
	['grade3'] = 90,
	['rdm'] = rdm,
	['hostip'] = ngx.var.serverip,
	['IP'] = IP or '192.168.1.33',
	['CHANNEL'] = headers['channel'] or 'xwtec',
	['VERSION'] = headers['version'] or '0.0.1',
	['PHONE'] = ngx.var['cookie_SmsNoPwdLoginCookie'] or '10086',
}
local info_limit = setmetatable({['status'] = 'limit'},{__index = info})
local info_pass = setmetatable({['status'] = 'pass'},{__index = info})

--根据url匹配业务模块scmccClient/scmccClientWap/scmccCampaign/xxxxx
if url == "/scmccClient/action.dox" or url == "/scmccClient/action.dox?" then
	info_limit['servermod'] = 'scmccClient'
	info_pass['servermod'] = 'scmccClient'
elseif string.find(url,"scmccClientWap") then
	info_limit['servermod'] = 'scmccClientWap'
	info_pass['servermod'] = 'scmccClientWap'
elseif string.find(url,"scmccCampaign") then
	info_limit['servermod'] = 'scmccCampaign'
	info_pass['servermod'] = 'scmccCampaign'
else
	info_limit['servermod'] = 'scmcc'
	info_pass['servermod'] = 'scmcc'
end

--根据黑白名单修改status
local whiteid,err = rediscmd:sismember('limit_white_list',ckv)
local whiteurl,err = rediscmd:sismember('limit_white_list',url)
if whiteid == 1 or whiteurl == 1 then
	writefile_log(limitlog,limitinfo..'|'..url..'|'..active..'|'..ckv..'|'..'pass'..'白名单请求')
	return
end
local blackid,err = rediscmd:sismember('limit_black_list',ckv)
local blackurl,err = rediscmd:sismember('limit_black_list',url)
if blackid == 1 or blackurl == 1 then
	info_pass['status'] = 'limit'
	writefile_log(limitlog,limitinfo..'|'..url..'|'..active..'|'..ckv..'|'..'limit'..'黑名单请求')
end

local limit_server = function(opt)
	if opt.servermod == 'scmccClient' then
		writefile_log(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
		ngx.redirect("/limit_json")
	elseif opt.servermod == 'scmccClientWap' then
		writefile_log(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
		ngx.redirect('/limit_static/index.html')
	elseif opt.servermod == 'scmccCampaign' then
		writefile_log(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
		ngx.redirect('/limit_static/index.html')
	elseif opt.servermod == 'scmcc' then
		writefile_log(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
		ngx.redirect('/limit_static/index.html')
	end
end
local carry_redis = function (opt)
	local ok,err = rediscmd:exists(opt.id)
	if err == 'ERR handle response, backend conn reset' then
		if opt.status == 'limit' then
			limit_server(opt)
		elseif opt.status == 'pass' then
			writefile_log(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
		end
	end
	if ok == 0  then
		local ok,err = rediscmd:hset(opt.id,'status',opt.status)
		if not ok then return end
		local ok,err = rediscmd:hset(opt.id,opt.url,1)
		if not ok then return end
		local ok,err = rediscmd:hset(opt.id,'ACTIVE',opt.active)
		if not ok then return end
		local ok,err = rediscmd:expire(opt.id,90)
		if not ok then return end
		if opt.status == 'limit' then
			limit_server(opt)
		elseif opt.status == 'pass' then
			writefile_log(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
		end
	elseif ok == 1 then
		local ok,err = rediscmd:hget(opt.id,"status")
		if ok == 'limit' then
			opt.status = 'limit'
			limit_server(opt)
		elseif ok == 'pass' then
			opt.status = 'pass'
			local ok,err = rediscmd:hincrby(opt.id,opt.url,1)
			if ok >= 300 then
				local ok,err = rediscmd:hset(opt.id,'status','limit')
				if not ok then return end
				writefile_log(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
				writefile_log(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..'The next request will be rejected'..'|')
			else
				writefile_log(limitlog,limitinfo..'|'..opt.url..'|'..opt.active..'|'..opt.id..'|'..opt.status..'|')
			end
		end
	end
end

local limitcmd = function(pass,limit)
	
	if pass.active >= 500 and pass.active < 600 then
		if  pass.rdm <= pass.grade1 then
			carry_redis(limit)
		else
			carry_redis(pass)
		end
	elseif pass.active >= 600 and pass.active < 800 then
		if  pass.rdm <= info_pass.grade2 then
			carry_redis(limit)
		else
			carry_redis(pass)
		end
	elseif pass.active >= 800 and pass.active < 1000 then
		if  pass.rdm <= pass.grade3 then
			carry_redis(limit)
		else
			carry_redis(pass)
		end
	elseif info_pass.active >=1100 then
			carry_redis(limit)
	else
			writefile_log(limitlog,limitinfo..'|'..pass.url..'|'..pass.active..'|'..pass.id..'|'..pass.status..'|')
	end
end

local upstream = function(pass,limit)
	local serverip,serr = rediscmd:hget('upgrade','update')
	--获取本机与当前正在更新服务器的更新状态
	local h_status,herr = rediscmd:hget('upgrade',pass.hostip)
	local s_status,serr = rediscmd:hget('upgrade',serverip)
	--判断是否为当前设置的更新服务器
	if serverip == pass.hostip then
		--根据更新状态,备份online-upstream配置各重置配置,并更改更新状态重新加载nginx,当状态为end后,恢复online-upstream配置,并清理更新状态
		if s_status == 'begin' then
			local upstream = readfile("/data/webapp/openresty/nginx/conf/upstream_conf/online.conf")
			local ok,err = rediscmd:hset('upgrade','upstream_online',upstream)
			if not ok then return end
			local ok,err =  rediscmd:hget('upgrade','upstream_transfer')
			if ok then
				writefile('/data/webapp/openresty/nginx/conf/upstream_conf/online.conf',ok)
			end
			local ok,err =  rediscmd:hget('upgrade','upstream_upgrade')
			if ok then 
				writefile('/data/webapp/openresty/nginx/conf/upstream_conf/upgrade.conf',ok)
			end
			local ok,err = rediscmd:hset('upgrade',serverip,'updating')
			if ok then
				os.execute('sh /data/webapp/openresty/nginx/conf/lua_conf/reload.sh')
			end
		elseif s_status == 'end' then
			local ok,err = rediscmd:hget('upgrade','upstream_online')
			if ok then
				writefile('/data/webapp/openresty/nginx/conf/upstream_conf/online.conf',ok)
			end
			local ok,err = rediscmd:hdel('upgrade',serverip)
			if ok then
				os.execute('sh /data/webapp/openresty/nginx/conf/lua_conf/reload.sh')
			end
		elseif s_status == 'updating' then
			ngx.exec('@proxyB')
		else
			limitcmd(pass,limit)
		end
	else
		--非设置为当前正在的更新服务器,需要根据当前正在更新服务器的状态进行一致为更新中,第一次进来,需要设置本机的更新状态,并拉取upgrade-upstream配置,并且加载nginx
		if not h_status then
			if s_status == 'updating' then
				local ok,err =  rediscmd:hget('upgrade','upstream_upgrade')
				if ok then
					writefile('/data/webapp/openresty/nginx/conf/upstream_conf/upgrade.conf',ok)
				end
				local ok,err = rediscmd:hset('upgrade',pass.hostip,'updating')
				if ok then
					limitcmd(pass,limit)
					os.execute('sh /data/webapp/openresty/nginx/conf/lua_conf/reload.sh')
				end
			elseif s_status == 'end' or s_status == nil then
				limitcmd(pass,limit)
			end
		else
			--与正在更新服务器的状态一致
			if h_status == 'updating' and s_status == 'updating' then
				ngx.exec('@proxyB')
			--正在更新服务器的状为end或者已经被清理后,主动清理本机状态
			elseif s_status == 'end' or serr == nil then
				local ok,err = rediscmd:hdel('upgrade',pass.hostip)
				limitcmd(pass,limit)
			else
				limitcmd(pass,limit)
			end
		end
	end
end

local proxy_ip = function(option,oIP,pass,limit) --{'192.168.1.200'}
	local OtoT = StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == oIP then
			upstream(pass,limit)
		else
			limitcmd(pass,limit)
		end
	end
end

local proxy_head = function(option,oCHANNEL,pass,limit) --{'xwtec'}
	local OtoT = StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == oCHANNEL then
			upstream(pass,limit)
		else
			limitcmd(pass,limit)
		end
	end
end

local proxy_phone = function(option,oPHONE,pass,limit) --{'13693464'}
	local OtoT = StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == oPHONE then
			upstream(pass,limit)
		else
			limitcmd(pass,limit)
		end
	end
end

local proxy_version = function(option,oVERSION,pass,limit) --{'3.4.0'}
	local OtoT = StrToTable(option)
	for k,v in pairs(OtoT) do
		if v == oVERSION then
			upstream(pass,limit)
		else
			limitcmd(pass,limit)
		end
	end
end

local proxy_association = function(option,oREQINFO,pass,limit) --proxy {'ip','phone','version','head'}多策略组合平滑升级 --{'ip','phone'}
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
		for kR,vR in pairs(oREQINFO) do
			for kP,vP in pairs(PP) do
				if vR == vP then
					table.insert(temp,vR)
				end
			end
		end

		local tlen = table.getn(temp)
		local olen = table.getn(option)
		if tlen >= olen then
			upstream(pass,limit)
		else
			limitcmd(pass,limit)
		end	
end

local upgrade = function(option,pass,limit)
	local tproxy = StrToTable(option)
	local field = {}
	if type(tproxy) == 'table' then
		for k,v  in pairs(tproxy) do
			table.insert(field,table.concat({'proxy',v},"_" ))
		end
	else
		table.insert(field,table.concat({'proxy',option},'_'))
	end
	if table.getn(field) == 1 then
		local ok,err = rediscmd:hget('upgrade',field[1])
		if not ok then
			return
		end
		if field[1] == 'proxy_ip' then
			if type(pass.IP) ~= 'table' then
				proxy_ip(ok,pass.IP,pass,limit)
			else
				return
			end
		elseif field[1] == 'proxy_head' then
			proxy_head(ok,pass.CHANNEL,pass,limit)
		elseif field[1] == 'proxy_phone' then
			proxy_phone(ok,pass.PHONE,pass,limit)
		elseif field[1] == 'proxy_version' then
			proxy_version(ok,pass.VERSION,pass,limit)
		else
			return
		end
	else
		local REQINFO = {pass.IP,pass.CHANNEL,pass.VERSION,pass.PHONE}
		proxy_association(field,REQINFO,pass,limit)
	end
end


if redispin == 'PONG' then
	local status,err = rediscmd:hget('upgrade','switch')
	if not status or status == 'off' then
		limitcmd(info_pass,info_limit)
	else
		local proxy,err = rediscmd:hget('upgrade','proxy')
		if proxy then
			upgrade(proxy,info_pass,info_limit)
		end
	end
else
	limitcmd(info_pass,info_limit)
end