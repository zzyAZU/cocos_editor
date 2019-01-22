--[[====================================
=
=   通用操作常用的全局函数
=
========================================]]
-- tolua++
local LUA_REGISTRY = debug.getregistry()

tolua_is_class = function(cls)
    local className = LUA_REGISTRY[cls]
    return className ~= nil and LUA_REGISTRY[className] == cls
end

tolua_is_class_t = function(cls)
    return type(cls) == 'table' and rawget(cls, '.isclass') == true and tolua_is_class(getmetatable(cls))
end

tolua_is_obj = function(obj)
    if not is_userdata(obj) then
        return false
    end

    if not tolua_is_class(getmetatable(obj)) then
        return false
    end

    return not tolua.isnull(obj)
end

local _cachedSuper = {}
tolua_super = function(cls)
    local ret = _cachedSuper[cls]
    if ret == nil then
        if tolua_is_class(cls) then
            ret = getmetatable(cls)
        elseif tolua_is_class_t(cls) or tolua_is_obj(cls) then
            ret = getmetatable(getmetatable(cls))
        else
            error_msg('tolua_super error [%s] not valid', str(cls))
        end

        _cachedSuper[cls] = ret
    end

    return ret
end

tolua_is_instance = function(obj, cls)
    assert(tolua_is_obj(obj))

    if tolua_is_class(cls) then
        return tolua_is_subclass(cls, getmetatable(obj))
    elseif tolua_is_class_t(cls) then
        return tolua_is_subclass(getmetatable(cls), getmetatable(obj))
    else
        error_msg('tolua_is_instance error [%s] not valid', str(cls))
    end
end

tolua_is_subclass = function(clsbase, clsderive)
    if tolua_is_class_t(clsbase) then
        clsbase = getmetatable(clsbase)
    end

    if tolua_is_class_t(clsderive) then
        clsderive = getmetatable(clsderive)
    end

    assert(tolua_is_class(clsbase))
    assert(tolua_is_class(clsderive))

    if clsbase == clsderive then
        return true
    end

    return LUA_REGISTRY['tolua_super'][clsderive][LUA_REGISTRY[clsbase]] == true
end

local tolua_new_classes = {}

tolua_get_class = function(class_name)
    local ret = tolua_new_classes[class_name]
    assert(tolua_is_class_t(ret))
    return ret, tolua_super(ret)
end

local _classInnerMember = table.to_value_set({
    '.classname',
    '__index',
    '__newindex',
    '__add',
    '__sub',
    '__mul',
    '__div',
    '__lt',
    '__le',
    '__eq',
    '__call',
    '__gc',
    'tolua_ubox',
    '__lua_defined_class_table',
})

--派生注册到lua中的 c++ 类
tolua_new_class = function(class_name, base)
    assert(is_valid_str(class_name))
    assert(is_valid_str(base) and LUA_REGISTRY[base])

    local classTable
    if LUA_REGISTRY[class_name] == nil then
        -- tolua_usertype
        local class = {}
        LUA_REGISTRY[class_name] = class
        LUA_REGISTRY[class] = class_name
        class['.classname'] = class_name

        --tolua_classevents
        local mtp = LUA_REGISTRY[base]
        class['__index'] = mtp['__index']
        class['__newindex'] = mtp['__newindex']
        class['__add'] = mtp['__add']
        class['__sub'] = mtp['__sub']
        class['__mul'] = mtp['__mul']
        class['__div'] = mtp['__div']
        class['__lt'] = mtp['__lt']
        class['__le'] = mtp['__le']
        class['__eq'] = mtp['__eq']
        class['__call'] = mtp['__call']
        class['__gc'] = mtp['__gc']

        --mapsuper
        local tolua_super = LUA_REGISTRY["tolua_super"]
        tolua_super[class] = table.merge({[LUA_REGISTRY[mtp]] = true}, tolua_super[mtp])

        -- tolua_cclass
        -- mapinheritance
        assert(is_table(mtp['tolua_ubox']))
        class['tolua_ubox'] = mtp['tolua_ubox']
        setmetatable(class, mtp)

        classTable = setmetatable({['.isclass'] = true}, class)
        rawset(class, '__lua_defined_class_table', classTable)
    else
        classTable = LUA_REGISTRY[class_name]['__lua_defined_class_table']

        local class = LUA_REGISTRY[class_name]
        for k, v in pairs(class) do
            if not _classInnerMember[k] then
                rawset(class, k, nil)
            end
        end
    end

    assert(tolua_is_class_t(classTable))

    cc[class_name] = classTable

    assert(tolua_new_classes[class_name] == nil)
    tolua_new_classes[class_name] = classTable

    return classTable
end

tolua_get_class_name = function(cls)
    if tolua_is_obj(cls) or tolua_is_class_t(cls) then
        cls = getmetatable(cls)
    end

    assert(tolua_is_class(cls))

    return cls['.classname']
end

