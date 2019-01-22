--[[====================================
=
=   import
=
========================================]]
local _searchPaths = {'?'}

local _moduleMt = {
    __index = _G,
    -- __newindex = function(t, k, v)
    --     rawset(t, k, v)
    -- end,
}

function is_module(m)
    return type(m) == 'table' and _moduleMt == getmetatable(m)
end

local _moduleFullPathMap = {}
local function _loadModule(fullPath, newModule)
    if _moduleFullPathMap[fullPath] == false then
        return
    end

    assert(_moduleFullPathMap[fullPath] == nil)

    local m = setmetatable({}, _moduleMt)
    -- m._EVN = m

    if newModule then
        for k, v in pairs(newModule) do
            m[k] = v
        end
    end

    newModule = m

    local func, err = luaext_loadfile(fullPath, newModule)
    if func then
        -- print('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~do load module', fullPath)
        newModule.__path__, newModule.__name__ = string.match(fullPath, '(.+/)(.+)')
        newModule.__full_path__ = fullPath
        newModule.__module__ = newModule

        -- 防止循环引用
        _moduleFullPathMap[fullPath] = newModule

        setfenv(func, newModule)()

        return newModule
    else
        _moduleFullPathMap[fullPath] = false

        if is_valid_str(err) then
            -- error
            __G__TRACKBACK__(err)
        end
    end
end

function import_get_moudule_info()
    return _moduleFullPathMap
end

local _directImportInfo = {}
function direct_import(dotName, evn)
    -- print('direct_import', dotName)

    local modulePath = string.gsub(dotName, '%.', '/')
    local ret = _directImportInfo[modulePath]
    if ret then
        return ret
    end

    -- 按照搜索路径搜索模块
    for _, v in pairs(_searchPaths) do
        local fullPath = string.gsub(v, "?", modulePath)

        ret = _moduleFullPathMap[fullPath]
        if ret then
            _directImportInfo[modulePath] = ret
            return ret
        else
            ret = _loadModule(fullPath, evn)
            if ret then
                _directImportInfo[modulePath] = ret
                return ret
            end
        end
    end

    -- error_msg('direct_import load [%s] failed', modulePath)
end

local _relativeImportInfo = {}
function relative_import(dotName, evn, level)
    -- print('relative_import', dotName, evn)

    local modulePath = string.gsub(dotName, '%.', '/')
    local curModule = import_get_self_evn(level or 3)
    assert(curModule)

    local info = _relativeImportInfo[curModule]
    if info == nil then
        info = {}
        _relativeImportInfo[curModule] = info
    end

    local ret = info[modulePath]

    if ret then
        return ret
    else
        local fullPath = curModule.__path__ .. modulePath .. '.lua'
        ret = _moduleFullPathMap[fullPath]

        if ret then
            info[modulePath] = ret
            return ret
        else
            ret = _loadModule(fullPath, evn)
            if ret then
                info[modulePath] = ret
                return ret
            else
                error_msg('relative_import load [%s] [%s] failed', modulePath, fullPath)
            end
        end
    end
end

function import(dotName, evn)
    -- print('import', dotName, evn)

    -- relative path
    local modulePath = string.gsub(dotName, '%.', '/')
    local curModule = import_get_self_evn(3)
    if curModule then
        local info = _relativeImportInfo[curModule]
        if info == nil then
            info = {}
            _relativeImportInfo[curModule] = info
        end

        local ret = info[modulePath]

        if ret then
            return ret
        else
            local fullPath = curModule.__path__ .. modulePath .. '.lua'
            ret = _moduleFullPathMap[fullPath]

            if ret then
                info[modulePath] = ret
                return ret
            else
                ret = _loadModule(fullPath, evn)
                if ret then
                    info[modulePath] = ret
                    return ret
                end
            end
        end
    end

    -- abs path
    local ret = _directImportInfo[modulePath]
    if ret then
        return ret
    end

    -- 按照搜索路径搜索模块
    for _, v in pairs(_searchPaths) do
        local fullPath = string.gsub(v, "?", modulePath)

        ret = _moduleFullPathMap[fullPath]
        if ret then
            _directImportInfo[modulePath] = ret
            return ret
        else
            ret = _loadModule(fullPath, evn)
            if ret then
                _directImportInfo[modulePath] = ret
                return ret
            end
        end
    end

    error_msg('import load [%s] failed', modulePath)
end

function import_reload(m)
    if is_string(m) then
        m = import(m)
    end

    return import_unload(m)
end

function import_unload(m)
    if is_string(m) then
        m = import(m)
    end

    _relativeImportInfo = {}
    _directImportInfo = {}
    _moduleFullPathMap[m.__full_path__] = nil
end

function import_unload_all()
    _relativeImportInfo = {}
    _directImportInfo = {}
    _moduleFullPathMap = {}
end

-- 默认为调用这个函数是在模块中调用的
function import_get_self_evn(level, levelMax)
    level = level or 2
    local curEvn = getfenv(level)
    if curEvn.__module__ then
        return curEvn
    elseif levelMax then
        for l = level + 1, levelMax do
            local evn = getfenv(l)
            if evn.__module__ then
                return evn
            end
        end
    end
end

function import_all_from(dotName, bRelative)
    local m
    if bRelative then
        m = relative_import(dotName, nil, 4)
    else
        m = direct_import(dotName)
    end

    if m then
        local curM = import_get_self_evn(3)
        if curM then
            for k, v in pairs(m) do
                rawset(curM, k, v)
            end
            return true
        end
    end

    __G__TRACKBACK__('import_all_from [%s] failed', str(dotName))
end

-- @desc:
--   增加import路径，优先增加的路径优先检测
function import_add_search_path(path)
    table.insert(_searchPaths, 1, path)
end

function import_get_search_paths()
    return _searchPaths
end
