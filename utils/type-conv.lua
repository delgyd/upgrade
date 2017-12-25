---类型转换
local _M = {}
local mt = {__index = _M}
_M._VERSION = "0.01"


_M.StrToTable = function(self,str)
    if str == nil or type(str) ~= "string" then
        return
    end
    return loadstring("return " .. str)()
end

local function ToStringEx(value)
    if type(value)=='table' then
       return TableToStr(value)
    elseif type(value)=='string' then
        return "\'"..value.."\'"
    else
       return tostring(value)
    end
end

_M.TableToStr = function(table)
    if table == nil then return "" end
    local retstr= "{"
    local i = 1
    for key,value in pairs(table) do
        local signal = ","
        if i==1 then
          signal = ""
        end
        if key == i then
            retstr = retstr..signal..ToStringEx(value)
        else
            if type(key)=='number' or type(key) == 'string' then
                retstr = retstr..signal..'['..ToStringEx(key).."]="..ToStringEx(value)
            else
                if type(key)=='userdata' then
                    retstr = retstr..signal.."*s"..TableToStr(getmetatable(key)).."*e".."="..ToStringEx(value)
                else
                    retstr = retstr..signal..key.."="..ToStringEx(value)
                end
            end
        end
        i = i+1
    end
     retstr = retstr.."}"
     return retstr
end

return _M