--获取时间戳函数
utils_get_tick = function()
    local sec, usec = luaext_get_tick()
    return sec + usec / 1000000
end

local __plist_table_cache = {}
function utils_get_plist_conf(plist)
    if not is_valid_str(plist) then
        return
    end

    local conf = __plist_table_cache[plist]

    if conf then
        return conf
    end

    conf = g_fileUtils:getValueMapFromFile(plist)
    if not conf then
        printf('utils_get_plist_conf error [%s] not valid plist conf', plist)
        return
    end
    __plist_table_cache[plist] = conf
    return conf
end

local _allDelayControl = {}
-- 这样的引用key被gc了但是timer还会存在而导致timer停不掉
-- local _allDelayControl = setmetatable({}, {
--     __mode = 'k',
-- })

function cancel_all_delay_call()
    print('begin cancel_all_delay_call')
    for k, v in pairs(_allDelayControl) do
        printf('cancel delay_call:%s', v)
        k('cancel')
    end
    print('end cancel_all_delay_call')
end

-- timer的二次封装
function delay_call(delay, func, ...)
    assert(delay >= 0)

    local timer_arg = {...}
    local n = select('#', ...)
    local timer_id = nil
    local _controlFun = nil

    local function _cancelTimer()
        if timer_id then
            --print('cancel_succeed', timer_id, debug.traceback())
            g_scheduler:unscheduleScriptEntry(timer_id)
            timer_id = nil
        end
    end

    -- 返回一个函数用户控制当前timer
    function _controlFun(action)
        assert(action == 'cancel')
        _cancelTimer()
        -- assert(_allDelayControl[_controlFun])
        _allDelayControl[_controlFun] = nil
    end

    local function on_timer()
        local next_delay = func(unpack(timer_arg, 1, n))

        if next_delay then
            if next_delay ~= delay then
                _cancelTimer()
                timer_id = g_scheduler:scheduleScriptFunc(on_timer, next_delay, false)
                delay = next_delay
            end
        else
            _controlFun('cancel')
        end
    end

    timer_id = g_scheduler:scheduleScriptFunc(on_timer, delay, false)

    _allDelayControl[_controlFun] = string.format('call_time:[%.3f]', utils_get_tick())

    return _controlFun
end

function p_delay_call(delay, func, ...)
    return delay_call(delay, function(...)
        local ret
        local args = {...}
        local n = select('#', ...)
        xpcall(function()
            ret = func(unpack(args, 1, n))
        end, __G__TRACKBACK__)
        return ret
    end, ...)
end

-- 下载
local _maxDownloader = 4 -- 同时最大下载的线程数量
local _taskList = {}
local _downloadingFlag = {}
local DOWNLOAD_STATUS = cc.EXT_DOWNLOAD_STATUS
local function _getAvailableDownloadIndex()
    for i = 1, _maxDownloader do
        if _downloadingFlag[i - 1] == nil then
            return i - 1
        end
    end
end

local function _checkDownload()
    local index = _getAvailableDownloadIndex()
    if _taskList[1] and index ~= nil then
        local taskInfo = table.remove(_taskList, 1)
        _downloadingFlag[index] = taskInfo

        local url, path, callback, taskList = unpack(taskInfo)

        delay_call(0, function()
            luaext_download_file(url, path, index, function(eventType, ...)
                callback(eventType, ...)
                for _, cb in ipairs(taskList) do
                    cb(eventType, ...)
                end

                if eventType ~= DOWNLOAD_STATUS.STATUS_PROGRESS  then
                    -- 下载成功或者失败则进入下一个下载任务
                    _downloadingFlag[index] = nil
                    _checkDownload()
                end
            end)
        end)
    end
end

-- callback(eventType, ...)
-- if eventType == 3 then
--     -- 下载成功
-- elseif eventType == 2 then
--     -- 下载中
-- elseif eventType == 1 then
--     -- 下载失败
-- end
function utils_download_url_file(url, path, callback, directCallback, bStopWarnning)
    local _callback

    if directCallback then
        _callback = directCallback
    else
        function _callback(eventType, ...)
            if eventType == DOWNLOAD_STATUS.STATUS_ERROR then
                print('STATUS_ERROR')
                nTryCount = nTryCount + 1
                if nTryCount > 5 then
                    printf('download [%s] failed', url)
                    if bStopWarnning then
                        callback(DOWNLOAD_STATUS.STATUS_ERROR, ...)
                    else
                        confirm(120, function()
                            utils_restart_game()
                        end, nil, 10219)
                        g_logicEventHandler:Trigger('utils_net_connenct_event', 'NET_connect_failed')
                    end
                else
                    delay_call(1, function()
                        if not bStopWarnning then
                            message(T('网络请求失败，尝试第{1}次请求'), nTryCount)
                        end
                        utils_download_url_file(url, path, nil, _callback)
                    end)
                end
            else
                callback(eventType, ...)
            end
        end
        setfenv(_callback, {
            nTryCount = 1,
            utils_download_url_file = utils_download_url_file, 
            confirm = confirm,
            utils_restart_game = utils_restart_game,
            handle_youmeng_event = handle_youmeng_event,
            delay_call = delay_call,
            message = message,
            T = T,
            print = print,
            printf = printf,
            g_logicEventHandler = g_logicEventHandler,
        })
    end

    -- task list找重复任务
    for i, v in ipairs(_taskList) do
        if v[1] == url and v[2] == path then
            table.insert(v[4], _callback)
            return
        end
    end

    -- 在downloadlist里面找重复任务
    for _, v in pairs(_downloadingFlag) do
        if v[1] == url and v[2] == path then
            table.insert(v[4], _callback)
            return
        end
    end

    table.insert(_taskList, {url, path, _callback, {}})
    _checkDownload()
