--[[
    android platform utils
]]

local _callStaticMethod = utils_android_call_static_method

local AVATAR_HELPER_CLASS = "org/cocos2dx/lib/common/AvatarHelper"
local UPLOAD_HELPER_CLASS = "org/cocos2dx/lib/common/UploadHelper"
local COMMON_INTERFACES = "org/cocos2dx/lib/common/CommonInterfaces"
local SPECIAL_INTERFACES = "org/cocos2dx/lua/SpecialInterfaces"

local runLoop = function(fn, interval)
    delay_call(interval, function()
        local ret = fn()
        if ret then
            return interval
        end
    end)
end

function platform_droid_log(tag, content)
    _callStaticMethod(COMMON_INTERFACES, "androidLog", {tag, content}, "(Ljava/lang/String;Ljava/lang/String;)V")
end

local platform_get_avatar_status = function()
    return _callStaticMethod(AVATAR_HELPER_CLASS, "getStatus", {}, "()I")
end

function platform_get_image_by_camera(callback)
    _callStaticMethod(COMMON_INTERFACES, "getImageByCamera", {}, "()V")
    runLoop(function()
        local status = platform_get_avatar_status()
        if status ~= -1 then
            callback(status)
            return false
        end
        return true
    end, 1)
end

function platform_get_image_from_storage(callback)
    _callStaticMethod(COMMON_INTERFACES, "getImageFromStorage", {}, "()V")
    runLoop(function()
        local status = platform_get_avatar_status()
        if status ~= -1 then
            callback(status)
            return false
        end
        return true
    end, 1)
end

function platform_share_web_to_weixin(url, title, description, icon)
    if platform_is_method_static_and_public("shareWebToWeixinWithIcon", SPECIAL_INTERFACES) and is_valid_str(icon) then
        _callStaticMethod(
            SPECIAL_INTERFACES, "shareWebToWeixinWithIcon",
            {url, title, description, icon},
            "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
        )
    else
        _callStaticMethod(
            SPECIAL_INTERFACES, "shareWebToWeixin",
            {url, title, description},
            "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
        )
    end
end

function platform_share_web_to_circle(url, title, description, icon)
    if platform_is_method_static_and_public("shareWebToCircleWithIcon", SPECIAL_INTERFACES) and is_valid_str(icon) then
        _callStaticMethod(
            SPECIAL_INTERFACES, "shareWebToCircleWithIcon",
            {url, title, description, icon},
            "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
        )
    else
        _callStaticMethod(
            SPECIAL_INTERFACES, "shareWebToCircle",
            {url, title, description},
            "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
        )
    end
end

function platform_share_image_to_weixin(imgPath)
    _callStaticMethod(SPECIAL_INTERFACES, "shareImageToWeixin",
            {imgPath},
            "(Ljava/lang/String;)V")
end

function platform_share_image_to_circle(imgPath)
    _callStaticMethod(SPECIAL_INTERFACES, "shareImageToCircle",
            {imgPath},
            "(Ljava/lang/String;)V")
end

function platform_upload_head_img(sessionkey, callback)
    local uploadUrl = g_conf_mgr.get_url_conf('game_url').game_hall_upload_head_img_url
    _callStaticMethod(AVATAR_HELPER_CLASS, "uploadImage", {uploadUrl, sessionkey}, "(Ljava/lang/String;Ljava/lang/String;)V")
    runLoop(function()
        local status = _callStaticMethod(AVATAR_HELPER_CLASS, "getUploadStatus", {}, "()I")
        if status ~= 0 then
            local result = _callStaticMethod(AVATAR_HELPER_CLASS, "getUploadResult", {}, "()Ljava/lang/String;")
            callback(status == 1, result)
            return false
        end
        return true
    end, 1)
end

function platform_report_panel_begin(panelName)
    _callStaticMethod(SPECIAL_INTERFACES, "onPanelBegin",
            {panelName},
            "(Ljava/lang/String;)V")
end

function platform_report_panel_end(panelName)
    _callStaticMethod(SPECIAL_INTERFACES, "onPanelEnd",
            {panelName},
            "(Ljava/lang/String;)V")
end

function platform_report_game_event(key)
    _callStaticMethod(SPECIAL_INTERFACES, "onGameEvent",
            {key},
            "(Ljava/lang/String;)V")
end

