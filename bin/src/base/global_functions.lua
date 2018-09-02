--[[====================================
=
=         common global functions
=
========================================]]

local curPlatform = g_application:getTargetPlatform()
if curPlatform == cc.PLATFORM_OS_IPHONE or curPlatform == cc.PLATFORM_OS_IPAD then
    loadfile = function(filePath, chunkname)
        local content = luaext_get_encrypted_file_content(filePath)
        local f, err = loadstring(content, chunkname)
        if f then
            return f
        else
            __G__TRACKBACK__(err)
        end
    end
end

function __tostring__(v)
    if tolua_is_obj and tolua_is_obj(v) then
        if is_valid_str(v.__name__) then
            return string.format('<%s[%s] %s>', tolua_get_class_name(v), v.__name__, tostring(v))
        else
            return string.format('<%s %s>', tolua_get_class_name(v), tostring(v))
        end
    elseif is_table(v) then
        if isobject and isobject(v) then
            return string.format('[lua class object %s defined in %s]', tostring(v), v.__definedMoudule.__full_path__)
        elseif isclass and isclass(v) then
            return string.format('[lua class %s defined in %s]', tostring(v), v.__definedMoudule.__full_path__)
        elseif is_module and is_module(v) then
            return string.format('[lua module %s %s]', v.__full_path__, tostring(v))
        else
            return str(v)
        end
    end

    return tostring(v)
end

local function process_print_args(...)
    local args = {...}
    for i = 1, select('#', ...) do
        local argv = args[i]
        if argv == nil then
            args[i] = '【nil】'
        elseif argv == '' then
            args[i] = '【""】'
        else
            args[i] = __tostring__(argv)
        end
    end

    local evn = import_get_self_evn(4)
    if evn then
        args[1] = string.format('[%d]from[%s]:%s', g_director:getTotalFrames(), evn.__name__, args[1])
    else
        args[1] = string.format('[%d]:%s', g_director:getTotalFrames(), args[1])
    end

    return table.concat(args, '    ')
end

function print(...)
    local printContent = process_print_args(...)
    release_print(printContent)

    if g_eventHandler then
        g_eventHandler:Trigger('global_print', printContent)
    end
end

-- 不用全局load
-- _G.loadstring = nil
assert_msg = function(bAssert, fmt, ...)
    if not bAssert then
        return error_msg(fmt, ...)
    end
end

error_msg = function(fmt, ...)
    return error(string.format(fmt, ...))
end

printf = function(fmt, ...)
    print(string.format(fmt, ...))
end

is_string = function(str)
    return type(str) == 'string'
end

is_valid_str = function(str)
    return type(str) == 'string' and #str > 0
end

is_number = function(n)
    return type(n) == 'number'
end

is_integer = function(n)
    return type(n) == 'number' and n == math.floor(n)
end

is_function = function(fun)
    return type(fun) == 'function'
end

is_table = function(t)
    return type(t) == 'table'
end

is_array = function(t)
    return is_table(t) and #t == table.count(t)
end

is_boolean = function(v)
    return type(v) == 'boolean'
end

is_userdata = function(u)
    return type(u) == 'userdata'
end

-- @desc:
--  返回一个数值的代码字符串
--  这个函数只支持key为字符串或者数字的table,否则可能得到的结果不理想   
str = function(t)
    local strResult = {}
    local tbCreated = {}    --1. table, 2.repre string
    local tbKeys = {"BASE"} --2. table, keys

    local function WriteStr(str)
        table.insert(strResult, str)
    end

    local function WriteTab(nCount)
        for i = 1, nCount do WriteStr('\t') end
    end

    local function Write(t, nTab)
        if is_table(t) then
            local repre = tbCreated[t]
            if repre then
                --如果这个table别处有引用则输出引用字符串
                WriteStr(repre)
            else
                tbCreated[t] = string.format('[%s:%s]', tostring(t), table.concat(tbKeys, ','))

                if isobject and isobject(t) or isclass and isclass(t) or is_module and is_module(t) then
                    WriteStr(__tostring__(t))
                else
                    WriteStr('{\n')
                    --现输出数组再输出string的key
                    local keys = table.arr_bubble_sort(table.keys(t), function(v1, v2)
                        local bn1, bn2 = is_number(v1), is_number(v2)
                        if bn1 and bn2 then
                            return v1 < v2
                        elseif bn1 then
                            return true
                        elseif bn2 then
                            return false
                        else
                            return tostring(v1) < tostring(v2)
                        end
                    end)

                    for _, k in ipairs(keys) do
                        table.insert(tbKeys, tostring(k))
                        WriteTab(nTab)
                        if is_table(k) then
                            k = tostring(k)
                        end
                        WriteStr('[' .. tostring(k) ..'] = ')
                        Write(t[k], nTab + 1)
                        WriteStr(',\n')
                        table.remove(tbKeys)
                    end
                    WriteTab(nTab - 1)
                    WriteStr('}')
                end
            end
        elseif type(t) == 'string' then
            t = string.gsub(t, '\\', '\\\\')
            t = string.gsub(t, '\n', '\\n')
            local bDQuote = string.find(t, '"')
            local bQuote= string.find(t, "'")
            if bQuote and bDQuote then
                local function get_e_char_str(len)
                    local ret = {}
                    for i = 1, len do
                        ret[i] = '='
                    end
                    return table.concat(ret)
                end
                for i = 0, 999 do
                    local e_char_str = get_e_char_str(i)
                    local checkStr = '[' .. e_char_str .. '['
                    if not string.find(t, checkStr, 1, true) then
                        local checkStrEnd = ']' .. e_char_str ..']'
                        WriteStr(checkStr .. t .. checkStrEnd)
                        break
                    end
                end
            elseif bDQuote then
                WriteStr("'" .. t .. "'")
            else
                WriteStr('"' .. t .. '"')
            end
        elseif type(t) == 'number' or type(t) == 'boolean' then
            WriteStr(tostring(t))
        else
            Write(__tostring__(t))
        end
    end

    Write(t, 1)

    return table.concat(strResult)
end

repr = function(s, bRaw)
    local ret
    pcall(function()
        ret = luaext_json_encode(s)
    end)
    return ret
end

-- @desc:
--  解析一个字符串为一个lua值
eval = function(str)
    local ret
    pcall(function()
        ret = luaext_json_dencode(str)
    end)

    return ret
end

is_equal = function(v1, v2)
    if v1 == v2 then
        return true
    end

    if not is_table(v1) or not is_table(v2) then
        return false
    end

    return table.is_equal(v1, v2)
end

--排序好的pairs
sorted_pairs = function(t, cmp)
    local keys = table.keys(t)
    table.sort(keys, cmp)
    
    local inv_table = {}
    for idx, k in ipairs(keys) do
        inv_table[k] = idx
    end
    return function(s, k)
        if not k then
            k = keys[1]
        else
            k = keys[ inv_table[k] + 1 ]
        end
        local v
        if k then
            v = t[k]
        end
        return k, v
    end
end

-- 将 bind 里面设置的参数自动填充到 fun 中
function bind(...)
    local args = {...}
    local numParm = select('#', ...)
    local fun = select(1, ...)

    return function(...)
        local num = select('#', ...)
        for i = 1, num do
            args[numParm + i] = select(i, ...)
        end
        return fun(unpack(args, 2, numParm + num))
    end
end