end

function utils_coroutine_download_url_file(url, path, progressCallback)
    print('utils_coroutine_download_url_file', url, path)
    local co = coroutine.running()

    local delayCallProgress = nil
    utils_download_url_file(url, path, function(eventType, bytesReceived, totalBytesReceived, totalBytesExpected)
        if eventType == DOWNLOAD_STATUS.STATUS_PROGRESS then
            if progressCallback then
                -- 下载完毕的时候一定要回调到
                if totalBytesReceived == totalBytesExpected then
                    if delayCallProgress then
                        delayCallProgress('cancel')
                        delayCallProgress = nil
                    end
                    progressCallback(bytesReceived, totalBytesReceived, totalBytesExpected)
                else
                    if delayCallProgress == nil then
                        print('~~~~~~~~~~up')
                        delayCallProgress = delay_call(0.1, function()
                            print('update~~~~~~~~~', bytesReceived, totalBytesReceived, totalBytesExpected)
                            progressCallback(bytesReceived, totalBytesReceived, totalBytesExpected)
                            delayCallProgress = nil
                        end)
                    end
                end
            end
        else
            -- 网络状况会出现这样的情况
            if delayCallProgress then
                delayCallProgress('cancel')
                delayCallProgress = nil
            end

            if eventType == DOWNLOAD_STATUS.STATUS_SUCCEED then
                assert(g_fileUtils:isFileExist(path))
                coroutine.resume(co, true)
            elseif eventType == DOWNLOAD_STATUS.STATUS_ERROR then
                coroutine.resume(co, false)
            else
                error('invalid event type')
            end
        end
    end)

    return coroutine.yield()
end

local function utils_url_encode(params)
    local qs = {}
    for k, v in pairs(params) do
        table.insert(qs, k..'='..tostring(v):urlencode())
    end
    return table.concat(qs, '&')
end

local _netHttpLog = nil

-- method: POST GET
function http_request(method, url, args, form, bRetry, bNotUploadError, requestHeader)
    -- print('http_request', method, url, args, form, bRetry)
    _netHttpLog = g_log_mgr.get_or_create_log('NET_HTTP')

    if not bNotUploadError then
        _netHttpLog:PrintHttp(true, method, url, args or form)
    end


    if args then
        if string.find(url, '?', 1, true) ~= nil then
            url = url .. '&'
        else
            url = url .. '?'
        end

        url = url .. utils_url_encode(args)
    end

    local strSend = form and (is_table(form) and utils_url_encode(form)) or (is_valid_str(form) and form) or nil

    local xhr = cc.XMLHttpRequest:new()
    local httpHandler = g_event_mgr.new_event_handler()

    httpHandler:RegisterEvent('on_success')
    httpHandler:RegisterEvent('on_fail')

    httpHandler.newHandler.on_success = function(data)
        if not bNotUploadError then
            _netHttpLog:PrintHttp(false, method, url, data)
        end
        xhr = nil

        if httpHandler.on_success then
            httpHandler.on_success(data)
        end
    end

    httpHandler.newHandler.on_fail = function()
        if not bNotUploadError then
            _netHttpLog:Printf('on_fail')
        end
        xhr = nil

        if httpHandler.on_fail then
            httpHandler.on_fail(status)
        end
    end

    local nTryCount = 1
    local function retry()
        if bRetry then
            nTryCount = nTryCount + 1
            if nTryCount > 5 then
                -- 尝试最大5次
                _netHttpLog:Printf('time out max try count')
                confirm(120, function()
                    utils_restart_game()
                end, nil, 10219)
                print(url)
                g_logicEventHandler:Trigger('utils_net_connenct_event', 'NET_connect_failed')
            else
                print(nTryCount)
                delay_call(3, function()
                    message(T('网络请求失败，尝试第{1}次请求'), nTryCount)
                    xhr:send(strSend)
                end)
            end
        else
            httpHandler:Trigger('on_fail')
        end
    end

    xhr:registerScriptHandler(function(curlPerformCode)
        if xhr.readyState == 4 and xhr.status == 200 then
            httpHandler:Trigger('on_success', xhr.response)
        else
            if not bNotUploadError then
                _netHttpLog:Printf('error [%s]:[%s][%s]', url, str(xhr.readyState), str(xhr.status))
                -- utils_test_upload_log2server('http_request_error', {readyState = xhr.readyState, status = xhr.status, curlPerformCode = curlPerformCode})
            end
            retry()
        end
    end)

    xhr:open(method, url, true) --设置请求方式  GET     或者  POST

    -- xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING --设置返回数据格式为字符串
    if requestHeader then
        for k, v in pairs(requestHeader) do
            xhr:setRequestHeader(k, v)
        end
    else
        if method == "POST" then
            xhr:setRequestHeader("Content-Type", "application/x-www-form-urlencoded;")
        end
    end

    xhr.timeout = 5
    xhr:send(strSend)

    return httpHandler