-- 添加了callback参数
-- 老下载器先直接调用callback（无参数），再开始下载
-- 新下载器下载成功了不弹出安装界面调用callback(参数为文件的本地地址)，如果不传callback下载成功了直接打开安装界面
-- 新下载器不支持打开本地apk安装界面的包还是直接调用callback（无参数），再开始下载，下载完成自动弹出安装界面
function platform_download_apk(title, url, filename, description, md5, callback)
    title = GetTextByLanguageI(title)
    if not platform_is_method_static_and_public("downloadAppFastNew", COMMON_INTERFACES) then
        if callback then
            callback()
        end
        local parms = {title, url, filename, description, md5}
        local funDesc = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
         _callStaticMethod(SPECIAL_INTERFACES, "startDownload", parms, funDesc)
        return true
    else
        local downloadApkTag = string.format("%s%s%s", "downloadApk", utils_get_md5_from_string(url) ,utils_get_md5_from_string(utils_get_tick()))
        local messageTable = {
            str_title = title,
            str_notice = T('正在下载...'),
            str_downloading = T('正在下载'),
            str_error = T('下载错误'),
            str_paused = T('暂停'),
            str_finished = T('下载完成'),
            str_md5_error = T('校验失败'),
            start_tip = T('开始下载'),
            auto_open = callback and "false" or "true",
            callback_tag = downloadApkTag,
        }
        local parms = {url, md5, "", filename, luaext_json_encode(messageTable)}
        local funDesc = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
        _callStaticMethod(COMMON_INTERFACES, "downloadAppFastNew", parms, funDesc)
        if callback and platform_is_method_static_and_public("openLocalApp", COMMON_INTERFACES) then
            g_eventHandler:AddCallback('global_platform_call_lua_func', function(tag, status, msg, res)
                if tag == downloadApkTag then
                    callback(res)
                end
            end)
        elseif callback then
            callback()
        end
        return true
    end
end

function platform_get_app_name()
    return _callStaticMethod(COMMON_INTERFACES, "getAppName", {}, "()Ljava/lang/String;")
end

function platform_set_uid_in_java(uid)
    _callStaticMethod(SPECIAL_INTERFACES, "setUidInJava", {uid}, "(I)V")
end

function platform_uid_in_java(uid)
    _callStaticMethod(SPECIAL_INTERFACES, "removeUidInJava", {uid}, "(I)V")
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
    local params = {source, url, skey, maxBytes}
    local methodStr = "(ILjava/lang/String;Ljava/lang/String;I)I"
    local key = _callStaticMethod(UPLOAD_HELPER_CLASS, "chooseAndUploadImage", params, methodStr)
    runLoop(function()
        local status = _callStaticMethod(UPLOAD_HELPER_CLASS, "getUploadStatus", {key}, "(I)I")
        if status ~= 0 then
            callback(status == 1, _callStaticMethod(UPLOAD_HELPER_CLASS, "getUploadResult", {key}, "(I)Ljava/lang/String;"))
            return false
        end
        return true
    end, 1)
end

