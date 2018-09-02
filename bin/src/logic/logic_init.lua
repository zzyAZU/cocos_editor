
-- 注册逻辑的一些配置
local function _registerLogicConfig()
    -- 默认值全部都要是正式数据
    local debugControlTable = {
        bPrintNetLog = false, 
        bIsReloadPanel = false,  -- 是否重新加载面板
        bIsReloadRes = false,  -- 是否重新加载资源配置文件
        bIsShowErrorPanel = false, -- 是否弹出保持
    }

    g_conf_mgr.register_native_conf('debug_control', debugControlTable)

    -- 缓存尚未上传到测试服的测试信息
    g_conf_mgr.register_native_conf('test_not_upload_log_type_list', {})
end

-- 注册全局逻辑事件
local function _registerLogicEvents()
end

-- 逻辑事件回调全局处理
local function _callbackLogicEvents()
end

-- 增加全局的逻辑变量
local function _addGlobal()
end

-- 在更换包之后需要清空patch
local function _processUpgradeEngineNo()
end

local function _processDebugEvent()
    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(function(keyCode, event)
        if cc.KeyCodeKey[keyCode + 1] == 'KEY_F1' then
            local testFilePath = 'test.lua'
            if g_fileUtils:isFileExist('src/' .. testFilePath) then
                include(testFilePath, true)
            end
        elseif cc.KeyCodeKey[keyCode + 1] == 'KEY_F6' then
            utils_restart_game()
        end
    end, cc.Handler.EVENT_KEYBOARD_PRESSED)
    g_eventDispatcher:addEventListenerWithFixedPriority(listener, 1)
end



local bStarted = false
function start()
    if not bStarted then
        g_director:setAnimationInterval(1.0 / 30.0)
        utils_enable_schedule_collect_garbage(true)

        rawset(_G, 'g_logic_editor', import('logic_editor'))
        g_logic_editor.init()

        bStarted = true
    end
end

-- 开始游戏逻辑
function init()
    printf('curSearchPaths:%s', str(g_fileUtils:getSearchPaths()))
    printf('curWritablePath:%s', g_fileUtils:getWritablePath())

    _registerLogicConfig()
    _processUpgradeEngineNo()
    _addGlobal()
    _registerLogicEvents()
    _callbackLogicEvents()
    _processDebugEvent()

    import('rich_label_init')
end
