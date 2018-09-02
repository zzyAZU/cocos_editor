--[[
    游戏逻辑常用的全局函数
]]

function message(message, ...)
    local msg = GetTextByLanguageI(message, ...)
    delay_call(0, function()
        g_panel_mgr.show_multiple_in_top_scene('common.dlg_common_tips_panel', msg)
    end)
end

function message_new(message, ...)
    local msg = GetTextByLanguageI(message, ...)
    delay_call(0, function()
        g_panel_mgr.show_multiple_in_top_scene('common.dlg_common_tips_new_panel', msg)
    end)
end

-- 显示确认面板
function confirm(content, callback, title, textYes, escFunc, notEscClosePanel, isClickClose, closePanelFunc)
    return g_panel_mgr.show_multiple('common.dlg_confirm_panel', title, content , callback, textYes, escFunc, notEscClosePanel, isClickClose, closePanelFunc)
end

-- 显示确认取消面板
function confirm_yes_no(content, callback, title, textYes, textNo, noCallback, isClickClose)
    return g_panel_mgr.show_multiple('common.dlg_confirm_yes_no_panel', title, content, callback, textYes, noCallback, textNo, isClickClose)
end
-- 显示确认取消面板(内容为scroll view)
function confirm_yes_no_scroll(content, callback, title, textYes, textNo, noCallback)
    return g_panel_mgr.show_multiple('common.dlg_confirm_yes_no_scroll_panel', title, content, callback, textYes, noCallback, textNo)
end

-- 显示确认关闭面板
function confirm_yes_close(content, callback, title, textYes, escFunc)
    return g_panel_mgr.show_multiple('common.dlg_confirm_yes_close_panel', title, content, callback, textYes, escFunc)
end

local _showLoadingPanels = {}
function show_loading_panel(id, time, closeCallback)
    if _showLoadingPanels[id] then
        _showLoadingPanels[id]:close_panel()
    end

    _showLoadingPanels[id] = g_panel_mgr.show_multiple('common.dlg_loading_panel', time, function()
        _showLoadingPanels[id] = nil
        if closeCallback then closeCallback() end
    end)
end

function close_loading_panel(id)
    local panel = _showLoadingPanels[id]
    if panel then
        panel:close_panel()
        _showLoadingPanels[id] = nil
    end
end

function is_loading_panel_exists(id)
    return _showLoadingPanels[id] ~= nil
end

function GetServerTimeStamp()
    return g_net_mgr.get_server_time_stamp()
end

-- dir:
function utils_test_upload_content2server(content, fileName, dir, callback)
    local url = g_constant_conf['constant'].GAME_UPLOAD_LOG_FILE_URL .. '?filename=' .. fileName
    if dir then
        url = url ..'&dir=' .. dir
    end

    http_post(url, content, false, true).on_success = function()
        if callback then
            callback()
        end
    end
end

-- 当上传日志因为网络问题上传失败的时候会延时一段时间尝试重新发送
local _scheduleUploadContent = {}

local function _getWriteLogPath(type)
    if _scheduleUploadContent[type] then
        return g_fileUtils:getWritablePath() .. 'cache_upload_log_file_tmp_' .. type
    else
        return g_fileUtils:getWritablePath() .. 'cache_upload_log_file_' .. type
    end
end

local function _tryUploadLog2Server(type)
    print('_tryUploadLog2Server', type)

    if _scheduleUploadContent[type] then
        return
    end

    local filePath = _getWriteLogPath(type)
    if g_fileUtils:isFileExist(filePath) then
        local uploadContent = g_fileUtils:getStringFromFile(filePath)
        local url = g_constant_conf['constant'].GAME_UPLOAD_HTTP_ERR_URL .. '?dir=' .. type
        local handler = http_post(url, uploadContent, false, true)

        _scheduleUploadContent[type] = true

        handler.on_success = function()
            local oldTempFilePath = _getWriteLogPath(type)
            if g_fileUtils:isFileExist(oldTempFilePath) then
                local tmpContent = g_fileUtils:getStringFromFile(oldTempFilePath)
                g_fileUtils:removeFile(oldTempFilePath)
                g_fileUtils:writeStringToFile(tmpContent, filePath)
            elseif g_fileUtils:isFileExist(filePath) then
                g_fileUtils:removeFile(filePath)
            end
            g_conf_mgr.set_native_conf_k_v('test_not_upload_log_type_list', type, nil)
            _scheduleUploadContent[type] = nil
        end

        handler.on_fail = function()
            _scheduleUploadContent[type] = nil
        end
    end