-- 临时处理相册上传问题 
function platform_choose_and_upload_photo(url, source, skey, maxBytes, callback)
    local params = {source, url, skey, maxBytes}
    local methodStr = "(ILjava/lang/String;Ljava/lang/String;I)I"
    local key = _callStaticMethod(UPLOAD_HELPER_CLASS, "chooseAndUploadImage", params, methodStr)
    runLoop(function()
        local status = _callStaticMethod(UPLOAD_HELPER_CLASS, "getUploadStatus", {key}, "(I)I")
        if status ~= 0 then
            callback(status == 1, _callStaticMethod(UPLOAD_HELPER_CLASS, "getUploadResult", {key}, "(I)Ljava/lang/String;"))
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
        return _callStaticMethod(COMMON_INTERFACES, 'getNetWorkType', {}, "()Ljava/lang/String;")
    end
end

-- getLaunchExtra
-- delay seconds
-- void setAlarm(int alarmType, int alarmTimestamp, String title, String content, String extra)
function platform_app_alarm(alarmType, delay, title, content, extra)
    assert(delay > 0)
    local alarmTimestamp = math.floor(os.time() + delay)

    local params = {alarmType, alarmTimestamp, title, content, extra}
    local methodStr = "(IILjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
     _callStaticMethod(COMMON_INTERFACES, "setAlarm", params, methodStr)
end

-- void cancelAlarm(int alarmType)
function platform_cancel_app_alarm(alarmType)
    _callStaticMethod(COMMON_INTERFACES, "cancelAlarm", {alarmType}, "(I)V")
end

-- String getLaunchExtra()
-- 获取该app被打开时候是如何被打开的 正常启动时空字符串
function platform_get_launch_extra()
    return _callStaticMethod(COMMON_INTERFACES, "getLaunchExtra", {}, "()Ljava/lang/String;")
end

-- 获取友盟
function platform_get_app_channel_name()
    local channeName = _callStaticMethod(SPECIAL_INTERFACES, "getChannelName", {}, "()Ljava/lang/String;")
    local debugControl = g_conf_mgr.get_native_conf('debug_control')
    if debugControl and debugControl.curChannelName and debugControl.curChannelName ~= '' then
        channeName = debugControl.curChannelName
    end
    return channeName
end

function platform_get_device_uuid()
    return _callStaticMethod(COMMON_INTERFACES, "getDeviceUuid", {}, "()Ljava/lang/String;")
end

function platform_set_device_uuid(device_uuid)
    if platform_is_method_static_and_public("setUntrueDeviceUuid", COMMON_INTERFACES) then
        _callStaticMethod(COMMON_INTERFACES, "setUntrueDeviceUuid", {tostring(device_uuid)}, "(Ljava/lang/String;)V")
    end
end

function platform_get_device_id()
    local isReadV2UuidSuccess, v2DeviceIdInNewUuidFile = xpcall(android_v3_read_v2_device_id_from_new_file, __G__TRACKBACK__)
    if isReadV2UuidSuccess and is_valid_str(v2DeviceIdInNewUuidFile) then
        return v2DeviceIdInNewUuidFile
    end
    local game_hall_login_info = g_native_conf['game_hall_login_info']
    local ret = game_hall_login_info.fast_login_gen_uid
    if ret == nil or ret == '' then
        local bSucceed
        ret, bSucceed = _callStaticMethod(COMMON_INTERFACES, "getDeviceId", {}, "()Ljava/lang/String;")
        if not bSucceed then
            ret = nil
        end
    end
    if ret == nil or ret == '' then
        local deviceName = platform_get_device_name()
        ret = string.format("fuid%s_%s", string.gsub(deviceName, ' ', ''), utils_get_uuid(20))
        game_hall_login_info.fast_login_gen_uid = ret
        g_native_conf['game_hall_login_info'] = game_hall_login_info
    end
    return ret
end

function platform_get_device_name()
    local ret = 'android'
    pcall(function()
        local name = _callStaticMethod(COMMON_INTERFACES, "getDeviceName", {}, "()Ljava/lang/String;")
        if name ~= '' then
            ret = name
        end
    end)

    return ret
end

function platform_report_scripts_error(msg)
    pcall(function()
        _callStaticMethod(SPECIAL_INTERFACES, 'reportError', {msg}, "(Ljava/lang/String;)V")
    end)
end

-- public static void addStringToClipboard(String s)
function platform_add_string_to_clipboard(s)
    _callStaticMethod(COMMON_INTERFACES, "addStringToClipboard", {s}, "(Ljava/lang/String;)V")
end

-- public static String sendSMS(String number, String content)
function platform_send_sms(number, content)
    return _callStaticMethod(COMMON_INTERFACES, "sendSMS", {number, content}, "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;")
end


-- 
function platform_get_contacts_task()
    return _callStaticMethod(COMMON_INTERFACES, "startGetContactsTask", {}, "()Ljava/lang/String;")
end

-- 获取已完成的获取通讯录任务的获取结果
function platform_get_contacts()
    local sContents = _callStaticMethod(COMMON_INTERFACES, "getContacts", {}, "()Ljava/lang/String;")
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
    return _callStaticMethod(COMMON_INTERFACES, "getStat", {taskId, true}, "(Ljava/lang/String;Z)Ljava/lang/String;")
end

-- 新的分享
function platform_new_share_web_to_weixin(url, title, description, icon)
    if platform_is_method_static_and_public("shareWebWithIcon", SPECIAL_INTERFACES) and is_valid_str(icon) then
        return _callStaticMethod(
            SPECIAL_INTERFACES, "shareWebWithIcon",
            {url, title, description, 'WEIXIN', icon},
            "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;"
        )
    else
        return _callStaticMethod(
            SPECIAL_INTERFACES, "shareWeb",
            {url, title, description, 'WEIXIN'},
            "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;"
        )
    end
end

function platform_new_share_web_to_circle(url, title, description, icon)
    if platform_is_method_static_and_public("shareWebWithIcon", SPECIAL_INTERFACES) and is_valid_str(icon) then
        return _callStaticMethod(
            SPECIAL_INTERFACES, "shareWebWithIcon",
            {url, title, description, 'CIRCLE', icon},
            "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;"
        )
    else
        return _callStaticMethod(
            SPECIAL_INTERFACES, "shareWeb",
            {url, title, description, 'CIRCLE'},
            "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;"
        )
    end
end

function platform_new_share_image_to_weixin(imgPath)
    return _callStaticMethod(SPECIAL_INTERFACES, "shareImage",
            {imgPath, 'WEIXIN'},
            "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;")
end

function platform_new_share_image_to_circle(imgPath)
    return _callStaticMethod(SPECIAL_INTERFACES, "shareImage",
        {imgPath, 'CIRCLE'},
        "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;")
end

-- String getLocation()
function platform_get_location()
    return _callStaticMethod(COMMON_INTERFACES, "getLocation", {}, "()Ljava/lang/String;")
end

-- double getLastLatitude() 维度
function platform_get_last_latitude()
    return _callStaticMethod(COMMON_INTERFACES, "getLastLatitude", {}, "()F")
end

-- double getLastLongitude() 经度
function platform_get_last_longitude()
    return _callStaticMethod(COMMON_INTERFACES, "getLastLongitude", {}, "()F")
end

-- public static void setLang(String lang)
function platform_set_lang()
    return _callStaticMethod(SPECIAL_INTERFACES, "setLang", {g_native_conf.cur_multilang_index}, "(Ljava/lang/String;)V")
end

-- 获取登陆时候要使用的账号体系名称
function platform_get_accounts_name()
    return _callStaticMethod(SPECIAL_INTERFACES, "getAccountsName", {}, "()Ljava/lang/String;")
end

-- 获取支付时候使用的sdk名称
function platform_get_payment_name()
    return _callStaticMethod(SPECIAL_INTERFACES, "getPaymentName", {}, "()Ljava/lang/String;")
end

-- 获取剪切板内容,如果为空返回""
function platform_get_pasteboard_content()
    return _callStaticMethod(COMMON_INTERFACES, "getStringFromClipBoard", {}, "()Ljava/lang/String;")
end

-- 获取外部存储器的路径,如果没有存储器或者没有读写权限则返回""
function platform_get_storage_path()
    return _callStaticMethod(COMMON_INTERFACES, "getStoragePath", {}, "()Ljava/lang/String;")
end

-- 重启APP，用AlarmManager，先关闭APP，seconds秒钟后重启
function platform_restart_this_app(seconds)
    if seconds == nil then
        seconds = 0
    end
    _callStaticMethod(COMMON_INTERFACES, "restartThisApp", {seconds}, "(I)V")
    return true
end

-- 如果方法存在并且public static的则返回true, 否则返回false
function platform_is_method_static_and_public(methodName, class)
    if not class then
        class = COMMON_INTERFACES
    end
    return _callStaticMethod(class, "isMethodStaticAndPublic", {methodName}, "(Ljava/lang/String;)Z")
end

-- 用户是否安装了某个应用, 安卓的参数为包名，如果安装了或者引擎不支持这个接口返回true
-- 只判断包名，对于不同版本的应用包名不一样的情况就多请求几次，判断下所有的可能出现的包名
function platform_is_package_installed(packageName)
    return _callStaticMethod(COMMON_INTERFACES, "isPackageInstalled", {packageName}, "(Ljava/lang/String;)Z")
end

-- 关闭启动页面
function platform_hide_start_page()
    _callStaticMethod(COMMON_INTERFACES, "hideStartPage", {}, "()V")
end

-- 获取图片,根据width height的比例让用户剪切图片
function platform_get_and_solve_image(tag, width, height, compress_rate, filepath)
    local rate = 100
    if is_number(compress_rate) and compress_rate > 0 and compress_rate < 1 then
        rate = math.floor(compress_rate * 100)
    end
    local parms = {tag, width, height, rate, filepath} -- java层的compress rate是0到100的int
    local funDesc = "(Ljava/lang/String;IIILjava/lang/String;)V"
    _callStaticMethod(UPLOAD_HELPER_CLASS, "getAndSolveImage", parms, funDesc)
end

-- 获取图片，按原图的宽高比例缩放原图
function platform_solve_scale_size_rate_image(tag, width, height, compress_rate, filepath)
    local rate = 100
    if is_number(compress_rate) and compress_rate > 0 and compress_rate < 1 then
        rate = math.floor(compress_rate * 100)
    end
    local params = {tag, width, height, rate, filepath} -- java层的compress rate是0到100的int
    local funDesc = "(Ljava/lang/String;IIILjava/lang/String;)V"
    _callStaticMethod(UPLOAD_HELPER_CLASS, "getAndScaleImage", params, funDesc)
end

-- 获取设备空闲空间 单位: M  出错时:-1
function platform_get_device_free_space()
    if not platform_is_method_static_and_public("getDeviceFreeSpace", COMMON_INTERFACES) then
        return -1
    end
    return _callStaticMethod(COMMON_INTERFACES, "getDeviceFreeSpace", {}, "()F")
end

-- 从相册选择图片并压缩保存到指定目录, 1 - 拍照  2 - 从相册选择
function platform_get_and_compress_image(tag, source, size, toPtah)
    -- local size = 100
    if is_number(size) and size > 0 then
        size = math.floor(size)
    end
    toPtah = g_fileUtils:getWritablePath() .. toPtah
    local parms = {tag, source, size, toPtah} -- 大小kb，toPath相对路径
    local funDesc = "(Ljava/lang/String;IILjava/lang/String;)V"
    _callStaticMethod(UPLOAD_HELPER_CLASS, "getAndCompressImage", parms, funDesc)
end

-- 把指定图片等比缩放之后保存到另一个指定目录
function platform_scale_image_from_path(relativePathFrom, width, height, relativePathTo)
    local absolutePathFrom = g_fileUtils:getWritablePath() .. relativePathFrom
    local absolutePathTo = g_fileUtils:getWritablePath() .. relativePathTo
    local parms = {absolutePathFrom, width, height, absolutePathTo} -- 大小kb，toPath相对路径
    local funDesc = "(Ljava/lang/String;IILjava/lang/String;)I"
    return _callStaticMethod(UPLOAD_HELPER_CLASS, "scaleImageFromPath", parms, funDesc)
end


--[[
    文件上传

    tag lua调用一个异步方法的时候传过来的tag，lua在事件监听的时候要判断是否是自己传进去的tag
    files json类型的文件路径数组
    mediaType 文件类型	
    url 上传问价你的目标url
    time 超时时间，大于30则当30来处理
    sessionKey session

        files 属性：
        [{"name":"file1", "path":"aa/bb/cc1.jpg"}, {"name":"file2", "path":"aa/bb/cc2.jpg"}]
        json数组字符串，数组的每个item是一个包含name和path的json对象，
     	
     	mediaType参数： 
		text/html ： HTML格式
		text/plain ：纯文本格式      
		text/xml ：  XML格式
		image/gif ：gif图片格式    
		image/jpeg ：jpg图片格式 
		image/png：png图片格式
		
		以application开头的媒体格式类型：
		application/xhtml+xml ：XHTML格式
		application/xml     ： XML数据格式
		application/atom+xml  ：Atom XML聚合格式    
		application/json    ： JSON数据格式
		application/pdf       ：pdf格式  
		application/msword  ： Word文档格式
		application/octet-stream ： 二进制流数据（如常见的文件下载）  
]]
function platform_upload_files_to_server(tag, files, mediaType, url, time, sessionKey)
    if not platform_is_method_static_and_public("uploadFilesToServer", UPLOAD_HELPER_CLASS) then
        return
    end
    files[1].path = g_fileUtils:getWritablePath() .. files[1].path
    files[2].path = g_fileUtils:getWritablePath() .. files[2].path
    local params = {tag, luaext_json_encode(files), mediaType, url, time, sessionKey}
    local description = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ILjava/lang/String;)V"
    _callStaticMethod(UPLOAD_HELPER_CLASS, "uploadFilesToServer", params, description)
    return true
