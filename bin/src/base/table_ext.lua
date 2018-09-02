--[[====================================
=
=         extending lua table API
=
========================================]]

-- @desc:
--     Remove all items from t
function table.clear(t)
    for k, _ in pairs(t) do t[k] = nil end
    return t
end

-- @desc:
--     Create a new dictionary with keys from seq and values set to value.
function table.fromkeys(keys, values)
    local ret = {}
    for i, v in ipairs(keys) do
        ret[v] = values[i]
    end
    return ret
end

function table.from_table_values(t, keyAttrKey)
    local ret = {}
    for _, v in pairs(t) do
        ret[v[keyAttrKey]] = v
    end
    return ret
end

function table.from_table_trans_fun(t, func)
    local ret = {}
    for k, v in pairs(t) do
        local kk, vv = func(k, v)
        if kk ~= nil then
            ret[kk] = vv
        end
    end
    return ret
end

function table.from_arr_trans_fun(arr, func)
    local ret = {}
    for i, v in ipairs(arr) do
        local vv = func(i, v)
        if vv ~= nil then
            table.insert(ret, vv)
        end
    end
    return ret
end

-- @desc:
--     Return a copy of the dictionary’s list of keys.
function table.keys(t)
    local ret = {}
    for k, _ in pairs(t) do table.insert(ret, k) end
    return ret
end

-- @desc:
--     Return a copy of the dictionary’s list of values.
function table.values(t)
    local ret = {}
    for _, v in pairs(t) do table.insert(ret, v) end
    return ret
end

-- @desc:
--     Update the dictionary with the key/value pairs from other with copy, 
--     overwriting existing keys. 
function table.merge(t, tOther)
    for k, v in pairs(tOther) do t[k] = v end
    return t
end

-- @desc:
--     Update the dictionary with the key/value pairs from other with deepcopy, 
--     overwriting existing keys. Return None.
function table.deepmerge(t, tOther)
    for k, v in pairs(tOther) do
        t[k] = table.deepcopy(v)
    end
end

function table.count(t)
    local c = 0
    local k = next(t)
    while k do
        c = c + 1
        k = next(t, k)
    end
    return c
end

function table.count_if(t, fun)
    local c = 0
    for k, v in pairs(t) do
        if fun(k, v) then c = c + 1 end
    end
    return c
end

-- @desc:
--     Return a shallow copy of t.
function table.copy(t)
    local ret = {}
    for k, v in pairs(t) do
        ret[k] = v
    end
    return ret
end

-- @desc:
--     Return a deep copy of t, only deepcopy values
function table.deepcopy(tb)
    local tbs = {}
    local function copy(t)
        if type(t) ~= 'table' then return t end
        local ret = tbs[t]
        if ret then return ret end
        ret = {}
        tbs[t] = ret
        for k, v in pairs(t) do
            ret[k] = copy(v)
        end
        return ret
    end
    return copy(tb)
end

function table.deepcopy_with_keys(tb)
    local tbs = {}
    local function copy(t)
        if type(t) ~= 'table' then return t end
        local ret = tbs[t]
        if ret then return ret end
        ret = {}
        tbs[t] = ret
        for k, v in pairs(t) do
            ret[copy(k)] = copy(v)
        end
        return ret
    end
    return copy(tb)
end

function table.find_v(tb, value)
    for k, v in pairs(tb) do
        if value == v then
            return k, v
        end
    end
end

function table.find_first_not_v(tb, value)
    for k, v in pairs(tb) do
        if value ~= v then
            return k, v
        end
    end
end

function table.find_if(tb, func)
    for k, v in pairs(tb) do
        if func(k, v) then return k, v end
    end
end

function table.pop_v(tb, value)
    for k, v in pairs(tb) do
        if v == value then
            tb[k] = nil
            return k, v
        end
    end
end

function table.pop_if(tb, func)
    for k, v in pairs(tb) do
        if func(k, v) then
            tb[k] = nil
            return k, v
        end
    end
end

function table.to_value_set(t)
    local ret = {}
    for _, v in pairs(t) do
        ret[v] = true
    end
    return ret
end

function table.reverse_key_value(t)
    local ret = {}
    for k, v in pairs(t) do
        ret[v] = k
    end
    return ret
end

function table.is_empty(t)
    return next(t) == nil
end

local function _isEqual(t1, t2)
    for k, v in pairs(t2) do
        if not is_equal(t1[k], v) then
            return false
        end
    end

    return true
end

function table.is_equal(t1, t2)
    for k, v in pairs(t1) do
        if t2[k] == nil then
            return false
        end
    end

    return _isEqual(t1, t2)
