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
        assert(is_table(mtp["tolua_ubox"]))
        class["tolua_ubox"] = mtp["tolua_ubox"]
        setmetatable(class, mtp)

        classTable = setmetatable({['.isclass'] = true}, class)
        rawset(class, '__lua_defined_class_table', classTable)
    else
        -- printf('warning tolua_new_class already defined:[%s]', class_name)
        classTable = LUA_REGISTRY[class_name]['__lua_defined_class_table']
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
        local next_delay = func(unpack(timer_arg))

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
        xpcall(function()
            ret = func(unpack(args))
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
    if _netHttpLog == nil then
        _netHttpLog = g_log_mgr.create_log('NET_HTTP')
    end

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
                utils_test_upload_log2server('http_request_error', {readyState = xhr.readyState, status = xhr.status, curlPerformCode = curlPerformCode})
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
            coroutine.yield()
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
    g_logicEventHandler:Trigger('logic_event_restart_app')

    g_net_mgr.close_all_nets()

    g_audio_mgr.destory()

    g_event_mgr.remove_all_events()

    -- scheduler
    cancel_all_delay_call()

    g_eventDispatcher:removeAllEventListeners()

    if utils_is_game_cpp_interface_available('ScriptHandlerMgr_removeAllHandlers') then
        ScriptHandlerMgr:getInstance():removeAllHandlers()
    end

    -- clear registry callback fun
    LUA_REGISTRY['toluafix_refid_function_mapping'] = {}
end

local function _cleanTextures()
    -- g_director:destroyTextureCache()
    -- cc.AnimationCache:destroyInstance()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
    g_director:getTextureCache():removeUnusedTextures()
end

local function utils_calc_lua_memory_usage()
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
        _delayScheduleCollect('cancle')
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
function utils_restart_game(bCleanTexture)
    print('utils_restart_game', bCleanTexture)
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

        if bCleanTexture then
            _cleanTextures()
        end

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
                assert_msg(checkFun(params[curParamCount]), '%d parm not valid', curParamCount)
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
}

function utils_android_call_static_method(javaClassStr, javaFunStr, params, methodStr)
    if _filterLogFun[javaFunStr] == nil then
        printf('_callStaticMethod [%s] [%s] [%s] parms:%s', javaClassStr, javaFunStr, methodStr, str(params))
    end

    if is_native_interface_supported('isNewInterfaces') then
        local isSuccess, hasMethod = LuaJavaBridge.callStaticMethod(javaClassStr, "isMethodStaticAndPublic", {javaFunStr}, "(Ljava/lang/String;)Z")
        if not isSuccess or isSuccess and not hasMethod then
            message('android _callStaticMethod failed, class ['.. javaClassStr ..'] has no method named [' .. javaFunStr .. ']')
            return nil, false
        end
    end

    -- 参数类型检测
    _validateAndroidParams(params, methodStr)

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