end

--[[
    获取android.os.Build类的可访问属性, 获取不到或者没有这个属性返回null

        key属性：
        1, BOARD 主板：The name of the underlying board, like goldfish.
        2, BOOTLOADER 系统启动程序版本号：The system bootloader version number.
        3, BRAND 系统定制商：The consumer-visible brand with which the product/hardware will be associated, if any.
        4, CPU_ABI cpu指令集：The name of the instruction set (CPU type + ABI convention) of native code.
        5, CPU_ABI2 cpu指令集2：The name of the second instruction set (CPU type + ABI convention) of native code.
        6, DEVICE 设备参数：The name of the industrial design.
        7, DISPLAY 显示屏参数：A build ID string meant for displaying to the user
        8, FINGERPRINT 唯一识别码：A string that uniquely identifies this build. Do not attempt to parse this value.
        9, HARDWARE 硬件名称：The name of the hardware (from the kernel command line or /proc).
        10, HOST
        11, ID 修订版本列表：Either a changelist number, or a label like M4-rc20.
        12, MANUFACTURER 硬件制造商：The manufacturer of the product/hardware.
        13, MODEL 版本即最终用户可见的名称：The end-user-visible name for the end product.
        14, PRODUCT 整个产品的名称：The name of the overall product.
        15, RADIO 无线电固件版本：The radio firmware version number. 在API14后已过时。使用getRadioVersion()代替。
        16, SERIAL 硬件序列号：A hardware serial number, if available. Alphanumeric only, case-insensitive.
        17, TAGS 描述build的标签,如未签名，debug等等。：Comma-separated tags describing the build, like unsigned,debug.
        18, TIME
        19, TYPE build的类型：The type of build, like user or eng.
        20, USER

]]
function platform_android_get_build_info(key)
    if not platform_is_method_static_and_public("getBuildInfo", COMMON_INTERFACES) then
        return
    end
    return _callStaticMethod(COMMON_INTERFACES, "getBuildInfo", {key}, "(Ljava/lang/String;)Ljava/lang/String;")
