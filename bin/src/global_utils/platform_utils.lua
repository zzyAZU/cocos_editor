
function platform_is_ios()
    local curPlatform = g_application:getTargetPlatform()
    return curPlatform == cc.PLATFORM_OS_IPHONE or curPlatform == cc.PLATFORM_OS_IPAD
end

function platform_is_android()
    return g_application:getTargetPlatform() == cc.PLATFORM_OS_ANDROID
end


function platform_utils_init_bugly()
    print('platform_utils_init_bugly', buglyInitCrashReport, __bugly_inited__)
    local appid = g_script_conf['game_info'].bugly_app_id
    if buglyInitCrashReport and not __bugly_inited__ and is_valid_str(appid) then
        buglySetAppChannel(game_get_engine_channel_name())
        buglySetAppVersion(tostring(game_get_engine_sub_version()))
        local bDebug = g_native_conf['debug_control'].bIsBuglyDebugMode
        local logLevel = bDebug and cc.EXT_BUGLY_CR_LOG_LEVEL.Off or cc.EXT_BUGLY_CR_LOG_LEVEL.Verbose
        print('buglyInitCrashReport', appid, bDebug, logLevel)
        buglyInitCrashReport(appid, bDebug, logLevel)

        rawset(_G, '__bugly_inited__', true)
    end
end

function platform_utils_set_uid(uid)
    platform_set_uid_in_java(uid)

    if __bugly_inited__ then
        -- bugly user id
        buglySetUserId(tostring(uid))
    end
end

function platform_utils_report_bug(errorMsg, msg)
    if g_application:getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
        return
    end

    local engineVersion = g_native_conf['check_update_info'].cur_engine_version
    local cur_patch_version = g_native_conf['cur_patch_version']

    if __bugly_inited__ then
        buglyReportLuaException(string.format('[%d][%d]%s', engineVersion, cur_patch_version, errorMsg), msg, false)
    elseif platform_report_scripts_error then
        local infoString
        xpcall(function()
            local chanelName = platform_get_app_channel_name()
            local cur_multilang_index = g_native_conf['cur_multilang_index']
            local engineRecommendVersion = utils_game_get_engine_sub_version()
            local info = {
                ['device_name'] =  platform_get_device_name(),
                ['trigger_time'] = os.date('%Y%m%d%H', os.time()),
                ['chanel_engine_patch_lang_no'] = chanelName .. '|' .. engineVersion .. '|' .. cur_patch_version .. '|' .. cur_multilang_index,
                ['engine_sub_version'] = engineRecommendVersion,
            }
            infoString = luaext_json_encode(info) .. '\n' .. msg
        end, function(e)
            print('format traceback msg error:', e)
            infoString = msg
        end)

        platform_report_scripts_error(infoString)
    end
end

local contacts
-- 获取通讯录
function utils_get_contacts(callback,taskId)
    taskId = taskId or platform_get_contacts_task()
    local status = platform_get_sm_stat(taskId)
    if contacts then
       callback(contacts)
    end
    delay_call(1, function()
        if(status == "RUNNING") then
            utils_get_contacts(callback ,taskId)
        else
            if(status == "OK") then
                local data = platform_get_contacts()
                contacts = data
                callback(contacts)
                return false
            end
            if status == 'EXPIRED' or status == 'FAIL'  then
                close_loading_panel('CONTACT_PEOPLE')
                message(T('请打开通讯录权限'))
                return
            end
        end
    end)
end

-- 加载经纬度
local have_send_location
function utils_get_location(callback,sendCallback)
    local taskId = platform_get_location()
    local status = platform_get_sm_stat(taskId)
    if have_send_location then
       callback()
    end
    delay_call(1, function()
        local status = platform_get_sm_stat(taskId)
        if status == "RUNNING" then
            return 1
        else
            if(status == "OK") then
                have_send_location = true
                sendCallback(platform_get_last_longitude(), platform_get_last_latitude())
                return
            end
            if status == 'EXPIRED' or status == 'FAIL'  then
                message(T('请打开手机定位'))
                close_loading_panel('NEARBY_PEOPLE')
                return
            end
        end
    end)
