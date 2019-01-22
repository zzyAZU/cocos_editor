--[[
    ios platform utils
]]

local _callStaticMethod = utils_ios_call_static_method
local _callStaticMethodCallback = utils_ios_call_static_method_callback
local ACTIVITY_CLASS = "LuaObjectCBridge"
local AlarmObjectCBridge = "AlarmObjectCBridge"
local ShareObjectCBridge = "ShareObjectCBridge"
local PayObjectCBridge = 'PayObjectCBridge'
local ToolsObjectCBridge = 'ToolsObjectCBridge'
local ToolsInfo = 'ToolsInfo'

local SOURCE = {
    [1] = 'CAMERA',
    [2] = 'STORAGE'
}

local runLoop = function(fn, interval)
    delay_call(0, function()
        local ret = fn()
        if ret then
            return interval
        end
    end)
end

function platform_check_order_result(orderId)
    local param = {
        orderId = orderId 
    }
    return _callStaticMethod(PayObjectCBridge, "checkOrderResult", param)
end

--[[
    param @orderId      游戏大厅的订单号
    param @amount       价格，单位为分
    param @goodsName    商品名称，显示用
    param @callback     支付结果回调，有一个int参数, 0成功，-1失败, -2用户取消
    param @productId    apple store对应的商品id
]]
local _bInChargePay = false
function platform_pay(orderId, amount, goodsName, callback, productId)
    assert_msg(productId and productId ~= '', 'productId %s not valid', str(productId))

    if _bInChargePay then
        return
    end

    _bInChargePay = true

    local OLD_PAY_SDK_VERSION = 2 -- 老的支付对应SDK的版本
    local ios_apple_pay_http_url = g_conf_mgr.get_url_conf('game_url').ios_apple_pay_http_url
    if utils_get_sdk_version() > OLD_PAY_SDK_VERSION then
        ios_apple_pay_http_url = g_conf_mgr.get_url_conf('game_url').ios_apple_pay_http_url_v2
    end
    local param = {
        orderId = orderId,
        amount = amount,
        name = goodsName,
        productId = productId,
        url = ios_apple_pay_http_url
    }
    show_loading_panel("APPLE_PAY", 200)
    _callStaticMethod(PayObjectCBridge, "pay", param)
    runLoop(function()
        local status = platform_check_order_result(orderId)
        if status == -1 then
            _bInChargePay = false
            callback(status)
            close_loading_panel("APPLE_PAY")
            return false
        elseif status ~= -1000 then
            _bInChargePay = false
            callback(status)

            xpcall(function()
                -- 充值成功的时候将订单发给服务器记录下来，方便服务器排查问题
                if status == 0 then
                    local sdkName = import('dialog.accounts.accounts_utils').get_sdk_name()
                    g_game_mgr.get_game_net('GameType_HALL').Request_CMD_ORDER_FINISH_REQ(orderId, sdkName)
                end
            end, __G__TRACKBACK__)

            close_loading_panel("APPLE_PAY")
            return false
        end
        return true
    end, 0.2)
end

--[[
    param @orderId      游戏大厅的订单号
    param @amount       价格，单位为分
    param @goodsName    商品名称，显示用
    param @callback     支付结果回调，有一个int参数, 0成功，-1失败, -2用户取消
]]
platform_pay_cash = platform_pay

local platform_get_avatar_status = function(type)
    return _callStaticMethod(ACTIVITY_CLASS, "getStatus", {idenfity = type})
end

function platform_get_image_by_camera(callback)
    runLoop(function()
        local status = platform_get_avatar_status('CAMERA')
        if status ~= -1 then
            callback(status)
            return false
        end
        return true
    end, 1)
end

function platform_get_image_from_storage(callback)
    runLoop(function()
        local status = platform_get_avatar_status('STORAGE')
        if status ~= -1 then
            callback(status)
            return false
        end
        return true
    end, 1)
end

function platform_share_web_to_weixin(url, title, description)
    local params = {
        url = url,
        title = title,
        description = description,
    }
    _callStaticMethod(ShareObjectCBridge, "shareWebToWeixin", params)
end

function platform_share_web_to_circle(url, title, description)
    local params = {
        url = url,
        title = title,
        description = description,
    }
    _callStaticMethod(ShareObjectCBridge, "shareWebToCircle", params)
end

function platform_share_image_to_weixin(imgPath)
    _callStaticMethod(ShareObjectCBridge, "shareImageToWeixin", {imagePath = imgPath})
end

function platform_share_image_to_circle(imgPath)
    _callStaticMethod(ShareObjectCBridge, "shareScreenToWeixin", {imagePath = imgPath})
end