end

-- android 获取manifest里面的meta data信息，返回值为string,获取不到则返回null
function platform_android_get_meta_data(key)
    if not platform_is_method_static_and_public("getMetaDataString", COMMON_INTERFACES) then
        return
    end
    return _callStaticMethod(COMMON_INTERFACES, "getMetaDataString", {key}, "(Ljava/lang/String;)Ljava/lang/String;")
end

-- action为android的Intent.ACTION_XXXX字符串
-- paramsString为json数组
--[[
    {
        {
            ["name"] = "desc",
            ["type"] = "string",
            ['value'] = "descripe"
        },
        {
            ["name"] = "status",
            ["type"] = "int",
            ['value'] = 0
        }
    }
        
]]
function platform_open_application_page(packageName, className, actionName, uriString, paramsString)
    if not platform_is_method_static_and_public("openApplicationPage", COMMON_INTERFACES) then
        return
    end
    local parms = {packageName, className, actionName, uriString, paramsString}
    local funDesc = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Z"
    return _callStaticMethod(COMMON_INTERFACES, "openApplicationPage", parms, funDesc)
end

function platform_start_other_application(packageName, actionName, uriString, paramsString)
    if not platform_is_method_static_and_public("startOtherApplication", COMMON_INTERFACES) then
        return
    end
    local parms = {packageName, actionName, uriString, paramsString}
    local funDesc = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Z"
    return _callStaticMethod(COMMON_INTERFACES, "startOtherApplication", parms, funDesc)
end

-- 返回值为json，获取不到就返回空字符串
function platform_android_get_package_info(packageName)
    if not platform_is_method_static_and_public("getPackageInfo", COMMON_INTERFACES) then
        return ""
    end
    local parms = {packageName}
    local funDesc = "(Ljava/lang/String;)Ljava/lang/String;"
    return _callStaticMethod(COMMON_INTERFACES, "getPackageInfo", parms, funDesc)   
end

-- 分享多个图片到微信，第一个参数为图片路径的json数据，第二个参数为false的时候分享到朋友圈，true为分享给好友
function share_images_to_wechat(imagePathsArray, isToFriends)
    if not platform_is_method_static_and_public("shareImagesToWechat", COMMON_INTERFACES) then
        return
    end
    local parms = {imagePathsArray, isToFriends}
    local funDesc = "(Ljava/lang/String;Z)Z"
    return _callStaticMethod(COMMON_INTERFACES, "shareImagesToWechat", parms, funDesc)