end

-- @desc:
--     从一个非加密的lua文件中读取table配置
--     失败则返回 nil
function table.read_from_file(filePath)
    if not g_fileUtils:isFileExist(filePath) then
        return
    end

    local str = g_fileUtils:getStringFromFile(filePath)

    if not str then
        return
    end

    return eval(str)
end

function table.write_to_file(t, filePath, reprFun)
    assert(g_fileUtils:isAbsolutePath(filePath), str(filePath))

    local writeStr = reprFun and reprFun(t) or repr(t)
    g_fileUtils:writeStringToFile(writeStr, filePath)
end

function table.transfer_key(t, fun)
    local ret = {}
    for k, v in pairs(t) do
        ret[fun(v)] = v
    end
    return ret
end


--[[ =========== array operation =========== ]]
-- @desc:
--     extend t from tOther
function table.arr_extend(t, tOther)
    for _, v in ipairs(tOther) do
        table.insert(t, v)
    end
    return t
end

function table.arr_remove_v(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i, table.remove(t, i)
        end
    end
end

function table.arr_find_key(t, key ,value)
    for i, v in ipairs(t) do
        if v[key] == value then
            return i, v
        end
    end
end

-- @desc:
--     删除所有func返回的索引，func 返回的第二个参数标记是否继续搜索
-- @return
--     返回移除的 value list
function table.arr_remove_if(t, func)
    local ret = {}
    local function remove(t, func)
        local idx, bContinue
        for i, v in ipairs(t) do
            idx, bContinue = func(i, v)
            if idx then
                table.insert(ret, table.remove(t, idx))
                if bContinue then
                    return remove(t, func)
                end
            end
        end
    end

    remove(t, func)

    return ret
end

-- @desc:
--     根据 func 返回的索引插入table元素，如果不符合条件则插入到尾端
function table.arr_insert_if(t, value, func)
    local idx
    for i,v in ipairs(t) do
        idx = func(i, v)
        if idx then break end
    end
    if idx then
        table.insert(t, idx, value)
    else
        table.insert(t, value)
    end
    return idx
end

function table.arr_rinsert_if(t, value, func)
    local idx
    for i = #t, 1, -1 do
        idx = func(i, t[i])
        if idx then break end
    end
    if idx then
        table.insert(t, idx, value)
    else
        table.insert(t, value)
    end
    return idx
end

-- @desc:
--     reverses the items of t in place
function table.arr_reverse(t)
    local ret = {}
    for i = #t, 1, -1 do
        table.insert(ret, t[i])
    end
    return ret
end

function table.arr_bubble_sort(array, cmp)
    local len = #array
    local i = len  
    while i > 0 do
        local j = 1
        while j < i do
            if not cmp(array[j], array[j+1]) then
                array[j], array[j+1] = array[j+1], array[j]
            end
            j = j + 1
        end
        i = i - 1  
    end

    return array
end


function table.arr_reduce(array, fun)
    if #array == 0 then return end
    if #array == 1 then return array[1] end

    local ret = fun(array[1], array[2])
    for i = 3, #array do
        ret = fun(ret, array[i])
    end

    return ret
end

function table.arr_sub(t, start, len)
    local ret = {}
    if not start then start = 1 end
    if not len then len = #t end
    for i = start, start + len - 1 do
        ret[#ret + 1] = t[i]
    end
    return ret
end

function table.arr_is_equal(t1, t2)
    if #t1 == #t2 then
        for i, v in ipairs(t1) do
            if v ~= t2[i] then
                return false
            end
        end
    else
        return false
    end

    return true
end

function table.fillter(tb, func)
    local ret = {}
    for k, v in pairs(tb) do
        if func(k, v) then ret[k] = v end
    end
    return ret
end

function table.fillter_values(tb, func)
    local ret = {}
    for k, v in pairs(tb) do
        if func(k, v) then table.insert(ret, v) end
    end
    return ret
end

-- 多条件排序 tabel, 是否升序, 参数列表
function table.sort_by_multi_condition(t, isAsc, ...)
    local args = {...} 
    if #args == 0 then return end
    table.sort(t, function(a1, a2)
        for i = 1, #args do
            if a1[args[i]] ~= a2[args[i]] then
                if isAsc then
                    return a1[args[i]] < a2[args[i]]
                else
                    return a1[args[i]] > a2[args[i]]
                end
            end
        end
    end)
end

-- 按照某个key大小排序
function table.sort_by_key(t, key)
    table.sort(t, function(a1, a2)
       return a1[key] > a2[key]
    end)
    return t
end