function platform_upload_head_img(sessionkey, callback)
    
    local uploadUrl = g_conf_mgr.get_url_conf('game_url').game_hall_upload_head_img_url
    local params = {
        session = sessionkey,
        url = uploadUrl,
    }
    _callStaticMethod(ACTIVITY_CLASS, 'getImageFromStorage', params)
    runLoop(function()
        local status = _callStaticMethod(ACTIVITY_CLASS, "getUploadStatus", {ide = 'HEAD'})
        if status == 2 then
            close_loading_panel("USERINFO_UPLOAD_IMAGE")
            return false
        end
        if status ~= 0 then
            local result = _callStaticMethod(ACTIVITY_CLASS, "getUploadResult", {ide = 'HEAD'})
            callback(status == 1, result)
            return false
        end
        return true
    end, 1)
end

function platform_report_panel_begin(panelName)
    _callStaticMethod(ACTIVITY_CLASS, 'onPanelBegin', {panelname = panelName})
end

function platform_report_panel_end(panelName)
    _callStaticMethod(ACTIVITY_CLASS, 'onPanelEnd', {panelname = panelName})
end

function platform_report_game_event(key)
    _callStaticMethod(ACTIVITY_CLASS, 'onGameEvent', {eventname = key})
end

function platform_download_apk(title, url, filename, description, md5)
end

function platform_get_app_name()
    return _callStaticMethod(ACTIVITY_CLASS, 'getAppName')
end

function platform_set_uid_in_java(uid)
end

function platform_uid_in_java(uid)
end

--[[
选择图片并上传
    @param source   1 - 拍照  2 - 从相册选择
    @param url      上传目标地址
    @param skey     用户游戏sessionkey
    @param maxBytes 图片最大字节数，0为不限制。程序会自动压缩图片到不大于maxBytes的尺寸，不保证质量
    @param callback 结果回调，有两个参数，第一个success，true成功 false失败。 第二个参数result，成功时为服务器返回内容，失败时为出错提示
]]
function platform_choose_and_upload_image(source, skey, maxBytes, callback)
    local url = g_conf_mgr.get_url_conf('game_url').game_hall_upload_screenshot_url
    local params = {
        url = url,
        session = skey,
        maxBytes = maxBytes,
        source = SOURCE[source]
    }
    _callStaticMethod(ACTIVITY_CLASS, "chooseAndUploadImage", params)
    runLoop(function()
        local status = _callStaticMethod(ACTIVITY_CLASS, "getUploadStatus", {ide = 'IMAGE'})
        if status == 2 then
            close_loading_panel("UPLOAD_IMAGE")
            return false
        end
        if status ~= 0 then
            callback(status == 1, _callStaticMethod(ACTIVITY_CLASS, "getUploadResult", {ide = 'IMAGE'}))
            return false
        end
        return true
    end, 1)
end

-- 临时处理相册上传问题
function platform_choose_and_upload_photo(url, source, skey, maxBytes, callback)
    local params = {
        url = url,
        session = skey,
        maxBytes = maxBytes,
        source = SOURCE[source]
    }
    _callStaticMethod(ACTIVITY_CLASS, "chooseAndUploadImage", params)
    runLoop(function()
        local status = _callStaticMethod(ACTIVITY_CLASS, "getUploadStatus", {ide = 'IMAGE'})
        if status == 2 then
            close_loading_panel("UPLOAD_PHOTO")
            return false
        end
        if status ~= 0 then
            callback(status == 1, _callStaticMethod(ACTIVITY_CLASS, "getUploadResult", {ide = 'IMAGE'}))
            return false
        end
        return true
    end, 1)
end

-- none
-- wifi
-- 2g
-- 3g
-- 4g
-- mobile
function platform_get_network_type()
    local test_net_work_type = g_native_conf['debug_control']['test_net_work_type']
    if is_valid_str(test_net_work_type) then
        return test_net_work_type
    else
        return _callStaticMethod(ACTIVITY_CLASS, 'getNetWorkType')
    end
end

-- getLaunchExtra
-- delay seconds
-- void setAlarm(int alarmType, int alarmTimestamp, String title, String content, String extra)
function platform_app_alarm(alarmType, delay, title, content, extra)
    assert(delay > 0)
    local params = {
        typeI = str(alarmType),
        delay = str(delay),
        title = title,
        content = content,
        extra = extra
    }
    _callStaticMethod(AlarmObjectCBridge, "registerAlarm", params)
end

-- void cancelAlarm(NSString* alarmType)
function platform_cancel_app_alarm(alarmType)
    _callStaticMethod(AlarmObjectCBridge, "cancleAlarm", {typeI = str(alarmType)})
end

-- String getLaunchExtra()
-- 获取该app被打开时候是如何被打开的 正常启动时空字符串
function platform_get_launch_extra()
    return _callStaticMethod(AlarmObjectCBridge, "getLaunchExtra")