end

local _scheduleUpload = nil
function utils_test_schedule_upload_log2server(delay)
    print('utils_test_schedule_upload_log2server', delay)
    if _scheduleUpload then
        return
    end

    _scheduleUpload = delay_call(5, function()
        for tp, _ in pairs(table.copy(g_native_conf['test_not_upload_log_type_list'])) do
            _tryUploadLog2Server(tp)
            -- 一次一次地发
            break
        end

        if table.is_empty(g_native_conf['test_not_upload_log_type_list']) then
            return delay
        else
            _scheduleUpload = nil
        end
    end)
end

-- 
function utils_test_upload_log2server(type, info)
    print('utils_test_upload_log2server')

    assert(is_valid_str(type))
    if is_string(info) then
        info = {content = info}
    end
    assert(is_table(info))

    info['wifi_state'] = platform_get_network_type()

    local uploadContent = luaext_json_encode(info) .. '\n'
    local url = g_constant_conf['constant'].GAME_UPLOAD_HTTP_ERR_URL .. '?dir=' .. type
    local handler = http_post(url, uploadContent, false, true)
    
    -- test
    -- handler.on_success = function()
    --     message("upload success")
    -- end

    handler.on_fail = function()
        g_conf_mgr.set_native_conf_k_v('test_not_upload_log_type_list', type, true)

        -- 追加到文件尾端
        local f = io.open(_getWriteLogPath(type), 'a')
        f:write(uploadContent)
        f:close()

        utils_test_schedule_upload_log2server(3600)
    end
end

function utils_remove_writable_path_folder_r(folderName)
    local folder = g_fileUtils:getWritablePath() .. folderName .. '/'
    if g_fileUtils:isDirectoryExist(folder) then
        g_fileUtils:removeDirectory(folder)
    end
end

--[[
websocket协程获取
    @param net       需要绑定的网络对象
    @param rsp       绑定的响应协议
    @param reqFunc     请求的函数
]]
function coroutine_get_socket_rsp(net, rsp, reqFunc)
    local co = coroutine.running()
    local bResume = false
    net:RegisterNetEvent(rsp, function(data)
        if bResume == false then
            bResume = true
            coroutine.resume(co, data)
        end
    end, nil, true)
    delay_call(1, function()
        if net:IsConnected() and bResume == false then
            return 1
        elseif bResume == false then
            bResume = true
            coroutine.resume(co)
            return
        end
    end)
    if net:IsConnected() then
        reqFunc()
    elseif bResume == false then
        bResume = true
        delay_call(0.5, function()
            coroutine.resume(co)
        end)
    end
    return coroutine.yield()
end

function coroutine_wait_seconds(delay)
    local co = coroutine.running()
    delay_call(delay, function()
        coroutine.resume(co)
    end)
    return coroutine.yield()
end

function coroutine_call_fun(fun)
    local co = coroutine.running()
    delay_call(0, function()
        fun()
        coroutine.resume(co)
    end)
    return coroutine.yield()
end

local _listRandom = {''}

for i = string.byte('0'), string.byte('9') do
    table.insert(_listRandom, string.char(i))
end

for i = string.byte('a'), string.byte('z') do
    table.insert(_listRandom, string.char(i))
end

for i = string.byte('A'), string.byte('Z') do
    table.insert(_listRandom, string.char(i))
end

