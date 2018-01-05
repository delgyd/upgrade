--基础配置信息
local _M = {}
_M._VERSION = '0.0.1'
_M.Redis = {
        ['host'] = '127.0.0.1',
        ['port'] = 19000,
        ['db_index'] = 0,
        ['password'] = 'scydxwtec',
        ['timeout'] = 1000,
        ['keepalive'] = 60000,
        ['pool_size'] = 100,
}
_M.Service = {
	['service'] = 'scmccClient',
	['hostip'] = '10.113.158.69',
}
_M.Limit = {
        ['L1'] = 30,
        ['L2'] = 60,
        ['L3'] = 90,
}
_M.Outfile = {
	['limitlog'] = '/data/webapp/logs/lua-limit-',
	['upgradelog'] = '/data/webapp/logs/lua-upgrade-',
	['apilog'] = '/data/webapp/logs/lua-api-',
}

return _M