end

function platform_get_share_state(callback, taskId)
    callback(true)
end

function platform_get_badam_imei()
    if not platform_is_method_static_and_public("getBadamIMEI", COMMON_INTERFACES) then
        local ret, bSucceed = _callStaticMethod(COMMON_INTERFACES, "getDeviceId", {}, "()Ljava/lang/String;")
        if bSucceed then
            return ret
        end
    else
        return _callStaticMethod(COMMON_INTERFACES, "getBadamIMEI", {}, "()Ljava/lang/String;")
    end
end

function platform_get_badam_uuid()
    if not platform_is_method_static_and_public("getBadamUuid", COMMON_INTERFACES) then
        return
    end
    return _callStaticMethod(COMMON_INTERFACES, "getBadamUuid", {}, "()Ljava/lang/String;")
end

--[[
    platform_android_http_download_data("https://wordsapiv1.p.mashape.com/words/inevitable", "get",
	luaext_json_encode({}),
	luaext_json_encode({}),
	30,
	function(a, b)
	end, function(a, b)
        message("isSuccess:" .. str(a) .. ", " .. str(b))
	end
)
]]
function platform_android_http_download_data(url, method, params, header, timeout, progressFunc, completeFunc)
    if not platform_is_method_static_and_public("httpDownloadData", COMMON_INTERFACES) then
        return 
    end
    assert(is_string(params))
    assert(is_string(header))
    local androidHttpDownloadTag = string.format("%s%s%s", "downloadData", utils_get_md5_from_string(url) ,utils_get_md5_from_string(utils_get_tick()))
    local params = {
        tag = androidHttpDownloadTag,
        url = url,
        method = method,
        params = params,
        header = header,
        timeout = timeout,
        step = 1, -- lua progress 回调函数每百分之多少调用一次，由于java调用lua太频繁会卡主ui这里做了个安全措施，卡住了ui可以把这个值设的大一点
        millisecStep = 100, -- 回调函数每多少毫秒之后才能回调一次
    }
    g_eventHandler:AddCallback('global_platform_call_lua_func', function(tag, status, msg, res)
        if tag == androidHttpDownloadTag then
            -- executing success
            local message = luaext_json_dencode(msg)
            if not is_table(message) then
                completeFunc(false, message.msg)
            elseif message.url ~= url then
                completeFunc(false, message.msg)
            elseif message.funcName == "progress" then
                -- 进度
                progressFunc(message.current, message.total)
            elseif message.funcName == "success" then
                -- 成功
                completeFunc(true, res)
            elseif message.funcName == "failure" then
                -- 错误
                completeFunc(false, message.msg)
            end
        end
    end)
    -- 参数大概是这样的格式 {"url":"http://aaa.com/bbb/ccc.json", "method":"get","params":"{}", "header":"{}","timeout":30,"tag":"xxxx", "step":1}
    local funDesc = "(Ljava/lang/String;)Z"
    return _callStaticMethod(COMMON_INTERFACES, "httpDownloadData", {luaext_json_encode(params)}, funDesc)
end

--[[
    platform_android_http_download_file("http://gamecenter.badambiz.com/gamehall10023wy__BADAMBIZ_mobi_new.apk",
	platform_get_storage_path() .. "/dwonload_new/dwonload_new_badam.apk", 30,
	function(a, b)
		print("progress")
	end, function(a, b)
		message("isSuccess:" .. str(a) .. ",path:" .. str(b))
	end
)
]]
function platform_android_http_download_file(url, path, timeout, progressFunc, completeFunc)
    if not platform_is_method_static_and_public("httpDownloadFile", COMMON_INTERFACES) then
        return
    end
    local androidHttpDownloadTag = string.format("%s%s%s", "downloadData", utils_get_md5_from_string(url) ,utils_get_md5_from_string(utils_get_tick()))
    local params = {
        tag = androidHttpDownloadTag,
        url = url,
        path = path,
        timeout = timeout,
        step = 1, -- lua progress 回调函数每百分之多少调用一次，由于java调用lua太频繁会卡主ui这里做了个安全措施，卡住了ui可以把这个值设的大一点
        millisecStep = 100, -- 回调函数每多少毫秒之后才能回调一次
    }
    g_eventHandler:AddCallback('global_platform_call_lua_func', function(tag, status, msg, res)
        if tag == androidHttpDownloadTag then
            -- executing success
            local message = luaext_json_dencode(msg)
            if not is_table(message) then
                completeFunc(false, message.msg)
            elseif message.url ~= url then
                completeFunc(false, message.msg)
            elseif message.funcName == "progress" then
                -- 进度
                progressFunc(message.current, message.total)
            elseif message.funcName == "success" then
                -- 成功
                completeFunc(true, res)
            elseif message.funcName == "failure" then
                -- 错误
                completeFunc(false, message.msg)
            end
        end
    end)
    -- 参数大概是这样的格式 {"url":"http://aaa.com/bbb/ccc.apk","path":"/ddd/eee/fff.apk","timeout":30,"tag":"xxxx", "step":1}
    local funDesc = "(Ljava/lang/String;)Z"
    return _callStaticMethod(COMMON_INTERFACES, "httpDownloadFile", {luaext_json_encode(params)}, funDesc)
