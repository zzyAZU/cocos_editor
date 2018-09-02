-- 配置默认参数的获取
local function _genDefVal(name, defVal)
    assert(defVal ~= nil)

    local customizeDefVal = import('config.__customize_def_conf')[name]
    if customizeDefVal == nil then
        return defVal
    else
        if is_table(customizeDefVal) then
            assert(is_table(defVal))
            table.merge(defVal, customizeDefVal)
            return defVal
        else
            return customizeDefVal
        end
    end
end

-- 本地配置
local _nativeConf = {}
local _defNativeConf = {}

local nativeConfPath = g_fileUtils:getWritablePath() .. 'native_conf/'
if not g_fileUtils:isDirectoryExist(nativeConfPath) then
    g_fileUtils:createDirectory(nativeConfPath)
end

function register_native_conf(name, defVal)
    defVal = _genDefVal(name, defVal)
    assert(is_valid_str(name))
    assert(_defNativeConf[name] == nil)
    assert(defVal ~= nil)
    _defNativeConf[name] = defVal
end

function get_native_conf(name)
    local defV = _defNativeConf[name]
    assert(defV ~= nil, name)

    local ret = _nativeConf[name]

    if ret == nil then
        local bSaveConf = false

        ret = table.read_from_file(nativeConfPath .. name)
        if ret == nil then
            ret = defV
            bSaveConf = true
        elseif is_table(ret) then
            -- 保存本地的配置可能相对于默认配置缺少字段
            for k, v in pairs(defV) do
                if ret[k] == nil then
                    ret[k] = v
                    bSaveConf = true
                end
            end
        end

        _nativeConf[name] = ret

        if bSaveConf then
            save_native_conf(name)
        end
    end

    return ret
end

function set_native_conf(name, val)
    assert(_defNativeConf[name] ~= nil)
    _nativeConf[name] = val

    if val == nil then
        remove_native_conf(name)
    else
        save_native_conf(name)    
    end
end

function set_native_conf_k_v(name, k, v)
    local nativeConf = get_native_conf(name)
    assert(is_table(nativeConf))

    nativeConf[k] = v
    set_native_conf(name, nativeConf)
end

function save_native_conf(name)
    assert(_defNativeConf[name] ~= nil)
    if _nativeConf[name] == nil then
        return
    end
    table.write_to_file(_nativeConf[name], nativeConfPath .. name)
end

function save_all_native_conf()
    for k, v in pairs(_nativeConf) do
        save_native_conf(k, v)
    end
end

function remove_native_conf(name)
    local filePath = nativeConfPath .. name
    if g_fileUtils:isFileExist(filePath) then
        printf('remove_native_conf:%s', filePath)
        g_fileUtils:removeFile(nativeConfPath .. name)
    end
end

function remove_all_native_conf()
    for k, v in pairs(_nativeConf) do
        remove_native_conf(k)
    end
end

-- 获取native配置
function get_all_native_conf()
    for confName, _ in pairs(_defNativeConf) do
        if _nativeConf[confName] == nil then
            get_native_conf(confName)
        end
    end

    return table.deepcopy(_nativeConf)
end



-- 脚本配置
local _scriptConf = {}

-- 脚本配置正式环境是不可变的，但是在调试模式下跟本地配置一样可以改变
function register_script_conf(name, defVal)
    defVal = _genDefVal(name, defVal)
    assert(is_valid_str(name))
    assert(_scriptConf[name] == nil)
    assert(defVal ~= nil)
    _scriptConf[name] = defVal
end

function get_script_conf(name)
    assert(_scriptConf[name] ~= nil)
    return _scriptConf[name]
end

-- 获取所有的脚本配置
function get_all_script_conf()
    return _scriptConf
end



-- 常量
function get_constant(name)
    local ret
    -- lua 的stack比较奇葩要这么 pcall stack才会到这
    xpcall(function()
        ret = import('config.constant.' .. name)
    end, function(e)
        print(e, debug.traceback())
    end)
    return ret