end

function http_get(url, args, bRetry, bNotUploadError)
    return http_request('GET', url, args, nil, bRetry, bNotUploadError)
end

function http_post(url, form, bRetry, bNotUploadError, requestHeader)
    return http_request('POST', url, nil, form, bRetry, bNotUploadError, requestHeader)
end

local function coroutine_get_http_text(url, bRetry)
    assert(is_valid_str(url))
    local co = coroutine.running()

    local event = http_get(url, nil, bRetry)
    event.on_success = function(data)
        coroutine.resume(co, data)
    end

    event.on_fail = function(status)
        coroutine.resume(co, nil)
    end

    return coroutine.yield()
end

--下载json并尝试进行解析，如果解析失败会再尝试下载，如果五次解析失败会弹出重启确认框
function utils_coroutine_get_http_json_conf(url, bRetry)
    local nTryCount = 1
    local ret
    while(ret == nil) do
        local text = coroutine_get_http_text(url, bRetry)
        pcall(function()
            ret = luaext_json_dencode(text)
        end)

        if not bRetry then
            break
        end

        if nTryCount > 5 then
            confirm(120, function()
                utils_restart_game()
            end, nil, 10219)
            g_logicEventHandler:Trigger('utils_net_connenct_event', 'NET_connect_failed')
        end
        nTryCount = nTryCount + 1
    end
    return ret
end

function utils_coroutine_get_http_json_conf_with_md5_size(url, url_conf_md5_size_str)
    assert(is_valid_str(url_conf_md5_size_str))

    print('utils_coroutine_get_http_json_conf_with_md5_size', url, url_conf_md5_size_str)

    if url_conf_md5_size_str == '99914b932bd37a50b983c5e7c90ae93b_2' then
        -- content:{}
        return {}
    end

    local path = g_fileUtils:getWritablePath()..'url_conf_md5_size/'
    if not g_fileUtils:isDirectoryExist(path) then
        g_fileUtils:createDirectory(path)
    end

    local filePath = path..url_conf_md5_size_str
    local ret
    if g_fileUtils:isFileExist(filePath) then
        pcall(function()
            ret = luaext_json_dencode(g_fileUtils:getStringFromFile(filePath))
        end)
    end

    if not ret then
        local text = coroutine_get_http_text(url, true)
        g_fileUtils:writeStringToFile(text, filePath)
        pcall(function()
            ret = luaext_json_dencode(text)
        end)
    end

    return ret
end

local function _stop()
    g_panel_mgr.close_all_scenes_and_panels()

    g_net_mgr.close_all_nets()

    g_audio_mgr.destory()

    -- scheduler
    cancel_all_delay_call()

    xpcall(function()
        g_logicEventHandler:Trigger('logic_event_restart_app')
    end, __G__TRACKBACK__)

    g_event_mgr.remove_all_events()

    if utils_is_game_cpp_interface_available('ScriptHandlerMgr_removeAllHandlers') then
        ScriptHandlerMgr:getInstance():removeAllHandlers()
    end

    -- clear registry callback fun
    LUA_REGISTRY['toluafix_refid_function_mapping'] = {}
end