end

--[[
    定时器有关接口
]]

-- delaytimer 毫秒之后，每periodTime触发一次tag为 TIMER_TASK_TRIGGER 的 global_platform_call_lua_func 事件, 函数返回值为定时器的唯一 key
local function platform_android_timer_set_task(delayTime, periodTime)
    if not platform_is_method_static_and_public("timerSetTask", COMMON_INTERFACES) then
        return
    end
    if not is_number(delayTime) or delayTime < 0 then
        return
    end
    if not is_number(periodTime) or  periodTime < 0 then
        periodTime = 0-- 零默认不重复
    end
    return _callStaticMethod(COMMON_INTERFACES, "timerSetTask", {delayTime, periodTime}, "(II)Ljava/lang/String;")
end

-- 查询定时任务是否存在
local function platform_android_timer_has_task(taskKey)
    if not platform_is_method_static_and_public("timerHasTask", COMMON_INTERFACES) then
        return
    end
    if not is_valid_str(taskKey) then
        return
    end
    return _callStaticMethod(COMMON_INTERFACES, "timerHasTask", {taskKey}, "(Ljava/lang/String;)Z")
end

-- 清理定时任务
function platform_android_timer_clear_task(taskKey)
    if not platform_is_method_static_and_public("timerClearTask", COMMON_INTERFACES) then
        return
    end
    if not is_valid_str(taskKey) then
        return
    end
    return _callStaticMethod(COMMON_INTERFACES, "timerClearTask", {taskKey}, "(Ljava/lang/String;)Z")
end

-- 添加有回调的延时任务
function platform_android_timer_delay_call(delayTime, callback)
    if not is_number(delayTime) or delayTime < 0 or not platform_is_method_static_and_public("timerSetTask", COMMON_INTERFACES) then
        return
    end
    local taskKey = platform_android_timer_set_task(delayTime)
    g_eventHandler:AddCallback('global_platform_call_lua_func', function(tag, status, msg, response)
        if tag == "TIMER_TASK_TRIGGER" and response == taskKey then
            if callback then callback() end
        end
    end)
    return taskKey
end

-- 获取电量 -1 获取失败
function platform_get_battery_quantity()
    if not platform_is_method_static_and_public("getBatteryProperties", COMMON_INTERFACES) then
        return -1, false
    end
    local info = _callStaticMethod(COMMON_INTERFACES, "getBatteryProperties", {}, "()Ljava/lang/String;")
    info = luaext_json_dencode(info)
    if not info or not is_number(info.level) or not is_number(info.scale) or info.level < 0 or info.scale < 0 then
        return -1, false
    end
    return math.floor(info.level / info.scale * 100), true
end

-- 退出程序（参数为状态码，一般都是零零表示正常退出）
function platform_android_exit_with_code(code)
    if not platform_is_method_static_and_public("exitWithCode", COMMON_INTERFACES) then
        return
    end
    if not is_number(code) then
        code = 0
    end
    return _callStaticMethod(COMMON_INTERFACES, "exitWithCode", {code}, "(I)Z")
end

-- h5游戏sdk，shared preferences里保存的用户信息
function platform_android_badam_game_set_user(params)
    if not platform_is_method_static_and_public("badamGameSetUser", SPECIAL_INTERFACES) then
        return
    end
    assert(is_table(params))
    assert(is_valid_str(params.userNickname)) -- 用户昵称
    assert(is_valid_str(params.userAvatar)) -- 用户头像
    assert(is_valid_str(params.userSession)) -- 用户session
    return _callStaticMethod(SPECIAL_INTERFACES, "badamGameSetUser", {luaext_json_encode(params)}, "(Ljava/lang/String;)Z")
end

-- h5游戏sdk，删除shared preferences里保存的用户信息
function platform_android_badam_game_delete_user()
    if not platform_is_method_static_and_public("badamGameDeleteUser", SPECIAL_INTERFACES) then
        return
    end
    return _callStaticMethod(SPECIAL_INTERFACES, "badamGameDeleteUser", {}, "()Z")
end

-- h5游戏sdk，启动游戏
function platform_android_badam_game_start_game(params)
    if not platform_is_method_static_and_public("badamGameStartGame", SPECIAL_INTERFACES) then
        return
    end
    assert(is_table(params))
    assert(is_valid_str(params.gameUrl)) -- 游戏url
    assert(is_valid_str(params.loadingIcon)) -- 加载游戏的时候的icon
    params.maxAge = params.maxAge or 60 * 60 * 1 -- 游戏缓存失效时间，秒为单位
    params.loadingTitle = params.loadingTitle or "" -- 加载游戏的时候的title
    params.isJsClose = params.isJsClose or true -- 是否由游戏内js代码关闭loading页面
    params.isPullRefresh = params.isPullRefresh or true -- 是否允许下来刷新
    params.isGoBack = params.isGoBack or true -- 是否允许回退页面
    params.gameTitle = params.gameTitle or "" -- 游戏标题，如果有合法字符串会显示一个标题栏
    params.isPortraitScreen = params.isPortraitScreen or false -- 是否横屏
    -- preload 信息
    assert(is_valid_str(params.prefixUrl)) -- 前缀链接
    assert(is_valid_str(params.zipUrl)) -- 资源下载链接
    params.isRequestWifi = params.isRequestWifi or false -- 是否需要wifi环境下才能下载
    -- user 信息
    assert(is_valid_str(params.userNickname)) -- 用户昵称
    assert(is_valid_str(params.userAvatar)) -- 用户头像
    assert(is_valid_str(params.userSession)) -- 用户session
    params.isSaveUser = params.isSaveUser or true -- 是否在shared preferences保存用户信息，用来点击快捷方式的时候启动游戏
    return _callStaticMethod(SPECIAL_INTERFACES, "badamGameStartGame", {luaext_json_encode(params)}, "(Ljava/lang/String;)Z")