end

local DOWNLOAD_STATUS = cc.EXT_DOWNLOAD_STATUS

save_init_http_request = http_request
if not save_init_luaext_download_file then
    rawset(_G, 'save_init_luaext_download_file', luaext_download_file)
end

local _netHttpLog = nil

function ios_http_request(method, url, args, form, bRetry, bNotUploadError, requestHeader)

    print('start ios_http_request', method, url)
    if string.lower(method) == 'get' then
        method = 'Get'
    elseif string.lower(method) == 'post' then
        method = 'Post'
    end

    local nTryCount = 1
    _netHttpLog = g_log_mgr.get_or_create_log('NET_HTTP')

    if not bNotUploadError then
        _netHttpLog:PrintHttp(true, method, url, args or form)
    end

    local timeout = 5
    local httpHandler = {}

     if not requestHeader then
        requestHeader = {}
        requestHeader['Cache-Control'] = 'no-cache'
    end

    local params = nil
    if args then
        local t_params_str = luaext_json_encode(args)
        params = t_params_str
    elseif form then
        if is_string(form) then
            params = form
            
            requestHeader['Content-type'] = 'text/plain'
        else
            local t_params_str = luaext_json_encode(form)
            params = t_params_str
        end
    end

    local header = nil
    if requestHeader then
        local req_header_str = luaext_json_encode(requestHeader)
        header = req_header_str
    end


    local progress_func = function()end
    local success_func = function()end
    local fail_func = function()end

    local function retry()
        nTryCount = nTryCount + 1
        if nTryCount > 5 then
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
                platform_ios_http_request(method, url, timeout, params, header, progress_func, fail_func, success_func)
            end)
        end
    end

    fail_func = function(errorcode, description)
        if not bNotUploadError then
            _netHttpLog:Printf('error [%s]:[%s]', url, str(errorcode))
            --test delete cache 
            -- utils_test_upload_log2server('http_request_error', {errorcode = errorcode, description = description})
        end

        if bRetry then
            retry()
        else
            if not bNotUploadError then
                _netHttpLog:Printf('on_fail')
            end

            if httpHandler.on_fail then
                httpHandler.on_fail(errorcode)
            end
        end
    end

    progress_func = function(curr, total)
        -- print("download data ", curr, total)
    end

    success_func = function(data)
        -- print("get data success ", data)
        -- print("get data success ", url)
        if not bNotUploadError then
            _netHttpLog:PrintHttp(false, method, url, data)
        end

        if httpHandler.on_success then
            httpHandler.on_success(data)
        end
    end
       
    platform_ios_http_request(method, url, timeout, params, header, progress_func, fail_func, success_func)
    return httpHandler
end

