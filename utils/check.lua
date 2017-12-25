---各种check
local _M = {}
local rediscmd = require('utils.rediscmd')



_M.checknull = function(status)
	if status ~= nil and status ~= ngx.null and status ~= "" and status ~= " " then
		return false
	end
	return true
end

_M.checkredis = function()
	local redispin,err = rediscmd:ping()
	if redispin ~= 'PONG' then
		return false
	end
	return true
end

return _M