---logs to files or to nginx logs
local _M = {}
local mt = {__index = _M}
_M._VERSION = "0.01"

local files = require('utils.files')

----logs to nginx logs

local ngxlog = ngx.log

-- local ngxSTD = ngx.STDERR
-- local ngxMEM = ngx.EMERG
-- local ngxALE = ngx.ALERT
local ngxCRI = ngx.CRIT
local ngxERR = ngx.ERR
-- local ngxWAR = ngx.WARN
-- local ngxNOT = ngx.NOTICE
-- local ngxINF = ngx.INFO
-- local ngxDEB = ngx.DEBUG

_M.ngxcrit = function(...)
	ngxlog(ngxCRI,...)
end
_M.ngxerr = function(...)
	ngxlog(ngxERR,...)
end

--logs to files
_M.writefile = function(filename,info,auth)
	files:write(filename,info,auth)
end

return _M