-- 当 cc.PLATFORM_OS_ANDROID 并且 platform_is_method_static_and_public("HttpDownloadFile", COMMON_INTERFACES) 返回true的时候可以用
function android_http_request(method, url, args, form, bRetry, bNotUploadError, requestHeader)
    local nTryCount = 1
    _netHttpLog = g_log_mgr.get_or_create_log('NET_HTTP')
    if not bNotUploadError then
        _netHttpLog:PrintHttp(true, method, url, args or form)
    end
    
    local timeoutToCall = 5
    local paramsToCall = {}
    local headerToCall = {}
    local httpHandler = {}

    if requestHeader then
        headerToCall = requestHeader
    else
        headerToCall['Cache-Control'] = 'no-cache'
    end

    if args then
        paramsToCall = args  
    elseif form then
        if is_string(form) then
            paramsToCall = form
            headerToCall['Content-type'] = 'text/plain'
        else
            paramsToCall = form
        end
    end
    if is_table(paramsToCall) then
        paramsToCall = luaext_json_encode(paramsToCall)
    end
    headerToCall = luaext_json_encode(headerToCall)

    local times1 = utils_get_tick()
    local retryFunc = function() end

    local progress_func = function(curr, total)
    end

    local complete_func = function(isSuccess, data)
        if isSuccess then
            -- success
            print("get data success ", url)
            if not bNotUploadError then
                _netHttpLog:PrintHttp(false, method, url, data)
            end
    
            if httpHandler.on_success then
                httpHandler.on_success(data)
            end
        else
            -- failure
            local errorcode = -1
            local description = data or ""
            if not bNotUploadError then
                _netHttpLog:Printf('error [%s]:[%s]', url, str(errorcode))
                --test delete cache 
                -- utils_test_upload_log2server('http_request_error', {errorcode = errorcode, description = description})
            end
    
            if bRetry then
                retryFunc()
            else
                if not bNotUploadError then
                    _netHttpLog:Printf('on_fail')
                end
    
                if httpHandler.on_fail then
                    httpHandler.on_fail(errorcode)
                end
            end
        end
    end
    
    retryFunc = function()
        nTryCount = nTryCount + 1
        if nTryCount > 5 then
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
                platform_android_http_download_data(url, method, paramsToCall, headerToCall, timeoutToCall,  progress_func, complete_func)
                -- TODO not supported interface
            end)
        end
    end

    local isCallSuccess = platform_android_http_download_data(url, method, paramsToCall, headerToCall, timeoutToCall,  progress_func, complete_func)
    if isCallSuccess then
        return httpHandler
    else
        __G__TRACKBACK__('android http util has an error, method:[%s], url:[%s], args:[%s], form:[%s]', method, url, str(args), str(form))
        return save_init_http_request('POST', url, args, form, bRetry, bNotUploadError, requestHeader)
    end 
end

function ios_http_download_file(url, path, index, callback)

    local invokeCallback = function(eventType, ...)
        if callback then
            callback(eventType, ...)
        end
    end

    local function progressFunc(curr, total)
        invokeCallback(DOWNLOAD_STATUS.STATUS_PROGRESS, curr, curr, total)
    end

    local function compeleteFunc(success, errorcode, error_msg)
        if success then
            invokeCallback(DOWNLOAD_STATUS.STATUS_SUCCEED)
        else
            invokeCallback(DOWNLOAD_STATUS.STATUS_ERROR)
        end
    end

    print("start _ios_download_file down load file", url)
    local timeout = 5
    platform_ios_http_download_file(url, path, timeout, progressFunc, compeleteFunc)
end

function android_http_download_file(url, path, index, callback)

    local invokeCallback = function(eventType, ...)
        if callback then
            callback(eventType, ...)
        end
    end

    local function progressFunc(current, total)
        invokeCallback(DOWNLOAD_STATUS.STATUS_PROGRESS, current, current, total)
    end
    local function completeFunc(isSuccess, path)
        if isSuccess then
            invokeCallback(DOWNLOAD_STATUS.STATUS_SUCCEED)
        else
            invokeCallback(DOWNLOAD_STATUS.STATUS_ERROR)
        end
    end

    local timeout = 5
    print("start _android_download_file down load file", url)
    local isCallSuccess = platform_android_http_download_file(url, path, timeout, progressFunc, completeFunc)
    if not isCallSuccess then
        __G__TRACKBACK__('android http util has an error, url:[%s], path:[%s]', url, path)
        save_init_luaext_download_file(url, path, index, callback)
    end 

end

local curPlatform = g_application:getTargetPlatform()
if (curPlatform == cc.PLATFORM_OS_IPHONE or curPlatform == cc.PLATFORM_OS_IPAD) and utils_is_use_new_http_download and utils_is_use_new_http_download() then
    http_request = ios_http_request
    luaext_download_file = ios_http_download_file
elseif (curPlatform == cc.PLATFORM_OS_ANDROID) and utils_is_use_new_http_download and utils_is_use_new_http_download() then
    http_request = android_http_request
    luaext_download_file = android_http_download_file
end