end

-- h5游戏sdk，预加载游戏
function platform_android_badam_game_preload_game(params)
    if not platform_is_method_static_and_public("badamGamePreloadGame", SPECIAL_INTERFACES) then
        return
    end
    assert(is_table(params))
    assert(is_valid_str(params.prefixUrl)) -- 前缀链接
    assert(is_valid_str(params.zipUrl)) -- 资源下载链接
    params.isRequestWifi = params.isRequestWifi or false -- 是否需要wifi环境下才能下载
    return _callStaticMethod(SPECIAL_INTERFACES, "badamGamePreloadGame", {luaext_json_encode(params)}, "(Ljava/lang/String;)Ljava/lang/String;")
end

-- h5游戏sdk，获取预加载状态(0表示没信息，1表示正在下载，2表示下载完成，-1表示这个任务出错了)
function platform_android_badam_game_preload_status(key)
    key = key or ""
    if not platform_is_method_static_and_public("badamGamePreloadStatus", SPECIAL_INTERFACES) then
        return 0
    end
    return _callStaticMethod(SPECIAL_INTERFACES, "badamGamePreloadStatus", {key}, "(Ljava/lang/String;)I")
end

-- h5游戏sdk，创建快捷方式，点击之后默认用最后一次设置的用户信息直接打开h5游戏，如果用户信息不存在就打开游戏大厅
function platform_android_badam_game_create_shortcut(params)
    if not platform_is_method_static_and_public("badamGameCreateShortcut", SPECIAL_INTERFACES) then
        return
    end
    assert(is_table(params))
    assert(is_valid_str(params.gameUrl)) -- 游戏url
    assert(is_valid_str(params.loadingIcon)) -- 加载游戏的时候的icon
    params.maxAge = params.maxAge or 60 * 60 * 1 -- 游戏缓存失效时间，秒为单位
    params.loadingTitle = params.loadingTitle or "" -- 加载游戏的时候的title
    params.isJsClose = params.isJsClose or true -- 是否由游戏内js代码关闭loading页面
    params.isPullRefresh = params.isPullRefresh or true -- 是否允许下来刷新
    params.isGoBack = params.isGoBack or true -- 是否允许回退页面
    params.gameTitle = params.gameTitle or "" -- 游戏标题，如果有合法字符串会显示一个标题栏
    params.isPortraitScreen = params.isPortraitScreen or false -- 是否横屏
    assert(is_valid_str(params.shortcutName)) -- 快捷方式名称
    assert(is_valid_str(params.shortcutIcon)) -- 快捷方式icon
    -- preload 信息
    assert(is_valid_str(params.prefixUrl)) -- 前缀链接
    assert(is_valid_str(params.zipUrl)) -- 资源下载链接
    params.isRequestWifi = params.isRequestWifi or false -- 是否需要wifi环境下才能下载
    return _callStaticMethod(SPECIAL_INTERFACES, "badamGameCreateShortcut", {luaext_json_encode(params)}, "(Ljava/lang/String;)Z")
end

function platform_android_badam_game_delete_shortcut(shortcutName)
    if not platform_is_method_static_and_public("badamGameDeleteShortcut", SPECIAL_INTERFACES) then
        return
    end
    return _callStaticMethod(SPECIAL_INTERFACES, "badamGameDeleteShortcut", {shortcutName}, "(Ljava/lang/String;)Z")
end

-- 此接口不靠谱，只能作为参考。返回true可能是模拟器，也有可能是没有拨号功能的android平板手机
-- 此接口的原理是那些原生的模拟器根据系统特征信息来判断是否是模拟器，
-- 而对于那些主流的定制过的模拟器就没法用这些信息判断了，针对这些模拟器只会判断能否跳转到拨号界面，当然结果某些没有拨号功能的平板手机也被误认为是模拟器。
function platform_android_is_android_emulator()
    if not platform_is_method_static_and_public("isAndroidEmulator", COMMON_INTERFACES) then
        return
    end
    return _callStaticMethod(COMMON_INTERFACES, "isAndroidEmulator", {}, "()Z")
end

-- 打开sd卡里面的app安装界面
function platform_android_open_local_app(path)
    if not platform_is_method_static_and_public("openLocalApp", COMMON_INTERFACES) then
        return
    end
    return _callStaticMethod(COMMON_INTERFACES, "openLocalApp", {path}, "(Ljava/lang/String;)Z")
end
