--获取redis连接信息与业务模块信息
local modulename = "init"
local _M = {}

_M._VERSION = '0.0.1'
-- _M.Redis = {
--         ["host"]        = ngx.var.redis_host,
--         ["port"]        = ngx.var.redis_port,
--         ["poolsize"]    = ngx.var.redis_pool_size,
--         ["idletime"]    = ngx.var.redis_keepalive_timeout,
--         ["timeout"]     = ngx.var.redis_connect_timeout,
--         ["dbid"]        = ngx.var.redis_dbid,
--         ["pwd"]         = ngx.var.redis_pwd,
--         ['db_index']	= 0,
--         ['password']	= ngx.var.redis_pwd,
--         ['keepalive']	= ngx.var.redis_keepalive_timeout,
--         ['pool_size']	= ngx.var.redis_pool_size,
-- }

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