end



-- 配置表
local conf_cache = {}
local function parseMultilangTable(t, keyLen)
    local curLangSuffix = get_native_conf('cur_multilang_index')
    local curConf = t
    for i = 1, keyLen do
        _, curConf = next(curConf)
    end

    local keys = {}
    local keysOrigin = {}
    for k, v in pairs(curConf) do
        local multiLangKey, lang = string.match(k, '^(.+)%((.+)%)$')
        if multiLangKey then
            if lang == curLangSuffix then
                table.insert(keysOrigin, k)
                table.insert(keys, multiLangKey)
            end
        else
            table.insert(keysOrigin, k)
            table.insert(keys, k)
        end
    end

    local function _convertInfo(dataConf)
        local ret = {}
        for i, key in ipairs(keysOrigin) do
            ret[keys[i]] = dataConf[key]
        end
        return ret
    end

    local function _parseConf(conf, deep)
        if deep == 1 then
            for k, v in pairs(conf) do
                conf[k] = _convertInfo(v)
            end
        else
            for _, v in pairs(conf) do
                _parseConf(v, deep - 1)
            end
        end

        return conf
    end

    return _parseConf(t, keyLen)
end

local function _loadConf(name)
    local ret
    xpcall(function()
        local fileName = string.format('config/info/%s.lua', name)
        local content = g_fileUtils:getStringFromFile(fileName)
        local i = string.find(content, '\n', 1, true)
        local j = string.find(content, '\n', i + 1, true)
        local secondLine = string.sub(content, i + 1, j - 1)
        local keys = string.match(secondLine, '^-- keys: (.+)$')
        local keyLen = #string.split(keys, ' ')
        local env = {}
        setfenv(loadstring(content), env)()
        ret = parseMultilangTable(env.data, keyLen)
    end, function(msg)
        __G__TRACKBACK__(msg)
        printf('warnning config [%s] not valid return empty table', str(name))
        ret = {}
    end)

    return ret
end

local function _reloadConf(name)
    if conf_cache[name] ~= nil then
        conf_cache[name] = _loadConf(name)
    end
end

function get_conf(name)
    local ret = conf_cache[name]
    if ret == nil then
        ret = _loadConf(name)
        conf_cache[name] = ret
    end

    return ret
end

function reload_conf(name)
    if name then
        _reloadConf(name)
    else
        for name, _ in pairs(conf_cache) do
            _reloadConf(name)
        end
    end
end



-- url conf(temp)
-- identify_placeholder 测试使用
function get_url_conf(name, isTestServer)
    local url_conf = get_conf(name)
    local confTable = get_native_conf('game_url_mode')
    if isTestServer == nil then 
        isTestServer =  get_native_conf('debug_control').bIsUrlTestServer
    end
    assert(url_conf ~= nil)
    local t ={}
    setmetatable(t,{__index = function(k,v)
            local key 
            if isTestServer then
                if confTable[v] == nil or confTable[v] == '' then
                    key = 'debug'
                else
                    key = confTable[v]
                end
            else
                key = 'release'
            end

            if url_conf[key] then
                return url_conf[key][v].url
            else
                return key
            end
        end})
    return t
end

-- 快捷索引
conf = setmetatable({}, {
    __index = function(t, name)
        return get_conf(name)
    end,

    __newindex = function(t, name, conf)
        error('conf __newindex not supported')
    end,
})

constant_conf = setmetatable({}, {
    __index = function(t, name)
        return get_constant(name)
    end,

    __newindex = function(t, name, conf)
        error('const __newindex not supported')
    end,
})

native_conf = setmetatable({}, {
    __index = function(t, name)
        return get_native_conf(name)
    end,

    __newindex = function(t, name, conf)
        set_native_conf(name, conf)
    end,
})

script_conf = setmetatable({}, {
    __index = function(t, name)
        return get_script_conf(name)
    end,

    __newindex = function(t, name, conf)
        error('scripts __newindex not supported')
    end,
})