-- calc_lua_data_size 计算的数据:
-- 1.lua number string table function userdata
-- 2.userdata 没有追溯引用可以用 ccext_ref_print_leaks 来追溯 userdata 的泄漏情况, table(key value 引用) 和 function(up value 引用) 会追溯相关
function calc_lua_data_size(...)
    local nTable = 0
    local nTableLen = 0
    local nString = 0
    local nStringLen = 0
    local nNum = 0
    local nUserData = 0
    local nFunction = 0

    local t = {}
    local n = {}
    local s = {}
    local u = {}
    local f = {}

    local listPath = {}
    local function _calc(v, key)
        table.insert(listPath, tostring(key))
        local curPath = table.concat(listPath, '->')
        -- print('curPath', type(v), curPath)

        if is_table(v) then
            if t[v] == nil then
                nTable = nTable + 1
                nTableLen = nTableLen + table.count(v)
                t[v] = {}
                table.insert(t[v], curPath)
                for k, v in pairs(v) do
                    _calc(k, '[table_key_type]')
                    _calc(v, tostring(k))
                end
            else
                table.insert(t[v], curPath)
            end
        elseif is_number(v) then
            if n[v] == nil then
                nNum = nNum + 1
                n[v] = {}
            end
            table.insert(n[v], curPath)
        elseif is_string(v) then
            if s[v] == nil then
                nString = nString + 1
                nStringLen = nStringLen + #v
                s[v] = {}
            end
            table.insert(s[v], curPath)
        elseif is_userdata(v) then
            if u[v] == nil then
                nUserData = nUserData + 1
                u[v] = {}
            end
            table.insert(u[v], curPath)
        elseif is_function(v) and f[v] == nil then
            nFunction = nFunction + 1
            -- avoid recursively call
            f[v] = true

            local fInfo = debug.getinfo(v)
            local funDesc = str(v)
            if fInfo.nups > 0 then
                local listPathBak = listPath
                listPath = {funDesc}
                for i = 1, fInfo.nups do
                    local vn, vv = debug.getupvalue(v, i)
                    _calc(vv, string.format('upvalue %s', vn))
                end
                listPath = listPathBak
            end
            f[v] = funDesc
        end

        table.remove(listPath)
    end

    -- number userdata string function table
    for i, info in ipairs({...}) do
        assert(table.is_empty(listPath))
        _calc(unpack(info))
    end

    return {
        -- t = t,
        -- n = n,
        -- s = s,
        -- u = u,
        -- f = f,
        nTable = nTable,
        nTableLen = nTableLen,
        nString = nString,
        nStringLen = nStringLen,
        nNum = nNum,
        nUserData = nUserData,
        nFunction = nFunction,
    }
end

function utils_calc_lua_memory_usage()
    local preLuaMem = collectgarbage('count')
    collectgarbage('collect')
    local curLuaMem = collectgarbage('count')
    printf('cur memory [%d] release lua memory [%d]', curLuaMem, preLuaMem - curLuaMem)
end

local _delayScheduleCollect = nil
local _scheduleCollectInterval = 8
function utils_enable_schedule_collect_garbage(bEnable)
    -- 为了调试方便 windows禁用回收某些内存
    if g_application:getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
        return
    end

    if _delayScheduleCollect then
        _delayScheduleCollect('cancel')
        _delayScheduleCollect = nil
    end

    if bEnable then
        _delayScheduleCollect = delay_call(_scheduleCollectInterval, function()
            cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
            g_director:getTextureCache():removeUnusedTextures()
            utils_calc_lua_memory_usage()
            return _scheduleCollectInterval
        end)
    end
end

-- 重启
-- registry 清理:
    -- 1.toluafix_refid_type_mapping
    -- 2.toluafix_refid_ptr_mapping
    -- 3.toluafix_refid_function_mapping
    -- 4.tolua_ubox
    -- 5.tolua_gc
    -- 6.tolua_value_root
local bStart = false
function utils_restart_game()
    print('utils_restart_game')

    if bStart == false then
        bStart = true
    else
        return
    end

    _stop()

    -- scene nodes
    if g_director:getRunningScene() then
        g_director:popToRootScene()
    end

    delay_call(0, function()
        local rootScene = g_director:getRunningScene()
        if rootScene then
            rootScene:removeAllChildren()
        end

        -- clean tex
        cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
        g_director:getTextureCache():removeUnusedTextures()

        if ccext_do_clean_up then
            ccext_do_clean_up()
        end

        -- for debug mem leak
        -- if ccext_ref_print_leaks then
        --     ccext_ref_print_leaks()
        -- end

        -- _stop()
        include('main.lua', true)
        utils_calc_lua_memory_usage()
        -- print('==============================================================================================================')
        -- print('toluafix_refid_type_mapping', str(LUA_REGISTRY['toluafix_refid_type_mapping']))
        -- print('toluafix_refid_ptr_mapping', str(LUA_REGISTRY['toluafix_refid_ptr_mapping']))
        -- print('toluafix_refid_function_mapping', str(LUA_REGISTRY['toluafix_refid_function_mapping']))
        -- print('tolua_ubox', str(LUA_REGISTRY['tolua_ubox']))
        -- print('tolua_gc', str(LUA_REGISTRY['tolua_gc']))
        -- print('tolua_value_root', str(LUA_REGISTRY['tolua_value_root']))
    end)
end

function event_applicationDidEnterBackground()
    g_eventHandler:Trigger('event_applicationDidEnterBackground')
end

function event_applicationWillEnterForeground()
    g_eventHandler:Trigger('event_applicationWillEnterForeground')
end

-- 被 java 或者 oc 调用的
function global_platform_call_lua_func(content)
    local info = eval(content)
    local tag = info['tag']
    local status = info['status']
    local message = info['message']
    local response = info['response']
    print(string.format( "# global_platform_call_lua_func -> tag:[%s], status:[%s], message:[%s]", tag, status, message))
    g_eventHandler:Trigger('global_platform_call_lua_func', tag, status, message, response)
