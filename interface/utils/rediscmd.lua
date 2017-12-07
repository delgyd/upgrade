---rediscommand
local _M = {}
local conf = require('interface.init')
local redisconf = conf.Redis
local redis = require('interface.redis-util')
local red = redis:new(redisconf)

_M.hget = function(self,key,field)
	local res,err = red:hget(key,field)
	return res,err
end

_M.hset = function(self,key,field,value)
	local res,err = red:hset(key,field,value)
	return res,err
end
_M.hdel = function(self,key,field)
	local res,err = red:hdel(key,field)
	return res,err
end
return _M