end

-- 获取友盟
function platform_get_app_channel_name()
    local channeName = _callStaticMethod(ACTIVITY_CLASS, "getChannelName")
    local debugControl = g_conf_mgr.get_native_conf('debug_control')
    if debugControl and debugControl.curChannelName and debugControl.curChannelName ~= '' then
        channeName = debugControl.curChannelName
    end
    return channeName
end

function platform_get_device_uuid()
end

function platform_get_device_id()
    return _callStaticMethod(ACTIVITY_CLASS, "getDeviceId")
end

function platform_get_device_name()
    local ret = 'iphone'
    ret = _callStaticMethod(ACTIVITY_CLASS, 'getAppName')
    return ret
end

function platform_report_scripts_error(msg)
     _callStaticMethod(ACTIVITY_CLASS, 'reportError', {message = msg})
end

-- public static void addStringToClipboard(String s)
function platform_add_string_to_clipboard(s)
    _callStaticMethod(ACTIVITY_CLASS, "addStringToClipboard", {content = s})
end

-- public static String sendSMS(String number, String content)
function platform_send_sms(number, content)
    local tb = {
        phone = number,
        content = content,
    }
    return _callStaticMethod(ACTIVITY_CLASS, "sendSMS", tb)
end


-- 
function platform_get_contacts_task()
    return _callStaticMethod(ACTIVITY_CLASS, "startGetContactsTask")
end

-- 获取已完成的获取通讯录任务的获取结果
function platform_get_contacts()
    local sContents = _callStaticMethod(ACTIVITY_CLASS, "getContacts")
    return eval(sContents)
end

local SM_STATUS = {
    RUNNING = "RUNNING",
    EXPIRED = "EXPIRED",
    OK = "OK",
    FAIL = "FAIL",
    NOTFOUND = "NOTFOUND",    
}

-- public static String getStat(String taskId, boolean removeIfFound)
function platform_get_sm_stat(taskId)
    local tb = {
        taskId = taskId,
        isLocation = true
    }
    return _callStaticMethod(ACTIVITY_CLASS, "getStat", tb)
end

-- 新的分享
function platform_new_share_web_to_weixin(url, title, description)
end

function platform_new_share_web_to_circle(url, title, description)
end

function platform_new_share_image_to_weixin(imgPath)
end

function platform_new_share_image_to_circle(imgPath)
end

-- String getLocation()
function platform_get_location()
    return _callStaticMethod(ACTIVITY_CLASS, "getLocation")
end

-- double getLastLatitude() 维度
function platform_get_last_latitude()
    return _callStaticMethod(ACTIVITY_CLASS, "getLastLatitude")
end

-- double getLastLongitude() 经度
function platform_get_last_longitude()
    return _callStaticMethod(ACTIVITY_CLASS, "getLastLongitude")
end

-- public static void setLang(String lang)
function platform_set_lang()
    local language = g_conf_mgr.get_native_conf('cur_multilang_index')
    return _callStaticMethod(ACTIVITY_CLASS, "setLang", {lang = language})
end

-- 获取登陆时候要使用的账号体系名称
function platform_get_accounts_name()
    return "badam"
end

-- 获取支付时候使用的sdk名称
function platform_get_payment_name()
    return "badam"
end

-- 获取剪切板内容
function platform_get_pasteboard_content()
    return _callStaticMethod(ACTIVITY_CLASS, 'generalPateboard')
end

-- 获取外部存储器的路径
function platform_get_storage_path()
    return ''
end

-- 重启APP
function platform_restart_this_app(seconds)
end

-- 如果方法存在并且public static的则返回true, 否则返回false
function platform_is_method_static_and_public(methodName)
end

-- 用户是否安装了某个应用
function platform_is_package_installed(packageName)
    return true
end

-- 关闭启动页面
function platform_hide_start_page()
end

-- 获取处理图像
-- width 宽
-- height 高
-- cmpress_rate 压缩比例 0 - 1
-- filepath 文件路径  hello/zhangsan/hello.png  
-- isBundle是否是bundle '1' = true '0' = false
function platform_get_and_solve_image(width, height, cmpress_rate, filepath)
    local params = {
        width = width,
        height = height,
        rate = cmpress_rate,
        path = filepath,
        isBundle = '0'
    }
    _callStaticMethod(ACTIVITY_CLASS, "solvePicture", params)
end

-- 处理图片 保持原有图片比例等比例缩放宽高 指定缩放比例缩放
-- width 宽
-- height 高
-- cmpress_rate 压缩比例 0 - 1
-- filepath 文件路径  hello/zhangsan/hello.png  
function platform_solve_scale_size_rate_image(width, height, cmpress_rate, filepath)
    local params = {
        width = width,
        height = height,
        rate = cmpress_rate,
        path = filepath,
    }
    _callStaticMethod(ACTIVITY_CLASS, "solvePictureWithScale", params)