end

local curPlatform = g_application:getTargetPlatform()
if curPlatform == cc.PLATFORM_OS_IPHONE or curPlatform == cc.PLATFORM_OS_IPAD then
    global_platform_call_lua_func = function(tag, status, message, response)
        g_eventHandler:Trigger('global_platform_call_lua_func', tag, status, message, response)
    end
end

-- 判断当前引擎是否支持某个原生接口
function is_native_interface_supported(methodName)
    local engineNativeInterface = g_conf_mgr.get_script_conf("engine_native_interface")
    if engineNativeInterface and engineNativeInterface[methodName] then
        return true
    end
end

local _cppNativeInterFace = is_table(game_new_cpp_interface) and game_new_cpp_interface or {}
-- 判断某个 c++ 导入到lua的接口特性是否支持
function utils_is_game_cpp_interface_available(name)
    return _cppNativeInterFace[name] ~= nil
end

-- 获取当前引擎子版本号(子版本号用于真正区分引擎的内容是否一致)
function utils_game_get_engine_sub_version()
    if game_get_engine_sub_version then
        return game_get_engine_sub_version()
    else
        return 0
    end
end

-- 获取当前 sdk 名称(编译sdk 的目录名)
function utils_get_sdk_version()
    return g_script_conf['cur_sdk_version']
end

-- 异步加载图
local _downloadingInfo = {}
function utils_add_image_async(filePath, callback)
    if _downloadingInfo[filePath] then
        table.insert(_downloadingInfo[filePath], callback)
    else
        _downloadingInfo[filePath] = {callback}
        g_director:getTextureCache():addImageAsync(filePath, function(tex)
            for _, cbk in ipairs(_downloadingInfo[filePath]) do
                cbk(tex)
            end
            _downloadingInfo[filePath] = nil
        end)
    end
end

--异步加载多张图片
function utils_add_images_async(filePathTable, callback)
    local loadNext
    local index,filePath
    loadNext = function()
        index,filePath = next(filePathTable,index)
        if index == nil then
            callback()
        else
            utils_add_image_async(filePath,loadNext)
        end
    end
    loadNext()
end

-- Z boolean
-- B byte
-- C char
-- S short
-- I int
-- J long
-- F float
-- D double
local config_check_android_data_type = {
    ['Z'] = is_boolean,
    ['I'] = is_integer,
    ['F'] = is_number,
    ['Ljava/lang/String;'] = is_string,
}

