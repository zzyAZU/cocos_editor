--[[
    日志管理
]]
local LogBase = CreateClass()

local const_log_path = g_fileUtils:getWritablePath() .. 'log/'
if not g_fileUtils:isDirectoryExist(const_log_path) then
    g_fileUtils:createDirectory(const_log_path)
end

local function _get_log_file(name)
    assert(is_valid_str(name))

    local fileInfo = _G.__log_file_info__
    if fileInfo == nil then
        fileInfo = {}
        rawset(_G, '__log_file_info__', fileInfo)
    end

    local file = fileInfo[name]
    if file == nil then
        local filePath = const_log_path .. name
        -- 第一次打开的话直接写操作
        if __already_write_log_file == nil then
            rawset(_G, '__already_write_log_file', {})
        end
        if __already_write_log_file[filePath] == nil then
            file = io.open(filePath, 'w')
            if file then
                local content = string.format('-----\n\n\nlog file [%s] created in:%s\n\n\n-----\n', name, os.date("%Y-%m-%d  %H-%M-%S", os.time()))
                file:write(content)
            end
            __already_write_log_file[filePath] = true
        else
            file = io.open(filePath, 'a')
        end

        if file then
            fileInfo[name] = file
        end
    end

    return file
end

local function _close_log_file(name)
    local fileInfo = _G.__log_file_info__
    if fileInfo == nil then
        return
    end
    local file = fileInfo[name]
    if file == nil then
        return
    end
    file:close()
    fileInfo[name] = nil
end

local startTime = utils_get_tick()
local function _write_log_file(name, content)
    local f = _get_log_file(name)
    if f then
        f:write(string.format('[%04.6f]', utils_get_tick() - startTime))
        f:write(content)
        f:write('\n')
        return f
    end
end

delay_call(0, function()
    if g_application:getTargetPlatform() == cc.PLATFORM_OS_WINDOWS or g_native_conf.debug_control.bPrintNetLog then
        local oldWrite = _write_log_file
        -- Windows 写日志立马刷到本地文件中方便查看
        function _write_log_file(name, content)
            oldWrite(name, content):flush()
        end
    end
end)

function get_log_file_content(name)
    _close_log_file(name)

    local ret
    local filePath = const_log_path .. name
    if g_fileUtils:isFileExist(filePath) then
        ret = g_fileUtils:getStringFromFile(filePath)
    else
        ret = ''
    end

    return ret
end

local logs = {}
function create_log(name)
    assert(logs[name] == nil)
    log = LogBase:New(name)
    logs[name] = log
    return log
end

function get_log(name)
    return logs[name]
end

function get_or_create_log(name)
    if logs[name] then
        return logs[name]
    end
    local log = LogBase:New(name)
    logs[name] = log
    return log
end

function close_log(name)
    if isinstance(name, LogBase) then
        name = name._name
    end

    assert(is_string(name))

    if logs[name] then
        logs[name] = nil
        _close_log_file(name)
    end
end

-- 处理全局 print 的行为
function process_global_print()
    print('process_global_print')
    local remote_http_log = g_native_conf['remote_http_log']
    print(str(remote_http_log))
    if remote_http_log.bEnable then
        local net = g_net_mgr.create_net('net_remote_console')

        g_eventHandler:AddCallback('global_print', function(content)
            _write_log_file('global_print', content)
            net:print_log(content)
        end)

        -- log打印的内容发到控制台
        local function _wrapLogPrintFun(funName)
            local printFun = LogBase[funName]
            assert(is_function(printFun))
            LogBase[funName] = function(self, ...)
                local content = printFun(self, ...)
                if content then
                    net:print_net_log(content, self._name)
                end
            end
        end
        _wrapLogPrintFun('PrintProto')
        _wrapLogPrintFun('Print')

        net:connect(g_native_conf['remote_http_log'].link_url)
        return true
    else
        g_eventHandler:AddCallback('global_print', function(content)
            _write_log_file('global_print', content)
        end)
    end
end



-- override
function LogBase:__init__(name)
    assert(string.match(name, '^[0-9a-z_A-Z]+'), name)

    printf('Log [%s] init', name)
    self._name = name
    self._bEnableLog = true
    self._protoLogFilterMap = {}
end

function LogBase:GetName()
    return self._name
end

function LogBase:PrintProto(strMsgId, body)
    if self._protoLogFilterMap[strMsgId] or not self._bEnableLog then
        return
    end

    printf('LOG_PROTO[%s][%s]', self._name, strMsgId)
    local content = string.format('LOG_PROTO[%s][%s]%s\n', self._name, strMsgId, body)
    _write_log_file(self._name, content)

    return content
end

function LogBase:PrintHttp(bRequest, method, url, parms)
    if not self._bEnableLog then
        return
    end

    if is_string(parms) then
        parms = luaext_json_dencode(parms) or parms
    end

    if bRequest then
        printf('request [%s] [%s]', method, url)
        local content = string.format('request [%s] [%s]:%s\n', method, url, str(parms))
        _write_log_file(self._name, content)
    else
        printf('response [%s] [%s]', method, url)
        local content = string.format('response [%s] [%s]:%s\n', method, url, str(parms))
        _write_log_file(self._name, content)
    end
end

function LogBase:Print(content)
    if not self._bEnableLog then
        return
    end

    content = string.format('LOG[%s]%s', self._name, content)
    print(content)
    _write_log_file(self._name, content)

    return content
end

function LogBase:Printf(...)
    return self:Print(string.format(...))
end

function LogBase:EnableLog(bEnable)
    self._bEnableLog = bEnable
end

function LogBase:GetLogContent()
    return get_log_file_content(self._name)
end

function LogBase:AddProtoLogFilter(protoName)
    self._protoLogFilterMap[protoName] = true
end