end

-- 获取设备空闲空间 单位:M  出错时:-1
function platform_get_device_free_space()
    local freesize, ok = _callStaticMethod(ToolsObjectCBridge, 'deviceFreeSpace')
    if not ok then
        return -1
    end
    if freesize == nil or tonumber(freesize) == nil then
        return -1
    end
    return tonumber(freesize)
end

-- 从相册选择图片并压缩保存到指定目录, 1 - 拍照  2 - 从相册选择
function platform_get_and_compress_image(tag, source, size, toPtah)
    if is_number(size) and size > 0 then
        size = math.floor(size)
    end
    local params = {
        idenfity = SOURCE[source],
        tag = tag,
        size = size,
        path = toPtah
    }
    return _callStaticMethod('UploadImageVersionTwo', "getAndCompressImage", params)
end

-- 把指定图片按照给定宽高缩放之后保存到另一个指定目录
function platform_scale_image_from_path(originPath, width, height, resultPath)
    local params = {
        orginPath = originPath,
        width = width,
        height = height,
        resultPath = resultPath
    }
    return _callStaticMethod('UploadImageVersionTwo', "scaleImageFromPath", params)
end

function platform_upload_files_to_server(tag, files, mediaType, url, time, sessionKey)
    local params = {
        tag = tag,
        files = luaext_json_encode(files),
        mediaType = mediaType,
        url = url,
        time = time,
        session = sessionKey
    }
    return _callStaticMethod('UploadImageVersionTwo', "uploadFileToServer", params)
end

function platform_open_application_page(packageName, className, actionName, uriString, paramsString)
end

function platform_start_other_application(packageName, actionName, uriString, paramsString)
end

function share_images_to_wechat(imagePathsArray, isToFriends)
end

-- 获取当前的分享状态
function platform_get_share_state(callback)
    callback(true)
end

function platform_get_badam_imei()
end

function platform_get_badam_uuid()
end

-- 获取当前系统版本 8.3 10.3.3
function platform_ios_get_system_version()
    local system_version, ok = _callStaticMethod(ToolsInfo, 'systemVersion')
    if ok and is_valid_str(system_version) then
        if tonumber(system_version) ~= nil then
            return tonumber(system_version)
        end
        local versions = string.split(system_version, '.')
        if #versions > 2 then
            return tonumber(versions[1]) + tonumber(versions[2]) * 0.1
        end
    end
    return 0
end

-- ios 11 的音效会出现崩溃问题所有打算使用 simple audio engine 来播放音效
function platform_ios_is_use_simple_audio_engine()
    local osVer = platform_ios_get_system_version()
    print('platform_ios_get_system_version', osVer)

    if not is_number(osVer) or osVer == 0 then
        return false
    end

    return osVer >= 10 or osVer < 9
end

function platform_set_device_uuid(device_uuid)

end

function platform_ios_http_request(method, url, timeout, params, header, progressFunc, failFunc, successFunc)

    local callback = function(status, msg, res)
        local message = luaext_json_dencode(msg)
        if message.url ~= url then
            failFunc(status, message.msg)
        elseif message.funcName == "progress" then
            -- 进度
            progressFunc(message.current, message.total)
        elseif message.funcName == "success" then
            -- 成功
            successFunc(res)
        elseif message.funcName == "failure" then
            -- 错误
            failFunc(status, message.msg)
        end
    end

    local _params = {
        method = method,
        url = url,
        timeout = timeout,
        params = params,
        header = header
    }
    
    return _callStaticMethodCallback('HttpRequestObjectCBridge', 'Http_Download_Data', _params, callback)
end

function platform_ios_http_download_file(url, path, timeout, progressFunc, comopeleteFunc)

    local callback = function(status, msg, res)
        local message = luaext_json_dencode(msg)
        if message.url ~= url then
            comopeleteFunc(false, status, message.msg)
        elseif message.funcName == "progress" then
            -- 进度
            progressFunc(message.current, message.total)
        elseif message.funcName == "success" then
            -- 成功
            comopeleteFunc(true)
        elseif message.funcName == "failure" then
            -- 错误
            comopeleteFunc(false, status, message.msg)
        end
    end

    local _params = {
        sourcePath = url,
        targetPath = path,
        timeout = timeout,
    }
    return _callStaticMethodCallback('HttpRequestObjectCBridge', 'Http_Download_File', _params, callback)
end

-- 获取剩余电量 -1 获取失败
function platform_get_battery_quantity()
    local battery, ok = _callStaticMethod(ToolsObjectCBridge, 'deviceBattery')
    if ok then
        return tonumber(battery) * 100, ok
    end
    return -1, ok
end
