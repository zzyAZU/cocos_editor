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
    if not is_table(info) then
        info = {content = info}
    end
    assert(is_table(info))

    info['wifi_state'] = platform_get_network_type()
    info['uuid'] = g_user_info.get_user_info() and g_user_info.get_user_info().uid or 0
    info['version'] = string.format('%d.%d', utils_game_get_engine_sub_version(), utils_get_sdk_version())
    info['channel'] = platform_get_app_channel_name()
    info['sdk_name'] = g_native_conf['sdk_name']
    info['cur_patch_version'] = g_native_conf['cur_patch_version']
    info['platform'] = g_application:getTargetPlatform()

    local uploadContent = luaext_json_encode(info) .. '\n'
    local url = g_constant_conf['constant'].GAME_UPLOAD_HTTP_ERR_URL .. '?dir=' .. type
    local handler = http_post(url, uploadContent, false, true)
    
    -- test
    -- handler.on_success = function()
    --     message("upload success")
    -- end

    handler.on_fail = function()
        -- 追加到文件尾端
        local f = io.open(_getWriteLogPath(type), 'a')
        if f then
            f:write(uploadContent)
            f:close()
            g_conf_mgr.set_native_conf_k_v('test_not_upload_log_type_list', type, true)
        end

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

function coroutine_call_fun(fun,time)
    local co = coroutine.running()
    delay_call(time or 0, function()
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
local _costTimes = {}
function profile(fun, name)
    if _costTime[name] == nil then
        _costTime[name] = 0
        _costTimes[name] = 0
    end

    local cur = utils_get_tick()
    fun()
    local cost = utils_get_tick() - cur
    local total = _costTime[name] + cost
    local totalTimes = _costTimes[name] + 1
    _costTime[name] = total
    _costTimes[name] = totalTimes
    printf('[%s] cost time:%f  per cost time %f total cost time %f', name, cost,total/totalTimes, total)
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

function logic_utils_can_use_spine()
    local sub_engine_version = utils_game_get_engine_sub_version()
    if sp ~= nil and sub_engine_version ~= 0 and sub_engine_version ~= 100000 then
        return true
    else
        return false
    end
end

function utils_coroutinue_download_split_res(res_names, upate_callback)
    local downloader = import('logic.logic_data.split_res_downloader')
    local co = coroutine.running()
    delay_call(0, function()
        downloader.download_split_res(res_names, function(status, cur_size, total_size, res_name)
            if upate_callback then
                upate_callback(status, cur_size, total_size, res_name)
            end
            if status == downloader.DOWNLOAD_SPLIT_RES_CALLBACK_STATUS.RES_STATUS_ERROR then  --下载出错
                coroutine.resume(co, false)
            elseif status == downloader.DOWNLOAD_SPLIT_RES_CALLBACK_STATUS.RES_STATUS_GROUP_SUCCESSED then  --下载成功了
                if total_size == 0 then  --版本为最新
                    coroutine.resume(co, true, false)
                else
                    coroutine.resume(co, true, true)
                end
            elseif status == downloader.DOWNLOAD_SPLIT_RES_CALLBACK_STATUS.RES_STATUS_GROUP_CANCEL then  --下载取消了
                coroutine.resume(co, true, false)
            end
        end)
    end)
    return coroutine.yield()
end

function show_common_download_panel(gameType, callback)
    local debug_control = g_native_conf['debug_control']
    if debug_control.bSkipUpdate or debug_control.bSkipCheckSplitPackage then
        if callback then
            callback(true)
        end
        return
    end
    local split_res_names = import('logic.logic_data.split_res_manager').get_game_split_res(gameType)
    show_common_download_panel_with_split_res_names(split_res_names, callback)
end

function show_common_download_panel_with_split_res_names(split_res_names, callback)
    g_panel_mgr.show("common.dlg_common_download_panel", split_res_names, function()
        if callback then
            callback(true)
        end
    end)
end

function utils_get_hall_lang_split_res_name(lang)
    if not lang then
        local curLang = g_native_conf['cur_multilang_index']
        lang = curLang
    end
    if lang == 'cn' then
        return g_constant_conf['constant'].CHIINESE_SPLIT_RES_NAME
    end
    return 'hall_'..lang
end

--尝试初始化大厅的分包信息(主要是给以前的包一个初始的分包版本10000)
function utils_init_hall_lang_split_res_info(lang)
    if not lang then
        local curLang = g_native_conf['cur_multilang_index']
        lang = curLang
    end
    local split_res_name = utils_get_hall_lang_split_res_name(lang)
    if lang ~= 'cn' then
        local constant = g_constant_conf['constant']
        local sdk_version = utils_get_sdk_version()
        local game_split_res_version_info = g_native_conf['game_split_res_version_info']
        if sdk_version < constant.GAME_SUPPORT_HALL_SPLIT_RES_MIN_SDK_VERSION then  --114 以前的版本是 各种语言的分包都放再一起。为了避免这些包去下载第一个分包，给个初始的版本号
            if not game_split_res_version_info[split_res_name] then
                game_split_res_version_info[split_res_name] = constant.GAME_SPLIT_RES_MIN_VERSION
            end
        end
    end
end