local function _validateAndroidParams(params, methodStr)
    assert(string.sub(methodStr, 1, 1) == '(')

    local curCheckStrIndex = 2
    local curParamCount = 0

    while(curCheckStrIndex <= #methodStr and string.sub(methodStr, curCheckStrIndex, curCheckStrIndex) ~= ')') do
        local findDataType = false
        for k, checkFun in pairs(config_check_android_data_type) do
            if k == string.sub(methodStr, curCheckStrIndex, curCheckStrIndex + #k - 1) then
                findDataType = true
                curParamCount = curParamCount + 1
                assert_msg(checkFun(params[curParamCount]), '[%d] parm is not [%s]:%s', curParamCount, k, str(params[curParamCount]))
                curCheckStrIndex = curCheckStrIndex + #k
            end
        end
        assert(findDataType)
    end

    assert(curParamCount == #params)
    assert(string.sub(methodStr, curCheckStrIndex, curCheckStrIndex) == ')')

    local retStr = string.sub(methodStr, curCheckStrIndex + 1)
    assert(is_function(config_check_android_data_type[retStr]) or retStr == 'V')
end

local _filterLogFun = {
    ['onPanelBegin'] = true,
    ['onPanelEnd'] = true,
    ['reportError'] = true,
    ['httpDownloadData'] = true,
}

function utils_android_call_static_method(javaClassStr, javaFunStr, params, methodStr)
    if _filterLogFun[javaFunStr] == nil then
        printf('_callStaticMethod [%s] [%s] [%s] parms:%s', javaClassStr, javaFunStr, methodStr, str(params))
    end

    -- 参数类型检测
    _validateAndroidParams(params, methodStr)

    if is_native_interface_supported('isNewInterfaces') then
        local isSuccess, hasMethod = LuaJavaBridge.callStaticMethod(javaClassStr, "isMethodStaticAndPublic", {javaFunStr}, "(Ljava/lang/String;)Z")
        if not isSuccess or isSuccess and not hasMethod then
            message('android _callStaticMethod failed, class ['.. javaClassStr ..'] has no method named [' .. javaFunStr .. ']')
            return nil, false
        end
    end

    local ok, ret = LuaJavaBridge.callStaticMethod(javaClassStr, javaFunStr, params, methodStr)
    if ok then
        if _filterLogFun[javaFunStr] == nil then
            printf('_callStaticMethod return:%s', str(ret))
        end
        return ret, true
    else
        printf('android _callStaticMethod failed [%s] [%s] [%s]', javaClassStr, javaFunStr, methodStr)
        return ret, false
    end
end

function utils_ios_call_static_method(objcClassStr, objcFuncStr, params)
    if _filterLogFun[objcFuncStr] == nil then
        printf('ios _callStaticMethod [%s] [%s] parms:%s', objcClassStr, objcFuncStr, str(params))
    end
    local ok, ret = LuaObjcBridge.callStaticMethod(objcClassStr, objcFuncStr, params)
    if ok then 
        if _filterLogFun[objcFuncStr] == nil then
            printf('ios _callStaticMethod return:%s', str(ret))
        end
        return ret, ok
    else
        printf('ios _callStaticMethod failed [%s] [%s] [%s] ', objcClassStr, objcFuncStr, str(params))
        return ret, ok
    end
end

--生成lua传递给native的tag的接口（tag用于native调用lua的global_platform_call_lua_func函数中）
if not utils_get_global_call_lua_tag then
    local _tag = 0
    local function utils_get_global_call_lua_tag()
        _tag = _tag + 1
        return tostring(_tag)
    end
    rawset(_G, "utils_get_global_call_lua_tag", utils_get_global_call_lua_tag)
end


function utils_android_call_static_method_callback(javaClassStr, javaFunStr, params, methodStr, callback)
    local _tag = utils_get_global_call_lua_tag()
    table.insert(params, _tag)
    local transform_methodStr = string.gsub(methodStr, '%)', "Ljava/lang/String;)")
    
    g_eventHandler:AddCallback('global_platform_call_lua_func', function(tag, status, msg, res)        
        if tostring(tag) == _tag then
            if callback then
                callback(status, msg, res)
            end
        end
    end)
    return utils_android_call_static_method(javaClassStr, javaFunStr, params, transform_methodStr)
end

function utils_ios_call_static_method_callback(objcClassStr, objcFuncStr, params, callback)
    local _tag = utils_get_global_call_lua_tag()
    params.tag = _tag
    g_eventHandler:AddCallback('global_platform_call_lua_func', function(tag, status, msg, res)        
        if tostring(tag) == _tag then
            if callback then
                callback(status, msg, res)
            end
        end
    end)
    return utils_ios_call_static_method(objcClassStr, objcFuncStr, params)
end

-- device
-- setAccelerometerEnabled
-- setAccelerometerInterval
-- setKeepScreenOn
-- vibrate
-- getDPI
function utils_device_enable_acceleration(bEnable, interval)
    cc.Device:setAccelerometerEnabled(bEnable)
    if bEnable and is_number(interval) then
        cc.Device:setAccelerometerInterval(interval)
    end
end

local const_md5_file_path = g_fileUtils:getWritablePath() .. 'md5/'
if not g_fileUtils:isDirectoryExist(const_md5_file_path) then
    g_fileUtils:createDirectory(const_md5_file_path)
end
local filePath = const_md5_file_path .. "md5file"

function utils_get_md5_from_string(string)
    if luaext_get_string_md5 == nil then
        local file = io.open(filePath, 'w+')
        file:write(string)
        file:close()
        return luaext_get_file_md5_and_size(filePath)
    else
        return luaext_get_string_md5(string)
    end
end

function utils_is_exist_emoj(emoj_value)
    local file_path = string.format(g_conf_mgr.get_constant('constant_uisystem').EMOJ_FORMAT_PATH, emoj_value)
    if not g_fileUtils:isFileExist(file_path) then
        return false
    end
    return true, file_path
end

function utils_is_use_new_http_download()
    local debugControl = g_conf_mgr.get_native_conf('debug_control')
    local bIsUseNewHttpDownload = debugControl and debugControl.bIsUseNewHttpDownload
    return bIsUseNewHttpDownload and utils_is_game_cpp_interface_available('support_use_new_http_download')
end

local _profileInfo = {}

local function _dumpProfile()
    local profilePath = g_fileUtils:getWritablePath()..'profile.txt'
    local profile = io.open(profilePath, 'w')

    local listInfo = {}
    for k, v in pairs(_profileInfo) do
        if v.total > 0 then
            table.insert(listInfo, v)
        end
    end

    table.sort(listInfo, function(v1, v2)
        return v1.total > v2.total
    end)

    profile:write('----------------------------------------------------------------------name----------------------------------------------------------------------|-----total time-----|-----total count-----|-----average per call-----|\n')
    -- 104 20 21 26
    for i,v in ipairs(listInfo) do
        local name = v['profileName']
        local sep1 = string.rep(' ', 144 - #name)

        local totalTime = str(#v['costs'])
        local sep2 = string.rep(' ', 20 - #totalTime)

        local totalCount = str(v['total'])
        local sep3 = string.rep(' ', 21 - #totalCount)

        local averagePerCall = str(v['total'] / #v['costs'])
        local sep4 = string.rep(' ', 26 - #averagePerCall)

        profile:write(string.format('%s%s|%s%s|%s%s|%s%s|\n',
            name, sep1, totalTime, sep2, totalCount, sep3, averagePerCall, sep4))
    end

    profile:close()

    -- 还原
    for k, v in pairs(_profileInfo) do
        local obj = v[1]
        local name = v[2]
        local v = v[3]
        obj[name] = v
    end

    _profileInfo = {}

    return profilePath
end

local function _doProfile(obj)
    if not isclass(obj) and not is_module(obj) then
        return
    end

    -- print('_doProfile', obj)
    for name, v in pairs(obj) do
        if is_function(v) then
            local profileName = string.format('%s[%s]', str(obj), name)
            local info = _profileInfo[profileName]
            if info == nil then
                printf('!!!!mark profile:%s', profileName)
                info = {obj, name, v}
                info.profileName = profileName
                info.costs = {}
                info.total = 0
                _profileInfo[profileName] = info
                obj[name] = function(...)
                    local ret
                    local cur = utils_get_tick()
                    ret = {v(...)}
                    local cost = utils_get_tick() - cur
                    table.insert(info.costs, cost)
                    info.total = info.total + cost
                    return unpack(ret, 1, table.maxn(ret))
                end
            else
                -- assert(info[1] == obj and info[2] == name and info[3] == v, profileName)
            end
        end
    end
end


function profile_all_existing_modules_and_classes()
    if table.is_empty(_profileInfo) then
        print('start profile')
        for _, cls in pairs(GetClassInfo()) do
            _doProfile(cls)
        end

        for _, m in pairs(import_get_moudule_info()) do
            _doProfile(m)
        end
    else
        print('stop profile and save results')

        return _dumpProfile()
    end
end

local byte = string.byte
local lshift = bit.lshift
local rshift = bit.rshift
local band = bit.band
local bor = bit.bor
function base64_decode(base64_str)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local base64Map = {}
    for i = 1, 64 do
        base64Map[byte(b, i)] = i - 1
    end

    local len = #base64_str
    local curIdx = 1
    local ret = {}

    while curIdx <= len - 4 do
        local n1 = base64Map[byte(base64_str, curIdx)]
        local n2 = base64Map[byte(base64_str, curIdx + 1)]
        local n3 = base64Map[byte(base64_str, curIdx + 2)]
        local n4 = base64Map[byte(base64_str, curIdx + 3)]
        -- print(n1, n2, n3, n4)

        table.insert(ret, string.char(lshift(n1, 2) + rshift(n2, 4)))
        table.insert(ret, string.char(lshift(band(n2, 0x0f), 4) + rshift(n3, 2)))
        table.insert(ret, string.char(lshift(band(n3, 0x03), 6) + n4))
        curIdx = curIdx + 4
    end

    local n1 = base64Map[byte(base64_str, curIdx)]
    local n2 = base64Map[byte(base64_str, curIdx + 1)]
    local n3 = base64Map[byte(base64_str, curIdx + 2)]

    table.insert(ret, string.char(lshift(n1, 2) + rshift(n2, 4)))
    if n3 then
        table.insert(ret, string.char(lshift(band(n2, 0x0f), 4) + rshift(n3, 2)))
        local n4 = base64Map[byte(base64_str, curIdx + 3)]
        if n4 then
            table.insert(ret, string.char(lshift(band(n3, 0x03), 6) + n4))
        end
    end

    return table.concat(ret)
end

function base64_encode(content)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local i = 1
    local prev, ascii, mod
    local result = {}
    local len = #content

    local base64Map = {}
    for i = 1, 64 do
        base64Map[i - 1] = string.char(byte(b, i))
    end

    while i <= len do
        ascii = byte(string.sub(content, i, i))
        mod = i % 3
        if mod == 1 then
            table.insert(result, base64Map[rshift(ascii, 2)])
        elseif mod == 2 then
            table.insert(result, base64Map[bor(lshift(band(prev, 3), 4), rshift(ascii, 4))])
        elseif mod == 0 then
            table.insert(result, base64Map[bor(lshift(band(prev, 0x0f), 2), rshift(ascii, 6))])
            table.insert(result, base64Map[band(ascii, 0x3f)])
        end
        prev = ascii
        i = i + 1
    end
    if mod == 1 then
        table.insert(result, base64Map[lshift(band(prev, 3), 4)])
        table.insert(result, '=')
        table.insert(result, '=')
    elseif mod == 2 then
        table.insert(result, base64Map[lshift(band(prev, 0x0f), 2)])
        table.insert(result, '=')
    end
    return table.concat(result)
end

if luaext_base64_encode then
    base64_encode = luaext_base64_encode
end

if luaext_base64_dencode then
    base64_decode = luaext_base64_dencode
end

-- 解析base64成图片保存到本地
function decode_base64_to_local_image(base64_str, path)
    g_fileUtils:writeStringToFile(base64_decode(base64_str), path)
end