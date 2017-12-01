--获取redis连接信息与业务模块信息
local modulename = "init"
local _M = {}

_M._VERSION = '0.0.1'
_M.Redis = {
        ["host"]        = ngx.var.redis_host,
        ["port"]        = ngx.var.redis_port,
        ["poolsize"]    = ngx.var.redis_pool_size,
        ["idletime"]    = ngx.var.redis_keepalive_timeout,
        ["timeout"]     = ngx.var.redis_connect_timeout,
        ["dbid"]        = ngx.var.redis_dbid,
        ["pwd"]         = ngx.var.redis_pwd,
}
_M.Service = {
        ["service"]    = ngx.var.server,
}

return _M