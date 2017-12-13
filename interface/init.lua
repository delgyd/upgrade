--获取redis连接信息与业务模块信息
local modulename = "init"
local _M = {}

_M._VERSION = '0.0.1'
_M.Redis = {
                ['host']= '192.168.1.2',
                ['port']= 19000,
                ['db_index']=0,
                ['password']= 'qwert',
                ['timeout']=1000,
                ['keepalive']=60000,
                ['pool_size']=100,
            }
_M.Service = {
        ["service"]    = ngx.var.server,
}

return _M