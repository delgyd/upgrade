---rediscommand
local _M = {}
local conf = require('config.init')
local redisconf = conf.Redis
local redis = require('utils.redis-util')
local red = redis:new(redisconf)

_M.ping = function()
	local res,err = red:ping()
	return res,err
end
_M.set = function(self,key,value)
	local res,err = red:set(key,value)
	return res,err
end

_M.get = function(self,key)
	local res,err = red:get(key)
	return res,err
end

_M.expire = function(self,key,time)
	local res,err = red:expire(key,time)
	return res,err
end
_M.exists = function(self,key)
	local res,err = red:exists(key)
	return res,err
end


_M.hget = function(self,key,field)
	local res,err = red:hget(key,field)
	return res,err
end

_M.hset = function(self,key,field,value)
	local res,err = red:hset(key,field,value)
	return res,err
end

_M.hmset = function(self,...)
	local res,err = red:hmset(...)
	return res,err
end

_M.hdel = function(self,key,field)
	local res,err = red:hdel(key,field)
	return res,err
end

_M.hincrby = function(self,key,field,increment)
	local res,err = red:hincrby(key,field,increment)
	return res,err
end

_M.sismember = function(self,key,member)
	local res,err = red:sismember(key,member)
	return res,err
end

_M.ttl = function(self,key)
        local res,err = red:ttl(key)
        return res,err
end

return _M