function utils_get_uuid(num)
    local ret = {}
    math.randomseed(utils_get_tick())
    for i = 1, num do
        table.insert(ret, _listRandom[math.random(1, #_listRandom)])
    end
    return table.concat(ret)
end

local _costTime = {}
function profile(fun, name)
    if _costTime[name] == nil then
        _costTime[name] = 0
    end

    local cur = utils_get_tick()
    fun()
    local cost = utils_get_tick() - cur
    local total = _costTime[name] + cost
    _costTime[name] = total
    printf('[%s] cost time:%f total cost time %f', name, cost, total)
end

--中文转换为当前选定语言
function T(desc)
    local ret
    pcall(function()
        local multiLangConf = g_conf.info_scripts_multi_lang
        ret = multiLangConf[desc]['lang']
    end)

    if ret == nil or ret == '' then
        ret = desc
    end

    return ret
end

-- 用法:
-- GetTextByLanguageI(2, '111', '222', '333')
-- GetTextByLanguageI(asdf# {2} # {1} # {3} #sdfddd, '111', '222', '333')
function GetTextByLanguageI(s, ...)
    if s == nil then
        s = 'nil'
    end

    -- 多国处理
    if is_number(s) then
        local conf = g_conf.info_multi_language[s]
        if conf then
            s = conf.lang
        else
            s = tostring(s)
        end
    end

    local args = {...}
    if #args == 0 then
        return s
    else
        local ret, _ = string.gsub(s, '%{(%d+)(.-)%}', function(num, decorator)
            if decorator ~= '' then
                return string.format(decorator, args[tonumber(num)])
            else
                return tostring(args[tonumber(num)])
            end
        end)
        return ret
    end
end

-- **************************************uuid v2包升级相关（开始）******************************************************

-- -- 有关存储信息
local UUID_FILE_DIR = ".BADAM_GAME/"
local UUID_OLD_FILE_NAME = "uuid_file.txt"
local UUID_NEW_FILE_NAME = "uuid_file_v2.txt"
local possiblePaths = {
    "/storage/emulated/0/",
    "/storage/sdcard0/",
    "/mnt/sdcard/",
    "/sdcard/",
}

-- 保存
local function _android_save_device_id_to_new_file(storagePath, deviceIdString)
    assert(is_valid_str(storagePath))
    if not g_fileUtils:isDirectoryExist(storagePath) then
        return false
    end
    if not is_valid_str(deviceIdString) then
        __G__TRACKBACK__('UUID-V2, _android_save_device_id_to_new_file failed deviceIdString not valid：' .. deviceIdString)
        return false
    end

    local destinationFilePath = string.format("%s%s", storagePath, UUID_FILE_DIR)
    local destinationFileName = string.format("%s%s", destinationFilePath, UUID_NEW_FILE_NAME)

    if not g_fileUtils:isDirectoryExist(destinationFilePath) then
        local isCreateSuccess = g_fileUtils:createDirectory(destinationFilePath)
        if not isCreateSuccess then
            __G__TRACKBACK__(string.format('UUID-V2, _android_save_device_id_to_new_file createDirectory [%s] failed', destinationFilePath))
            return false
        end
    end
    local uuidFileContent = {
        ["uuid"] = deviceIdString,
        ["standard_md5"] = utils_get_md5_from_string(deviceIdString),
    }
    
    local bSaveOk = g_fileUtils:writeStringToFile(luaext_json_encode(uuidFileContent), destinationFileName)

    if bSaveOk then
        printf("UUID-V2, save device id to new file [%s] succeed", destinationFileName)
    else
        __G__TRACKBACK__(string.format("UUID-V2, save device id to new file [%s] failed", destinationFileName))
    end

    return bSaveOk
end

-- 获取
local function _android_get_device_id_from_new_file(storagePath)
    local ret = nil
    if is_valid_str(storagePath) then
        -- 有权限
        local destinationFileName = string.format("%s%s%s", storagePath, UUID_FILE_DIR, UUID_NEW_FILE_NAME)
        if g_fileUtils:isFileExist(destinationFileName) then
            -- 存在v2 uuid文件
            local deviceIdString = g_fileUtils:getStringFromFile(destinationFileName)
            local deviceIdTable = luaext_json_dencode(deviceIdString or "")
            if is_table(deviceIdTable)
            and is_string(deviceIdTable.uuid)
            and is_string(deviceIdTable.standard_md5)
            and utils_get_md5_from_string(deviceIdTable.uuid) == deviceIdTable.standard_md5 then
                ret = deviceIdTable.uuid
            end
        end
    end
    return ret
end

-- 在v3包从uuid file获取我们在v2包手动存储的device id(uuid格式)
function android_v3_read_v2_device_id_from_new_file()
    -- 只针对android
    if g_application:getTargetPlatform() ~= cc.PLATFORM_OS_ANDROID then
        return
    end
    if import('dialog.accounts.accounts_utils').get_sdk_name() ~= "badam" then
        return
    end
    -- getDeviceUuid接口存在说明这是一个uuid v2问题已经被修复的v3包
    if platform_is_method_static_and_public("getDeviceUuid") then
        -- v3, 如果v2 uuid文件存在就从文件读取device id返回
        local externalStoragePath = platform_get_storage_path() .. '/'
        local internalDeviceId = _android_get_device_id_from_new_file(g_fileUtils:getWritablePath())
        local externalDeviceId = _android_get_device_id_from_new_file(externalStoragePath)
        if not externalDeviceId then
            print("UUID-V3 , no device id in platform_get_storage_path, trying possible paths")
            for i,path in ipairs(possiblePaths) do
                externalDeviceId = _android_get_device_id_from_new_file(path)
                print(string.format("UUID-V3 , no device id in platform_get_storage_path, possible path:%s, external:%s", path, externalDeviceId))
                if externalDeviceId then
                    break
                end
            end
        end
        print(string.format("UUID-V3 , device id from uuid v2 file, internal:%s, external:%s", internalDeviceId, externalDeviceId))
        -- 
        if not internalDeviceId and not externalDeviceId then
            return
        elseif internalDeviceId == externalDeviceId then
            return internalDeviceId
        elseif internalDeviceId and not externalDeviceId then
            _android_save_device_id_to_new_file(externalStoragePath, internalDeviceId)
            return internalDeviceId
        elseif externalDeviceId and not internalDeviceId then
            _android_save_device_id_to_new_file(g_fileUtils:getWritablePath(), externalDeviceId)
            return externalDeviceId
        elseif externalDeviceId ~= internalDeviceId then
            _android_save_device_id_to_new_file(externalStoragePath, internalDeviceId)
            return internalDeviceId
        end
    end
end

-- 在v2包向uuid file手动存储device id(uuid格式)
function android_v2_write_v2_device_id_to_new_file()
    -- 只针对android
    if g_application:getTargetPlatform() ~= cc.PLATFORM_OS_ANDROID then
        return
    end
    if import('dialog.accounts.accounts_utils').get_sdk_name() ~= "badam" then
        return
    end
    -- 根据device id的格式判断是否是v2 , uuid 格式 e648e2fd-0af4-4341-bf35-7f07647051eb
    local deviceIdString = platform_get_device_id()
    local tile = string.rep("%x", 4)
    local expression = string.format("%s%s%s", string.rep(tile, 2), string.rep("%-" .. tile, 4), string.rep(tile, 2))
    local isMatch = string.match(deviceIdString, expression)
    -- getDeviceUuid接口不存在并device id返回uuid格式说明这是一个v2 uuid包
    if not platform_is_method_static_and_public("getDeviceUuid") and isMatch then
        print("UUID-V2 , starting to write device id to new file")
        -- v2 , device id接口返回的uuid存储到v2 uuid文件里（内部存储）
        _android_save_device_id_to_new_file(g_fileUtils:getWritablePath(), deviceIdString)
        -- v2 ，device id接口返回的uuid存储到v2 uuid文件里（外部存储，v3包里读取这个uuid当做device id来用）
        local externalStoragePath = platform_get_storage_path()
        if is_valid_str(externalStoragePath) then -- 可以获取sd卡路径, 并且与读写文件权限
            if _android_save_device_id_to_new_file(externalStoragePath .. '/', deviceIdString) then
                return
            end
        end
        print("UUID-V2 , platform_get_storage_path is not available, trying to possible paths")
        for _,path in ipairs(possiblePaths) do-- 获取不到sd卡路径的包试图搜索sdk卡路径
            print(string.format("UUID-V2 , platform_get_storage_path is not available, trying possible path:%s", path))
            if _android_save_device_id_to_new_file(path, deviceIdString) then
                print(string.format("UUID-V2 , platform_get_storage_path is not available, used possible path:%s", path))
                return
            end
        end

        __G__TRACKBACK__('UUID-V2 write failed')
    end
end

-- **************************************uuid v2包升级相关（结束）******************************************************