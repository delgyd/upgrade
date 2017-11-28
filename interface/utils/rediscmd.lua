---rediscommand
local _M = {}
local conf = require('interface.init')
local redisconf = conf.Redis
local redis = require('interface.utils.redismod')
local red = redis.new(redisconf)


_M.set = function(self,key,val)
	local res, err = red:exec(
    function(red)
        return red:set(key,val)
    end
	)
	return res,err
end

_M.setex = function(self,key,time,val)
	local res,err = red:exec(
	function(red)
		return red:setex(key,time,val)
	end
	)
	return res,err
end

_M.incr = function(self,key)
	local res,err = red:exec(
	function(red)
		return red:incr(key)
	end
	)
	return res,err
end

_M.get = function(self,key)
	local res, err = red:exec(
    function(red)
        return red:set(key)
    end
	)
	return res,err
end

_M.hset = function(self,key,field,val)
	local res, err = red:exec(
    function(red)
        return red:hset(key,field,val)
    end
	)
	return res,err
end

_M.hget = function(self,key,field)
	local res, err = red:exec(
    function(red)
        return red:hget(key,field)
    end
	)
	return res,err
end

_M.hdel = function(self,key,field)
	local res, err = red:exec(
    function(red)
        return red:hdel(key,field)
    end
	)
	return res,err
end

_M.hexists = function(self,key,field)
	local res,err = red:exec(
	function(red)
		return red:hexists(key,field)
	end
	)
	return res,err
end

_M.sadd = function(self,key,member)
	local res,err = red:exec(
	function(red)
		return red:sadd(key,member)
	end
	)
	return res,err	
end

_M.smembers = function(self,key)
	local res,err = red:exec(
	function(red)
		return red:smembers(key)
	end
	)
	return res,err
end

_M.srem = function(self,key,member)
	local res,err = red:exec(
	function(red)
		return red:srem(key,member)
	end
	)
	return res,err
end

return _M