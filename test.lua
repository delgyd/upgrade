----lua_index.lua
--1、判断限流，为常开
--2、判断平滑，为可选
local rediscmd = require('interface.utils.rediscmd')
local limit_mode = require('interface.limit.limitindex')
local upgrade = require('interface.upgrade.upindex')

local url = ngx.var.uri
if url == '/scmccClient/servlet/chargeNotify.do' then --充值回调
	return
end

--获取当前连接数
local active = tonumber(ngx.var.connections_active)
if not active then
    active = 0
end
--获取请求随机数
local socket = require("socket")
math.randomseed(tostring(socket.gettime()):reverse():sub(1, 10)) 
local rdm = math.random(1,100)

--获取用户ID
local ckv = ngx.var["cookie_SmsNoPwdLoginCookie"]
if not ckv then return end

local grade1,err = rediscmd:hget('limit','grade1')
local grade2,err = rediscmd:hget('limit','grade2')
local grade3,err = rediscmd:hget('limit','grade3')

local info_limit = {
	['id'] = ckv,
	['status'] = 'limit',
	['active'] = active,
	['url'] = url,
	['grade1'] = tonumber(grade1) or 30,
	['grade2'] = tonumber(grade1) or 60,
	['grade3'] = tonumber(grade1) or 90,
	['rdm'] = rdm,
}
local info_pass = {
	['id'] = ckv,
	['status'] = 'pass',
	['active'] = active,
	['url'] = url,
	['grade1'] = tonumber(grade1) or 30,
	['grade2'] = tonumber(grade1) or 60,
	['grade3'] = tonumber(grade1) or 90,
	['rdm'] = rdm,
}
--根据url匹配业务模块scmccClient/scmccClientWap/scmccCampaign/xxxxx
if url == "/scmccClient/action.dox" or url == "/scmccClient/action.dox?" then
	info_limit['servermod'] = 'scmccClient'
	info_pass['servermod'] = 'scmccClient'
elseif string.find(url,"scmccClientWap") then
	info_limit['servermod'] = 'scmccClientWap'
	info_pass['servermod'] = 'scmccClientWap'
elseif string.find(url,"scmccCampaign") then
	info_limit['servermod'] = 'scmccCampaign'
	info_pass['servermod'] = 'scmccCampaign'
else
	info_limit['servermod'] = 'scmcc'
	info_pass['servermod'] = 'scmcc'
end

local upgrade_switch,err = rediscmd:hget('upgrade','switch') -- on/off/nil
local upgrade_proxy,err = upgrade:upgrade_proxy() --true/nil
if upgrade_switch == 'off' or upgrade_switch == nil then
	limit_mode:limit(info_pass,info_limit)
elseif upgrade_switch == 'on' and upgrade_proxy then
	-- ngx.say('upgrade')
	upgrade:upgrade(upgrade_proxy,info_pass,info_limit)
else
	limit_mode:limit(info_pass,info_limit)
end