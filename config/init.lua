--基础配置信息
local _M = {}
_M._VERSION = '0.0.1'
_M.Redis = {
        ['host'] = '192.168.1.2',
        ['port'] = 6388,
        ['db_index'] = 0,
        ['password'] = 'qwert',
        ['timeout'] = 1000,
        ['keepalive'] = 60000,
        ['pool_size'] = 100,
}
_M.Service = {
		['service'] = 'scmccClient',
		['hostip'] = '192.168.1.2',
}
_M.Outfile = {
		['limitlog'] = '/data/webapp/logs/lua-limit-',
		['upgradelog'] = '/data/webapp/logs/lua-upgrade-',
		['apilog'] = '/data/webapp/logs/lua-api-',
}

return _M