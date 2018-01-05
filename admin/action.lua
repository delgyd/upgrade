local upgradecmd = require('interface.upgrade.upindex')
local json = require('cjson')


--[[
	action=set&key=upgrade&field=switch&value=on[abc=34
]]
ngx.header['Content-Type'] = 'text/plain; charset=utf-8'
local args = ngx.req.get_uri_args()




local jsonTest = json.encode(args)
ngx.say(jsonTest)




--[[
ngx.req.read_body()
-- local args = ngx.req.get_post_args()
local args = ngx.req.get_uri_args()
-- Object to JSON encode  

-- if type(args) == 'table' then
-- 	jsonTest = json.encode(args)
-- end      --table转json  
args = {'1','2'}
  jsonTest = json.encode(args)
}
ngx.say(jsonTest)  
  
-- Now JSON decode the json string  
result = json.decode(jsonTest)   --json转table  
  
--]]

-- local json = require("cjson")
-- -- local args = ngx.req.get_uri_args()
-- local data = {1, 2}
-- data[1000] = 99
-- json.encode_sparse_array(true)
-- ngx.say(json.encode(args))




-- local cjson         = require('cjson.safe')
-- ngx.header['Content-Type'] = 'text/plain; charset=utf-8'
-- -- local request_body  = ngx.var.request_body
-- ngx.req.read_body()
-- -- local postData      = cjson.decode(request_body)
-- local args = {['name'] = 'bbb',['arg'] = 23, ['key'] = {['name']= 222}}

-- if type(args) == 'table' then
	
-- 	ngx.say(cjson.encode(args))
-- end


-- local cjson = require "cjson"
-- ngx.header['Content-Type'] = 'text/plain; charset=utf-8'
-- -- 先定义一个json字符串
-- local json_str = '{"name": "Bruce.Lin", "age": 25}'
-- -- 这里把它转成对象，然后输出属性
-- local json = cjson.decode(json_str)
-- ngx.say("Name = " .. json['name'] .. ", Age = " .. tostring(json['age'])) -- 这里需要把25转成字符串，才能进行字符串拼接
-- -- 输出 Name = Bruce.Lin, Age = 25
-- ngx.say('<br/>') -- 换行
-- -- 接下来我们再把json对象转成json字符串
-- local json_str2 = cjson.encode(json)
-- ngx.say(json_str2)
-- -- 输出{"name":"Bruce.Lin","age":25}
-- ngx.say('<br/>') -- 换行
-- local obj = {
--     ret = 200,
--     msg = "login success"
-- }
-- ngx.say(cjson.encode(obj))
-- ngx.say('<br/>') -- 换行
-- local obj2 = {}
-- obj2['ret'] = 200
-- obj2['msg'] = "login fails"
-- ngx.say(cjson.encode(obj2))
-- ngx.say('bb')



-- ?action=set&
-- ?action=check&
-- ?action=get&