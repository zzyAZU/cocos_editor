
-- 注册逻辑的一些配置
local function _registerLogicConfig()
    -- 默认值全部都要是正式数据
    local debugControlTable = {
        bPrintNetLog = false,
        bIsReloadPanel = false,  -- 是否重新加载面板
        bIsReloadRes = false,  -- 是否重新加载资源配置文件
        bIsShowErrorPanel = false, -- 是否弹出保持
        test_net_work_type = '',  -- 可以直接设置当前 wifi 的类型
    }

    g_conf_mgr.register_native_conf('debug_control', debugControlTable)

    -- 缓存尚未上传到测试服的测试信息
    g_conf_mgr.register_native_conf('test_not_upload_log_type_list', {})
end

-- 注册全局逻辑事件
local function _registerLogicEvents()
end

-- 增加全局的逻辑变量
local function _addGlobal()
end

local function _processDebugEvent()
    -- KEY_F1 test
    g_ui_event_mgr.add_common_key_event('KEY_F1', function()
        local testFilePath = 'test.lua'
        if g_fileUtils:isFileExist('src/' .. testFilePath) then
            include(testFilePath, true)
        end
    end)

    -- KEY_F2 start new app
    local curDebugIndex = 0
    g_ui_event_mgr.add_common_key_event('KEY_F2', function()
        curDebugIndex = curDebugIndex + 1
        local id = 'F2START_'..curDebugIndex
        local cmd = string.format('start %s -workdir %s -id %s -app_name %s', win_get_exe_dir(), win_startup_conf['workdir'], id, id)
        print(cmd)
        os.execute(cmd)
    end)

    g_ui_event_mgr.add_common_key_event('KEY_F3', function()
        profile_all_existing_modules_and_classes()
    end)

    -- KEY_F6 重启
    g_ui_event_mgr.add_common_key_event('KEY_F6', function()
        utils_restart_game()
    end)
end

function start()
    g_director:setAnimationInterval(1.0 / 30.0)
    utils_enable_schedule_collect_garbage(true)

    -- add startup code here...
    
end

-- 开始游戏逻辑
function init()
    printf('curSearchPaths:%s', str(g_fileUtils:getSearchPaths()))
    printf('curWritablePath:%s', g_fileUtils:getWritablePath())

    _registerLogicConfig()
    _addGlobal()
    _registerLogicEvents()
    _processDebugEvent()

    import('rich_label_init')
end
