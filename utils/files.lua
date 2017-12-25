----封装对文件操作

local _M = {}
local mt = {__index = _M}
_M._VERSION = "0.01"

_M.write = function(self,filename,info,mode)
    local wfile=io.open(filename,mode)
    assert(wfile)
    wfile:write(info,'\n')
    wfile:close()
end

_M.read = function(self,filename,mode)
	local file = io.open(filename,mode)
	local read = file:read("*a")
	file:close()
	return read
end

return _M