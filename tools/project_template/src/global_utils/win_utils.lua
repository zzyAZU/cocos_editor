--[[
	win platform utils
]]

__G__TRACKBACK__ = function(...)
    local errorMsg = string.format(...)
    local msg = debug.traceback(errorMsg)
    print(msg)

    win_confirm('bug', msg)
    return msg
end

--颜色选择框
function win_choose_color(r, g, b, callback)
    win_show_choose_color_dialog(r, g, b)
    g_eventHandler:AddCallbackOnce('global_on_choose_color', callback)
end

--called by c++
function global_on_choose_color(r, g, b)
    g_eventHandler:Trigger('global_on_choose_color', r, g, b)
end

function global_on_window_resize()
    utils_restart_game()
end

function global_on_drop_file(filePaths, position)
    for i, filePath in ipairs(filePaths) do
        filePaths[i] = string.gsub(filePath, "\\", "/")
    end
    g_logicEventHandler:Trigger('logic_event_on_drop_file', filePaths, position)
end

local function _getWinPath(path)
    if path == '' or not g_fileUtils:isDirectoryExist(path) then
        return ''
    end

    path = string.gsub(path, '/', '\\')
    if path:sub(-1, -1) == '\\' then
        path = path:sub(1, -2)
    end
    return path
end

local function _convertPath(ret, path, bFullPath)
    if ret == '' then
        return ret
    end
    
    ret = ret:gsub('\\', '/')
    
    if not bFullPath then
        path = path:gsub('\\', '/')

        if ret:find(path) ~= 1 then
            message(string.format('请选择[%s]下面的文件或文件夹', path))
            return ''
        end
        ret = ret:sub(#path + 2, -1)
    end
    return ret
end

local function _getRetPath(ret, path, bFullPath)
    if is_table(ret) then
        for i, v in ipairs(ret) do
            ret[i] = _convertPath(ret[i], path, bFullPath)
        end
    else
        ret = _convertPath(ret, path, bFullPath)
    end

    if ret == '' then
        ret = nil
    end
    print('ret path', ret)
    return ret
end

-- 优化频繁的打开文件的选择目录的操作
local _recentOpenFilePath = {}

--[[开单个文件]]
function win_open_file(title, path, ext, bFullPath)
    path = _getWinPath(path)
    -- print('win_open_file', title, path, ext)

    local ret = win_openFile(title, _recentOpenFilePath[path] or path, ext)

    if ret ~= '' then
        _recentOpenFilePath[path] = string.gsub(ret, '\\[^\\]+$', '')
    end

    return _getRetPath(ret, path, bFullPath)
end

--[[开多个文件]]
function win_open_multiple(title, path, ext, bFullPath)
    path = _getWinPath(path)
    -- print('win_openMultiple', title, path, ext)

    local ret = win_openMultiple(title, _recentOpenFilePath[path] or path, ext)
    if #ret > 0 then
        _recentOpenFilePath[path] = string.gsub(ret[1], '\\[^\\]+$', '')
    end
    return _getRetPath(ret, path, bFullPath)
end

--[[开目录]]
function win_open_directory(title, path, bFullPath)
    path = _getWinPath(path)
    -- print('win_open_directory', title, path)

    return _getRetPath(win_openDirectory(title, path), path, bFullPath)
end

local _recentSaveFilePath = {}

--[[保存文件名]]
function win_save_file(title, path, bFullPath)
    path = _getWinPath(path)
    -- print('win_saveFile', title, path)

    local ret = win_saveFile(title, _recentSaveFilePath[path] or path .. '\\save_file', '')
    if #ret > 0 then
        _recentSaveFilePath[path] = string.gsub(ret, '\\[^\\]+$', '')  .. '\\save_file'
    end

    return _getRetPath(ret, path, bFullPath)
end

function win_confirm(title, message, callback)
    title = title or '确认'
    win_message_box(title, message, 0)
    if callback then
        callback()
    end
end

function win_confirm_yes_no(title, message, callbackYes, callbackNo)
    title = title or '确认'
    local status = win_message_box(title, message, 2)
    -- 2 3
    if status == 2 then
        callbackYes()
    elseif callbackNo then
        callbackNo()
    end
end

function win_confirm_yes_no_cancle(title, message, callbackYes, callbackNo, callbackCancle)
    title = title or '确认'
    local status = win_message_box(title, message, 3)
    -- 2 3 1
    if status == 2 then
        callbackYes()
    elseif status == 3 then
        if callbackNo then
            callbackNo()
        end
    else
        if callbackCancle then
            callbackCancle()
        end
    end
end

local clipboardStr = ''
function win_get_data_from_clipboard()
    return clipboardStr
end

function win_copy_data2clipboard(constent)
    clipboardStr = constent
end

function win_execute_client_cmd(cmd_line)
    if string.match(cmd_line, "^@.+$") then
        print('exec scripts')
        local code = string.match(cmd_line, "^@(.+)$")
        loadstring(code)()
    elseif string.match(cmd_line, "^#.+$") then
        print('exec file')
        local fileName = string.match(cmd_line, "^#(.+)$")
        local code = g_fileUtils:getStringFromFile(fileName)
        loadstring(code)()
    end
end

function win_explorer(filePath)
    filePath = string.gsub(filePath, '/', '\\')
    if g_fileUtils:isFileExist(filePath) then
        os.execute('explorer /select, ' .. filePath)
    else
        os.execute('explorer ' .. filePath)
    end
end

function win_list_files(dir)
    dir = string.gsub(dir, '\\', '/')
    if string.sub(dir, -1) ~= '/' then
        dir = dir .. '/'
    end

    local ret = {}
    local startIndex = #dir + 1
    for _, path in ipairs(g_fileUtils:listFiles(dir)) do
        local isDir = string.sub(path, -1) == '/'
        local name = string.sub(path, startIndex, isDir and -2 or -1)
        if name ~= '.' and name ~= '..' then
            table.insert(ret, {
                path = path,
                name = name,
                is_dir = isDir,
            })
        end
    end

    return ret
end

function platform_share_web_to_weixin(url, title, description)
    message("分享网页到微信好友：在windows客户端不可用")
end

function platform_share_web_to_circle(url, title, description)
    message("分享网页到朋友圈：在windows客户端不可用")
end

function platform_share_image_to_weixin(imgPath)
    message("分享图片到微信好友：在windows客户端不可用")
end

function platform_share_image_to_circle(imgPath)
    message("分享图片到朋友圈：在windows客户端不可用")
end

function platform_report_panel_begin(panelName)
end

function platform_report_panel_end(panelName)
end

function platform_report_game_event(key)
    print('【windows】 reportGameEvent:', key)
end

function platform_pay(orderId, amount, goodsName, callback)
    message('windows一定支付成功')
    callback(0)
end

function platform_pay_cash(orderId, amount, goodsName, callback)
    message('windows一定支付成功')
    callback(0)
end

function platform_get_image_by_camera(callback)
    message("windows没法拍照")
end

function platform_get_image_from_storage(callback)
    message("windows没法选择照片")
end

function platform_choose_and_upload_image(source, skey, maxBytes, callback)
    message('windows没法选择照片')
end

-- 临时处理相册上传问题
function platform_choose_and_upload_photo(src, source, skey, maxBytes, callback)
    message('windows没法选择照片')
end

function platform_get_network_type()
    local test_net_work_type = g_native_conf['debug_control']['test_net_work_type']
    if is_valid_str(test_net_work_type) then
        return test_net_work_type
    else
        return 'wifi'
    end
end

function platform_app_alarm(alarmType, delay, title, content, extra)
    print('win32 platform_app_alarm', alarmType, delay, title, content, extra)
end

function platform_cancel_app_alarm(alarmType)
   print('win32 platform_cancel_app_alarm', alarmType) 
end

function platform_get_launch_extra()
    return ''
end

function platform_get_app_channel_name()
    local channeName = 'win32'
    local debugControl = g_conf_mgr.get_native_conf('debug_control')
    if debugControl and debugControl.curChannelName and debugControl.curChannelName ~= '' then
        channeName = debugControl.curChannelName
    end
    return channeName
end

function platform_get_device_uuid()
end

function platform_get_device_id()
    local ret = g_conf_mgr.get_native_conf('debug_control').win32ID
    if not is_valid_str(ret) then
        ret = win_get_uuid()
    end
    return ret
end

function platform_get_device_name()
    return "windows"
end

function platform_report_scripts_error(msg)
end

function platform_add_string_to_clipboard(s)
    
end

-- public static String sendSMS(String number, String content)
function platform_send_sms(number, content)
    message("发送短信了")
    return ''
 end

function platform_get_contacts_task()
    return 1234
end

-- public static String getContacts()
function platform_get_contacts()
    local contacts = 
    {[1] = {
            ["name"] = "七十",
            ["number"] = "18699426374",
    },
    [2] = {
            ["name"] = "爹",
            ["number"] = "13286865776",
    },
    [3] = {
            ["name"] = "二十",
            ["number"] = "11111111120",
    },
    [4] = {
            ["name"] = "二十一",
            ["number"] = "11111111121",
    }}
    return contacts
end

function platform_get_sm_stat(taskId)
    return 'OK'
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
    return 123
end
-- double getLastLatitude()纬度
function platform_get_last_latitude()
    return 23.12
end
-- double getLastLongitude()经度
function platform_get_last_longitude()
    return 113.3675  
end

function platform_set_lang()
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
    return ''
end

-- 获取外部存储器的路径
function platform_get_storage_path()
    return g_fileUtils:getWritablePath()
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

-- 获取图片
function platform_get_and_solve_image(width, height, cmpress_rate, filepath)
end

function platform_solve_scale_size_rate_image(width, height, compress_rate, filepath)
end

function platform_get_device_free_space()
    return -1
end

-- 从相册选择图片并压缩保存到指定目录, 1 - 拍照  2 - 从相册选择
function platform_get_and_compress_image(source, size, toPtah)
end

-- 把指定图片等比缩放之后保存到另一个指定目录
function platform_scale_image_from_path(absolutePathFrom, width, height, absolutePathTo)
end

function platform_upload_files_to_server(tag, files, mediaType, url, sessionKey)
end

function platform_open_application_page(packageName, className, actionName, uriString, paramsString)
end

function platform_start_other_application(packageName, actionName, uriString, paramsString)
end

function share_images_to_wechat(imagePathsArray, isToFriends)
end

function platform_get_share_state(callback)
    callback(true)
end

function platform_get_badam_imei()
end

function platform_get_badam_uuid()
end

function platform_get_battery_quantity()
    return -1, false
end
