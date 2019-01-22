--[[====================================
=
=              程序入口lua文件
=
========================================]]
print('enter main.lua')

-- 初始化的那些信息需要输出
print = release_print

rawset(_G, 'g_application', cc.Application:getInstance())
rawset(_G, 'g_director', cc.Director:getInstance())
rawset(_G, 'g_fileUtils', cc.FileUtils:getInstance())
rawset(_G, 'g_scheduler', g_director:getScheduler())
rawset(_G, 'g_eventDispatcher', g_director:getEventDispatcher())

-- 收集错误日志以及堆栈信息并发回给服务器
__G__TRACKBACK__ = function(...)
    local errorMsg = string.format(...)
    local msg = debug.traceback(errorMsg)
    print(msg)
    local bIsShowErrorPanel = g_native_conf and g_native_conf['debug_control'] and g_native_conf['debug_control'].bIsShowErrorPanel
    if bIsShowErrorPanel and logic_utils_show_error_panel then
        logic_utils_show_error_panel(msg)
    end

    if platform_utils_report_bug then
        platform_utils_report_bug(errorMsg, msg)
    end

    return msg
end

-- @desc:
--     include 机制 dofile制定文件 支持 .. 相对路径
local include_stack = {'src'}
local include_visit = {}

function include(path, bForceInclude)
    -- print('~~~include', path, bForceInclude)

    local bak = {}
    for _, v in ipairs(include_stack) do
        table.insert(bak, v)
    end

    for w in string.gmatch(path, "(.-)/") do
        if w == ".." then
            table.remove(include_stack)
        else
            table.insert(include_stack, w)
        end
    end

    local filename = string.match(path, ".+/(.-)$") or path
    local real_path = string.format('%s/%s', table.concat(include_stack, '/'), filename)

    if include_visit[real_path] and not bForceInclude then
        print(real_path, 'already included')
        include_stack = bak
        return
    else
        include_visit[real_path] = true
    end

    local func = luaext_loadfile(real_path, _G)
    if func then
        xpcall(func, __G__TRACKBACK__)
    else
        print(string.format('include [%s] failed', path))
        include_visit[real_path] = false
    end

    include_stack = bak
end

local function _include_base_utils()
    include('cocos/init.lua')
    include('base/__init__.lua')

    include('global_utils/cocos_ext_constant.lua')
    include('global_utils/utils.lua')
    include('global_utils/cocos_ext_utils.lua')
    include('global_utils/logic_utils.lua')

    include('logic/logic_global_utils/game_logic_utils.lua')
    include('logic/logic_global_utils/logic_logic_utils.lua')
end

local function _include_platform_utils()
    local curPlatform = g_application:getTargetPlatform()
    if curPlatform == cc.PLATFORM_OS_ANDROID then
        include('global_utils/android_utils.lua')
        include('logic/logic_global_utils/logic_android_utils.lua')
    elseif curPlatform == cc.PLATFORM_OS_IPHONE or curPlatform == cc.PLATFORM_OS_IPAD then
        include('global_utils/ios_utils.lua')
        include('logic/logic_global_utils/logic_ios_utils.lua')
    elseif curPlatform == cc.PLATFORM_OS_WINDOWS then
        include('global_utils/win_utils.lua')
        include('logic/logic_global_utils/logic_win_utils.lua')
    else
        error_msg('platform [%d] not supported', curPlatform)
    end

    include('global_utils/platform_utils.lua')
    include('logic/logic_global_utils/logic_platform_utils.lua')
end

local function _try_init_and_debug(otherInitCallback)
    g_fileUtils:setPopupNotify(false)

    -- 只有在Windows下定义的全局变量才会放到代理中, 强制约束不允许增加全局函数
    if g_application:getTargetPlatform() == 0 then
        -- Windows 命令行解析
        if win_startup_parms then
            win_startup_conf = {}
            local i = 2
            while i <= #win_startup_parms do
                local key = string.match(win_startup_parms[i], '^-([a-z_]+)$')
                i = i + 1
                if key then
                    local nextP = win_startup_parms[i]
                    if nextP and string.sub(nextP, 1, 1) == '-' then
                        win_startup_conf[key] = true
                    else
                        if nextP == nil then
                            win_startup_conf[key] = true
                        else
                            win_startup_conf[key] = nextP
                        end
                        i = i + 1
                    end
                end
            end
        end

        local _bNewGlobals
        local _globalsProxy = {}
        setmetatable(_G, {
            __newindex = function(t, k, v)
                if _bNewGlobals then
                    if type(v) ~= 'function' then
                        error(string.format('global name [%s] type is [%s], not function', k, type(v)))
                    end
                    if string.sub(k, 1, 1) == '_' then
                        print(string.format('global name [%s] invalid', k))
                    end
                    _globalsProxy[k] = v
                else
                    error(string.format('attempt to new index global varible G[%s] = [%s]', tostring(k), tostring(v)))
                end
            end,
            __index = function(t, k)
                -- print('__index _G:', k)
                return _globalsProxy[k]
            end
        })

        _bNewGlobals = true
        _include_base_utils()
        _bNewGlobals = false

        otherInitCallback()
        import('logic_init').init()
        
        _bNewGlobals = true
        _include_platform_utils()
        _bNewGlobals = false
    else
        -- 这里更新patch可能之前版本有metatable所以
        setmetatable(_G, nil)

        _include_base_utils()
        otherInitCallback()
        import('logic_init').init()

        -- 平台特性接口最后初始化 因为它依赖一些具体逻辑
        _include_platform_utils()
    end

    assert(#include_stack == 1 and include_stack[1] == 'src')

    -- android 切到后台台久则关闭掉进程
    if g_application:getTargetPlatform() == cc.PLATFORM_OS_ANDROID then
        local taskKey = nil
        g_logicEventHandler:AddCallback('logic_event_restart_app', function()
            if taskKey then
                platform_android_timer_clear_task(taskKey)
                taskKey = nil
            end
        end)

        g_eventHandler:AddCallback('event_applicationDidEnterBackground', function()
            taskKey = platform_android_timer_delay_call(1000 * 15 * 60, function()
                platform_android_exit_with_code()
            end)
        end)

        g_eventHandler:AddCallback('event_applicationWillEnterForeground', function()
            if taskKey then
                platform_android_timer_clear_task(taskKey)
                taskKey = nil
            end
        end)
    end

    if not g_log_mgr.process_global_print() then
        import('logic_init').start()
    end
end

local function _registerConfig()
    -- 调试模式 在调试模式下脚本配置是可变的
    -- windows for debug
    g_conf_mgr.register_native_conf('debug_mode', g_application:getTargetPlatform() == cc.PLATFORM_OS_WINDOWS)
    if g_native_conf.debug_mode then
        -- debug模式下 scripts conf 跟 native conf一致
        print('debug_mode ~~~~~~~~~~~~~~~~~~~~~~')
        g_conf_mgr.register_script_conf = g_conf_mgr.register_native_conf
        g_conf_mgr.get_script_conf = g_conf_mgr.get_native_conf
        g_conf_mgr.get_all_script_conf = g_conf_mgr.get_all_native_conf
    end

    -- for test
    -- 远程日志输出
    g_conf_mgr.register_native_conf('remote_http_log', {
        bEnable = false,
        link_url = 'ws://192.168.10.65:12345/game_console',
    })

    -- 当前使用的多国版本
    g_conf_mgr.register_native_conf('cur_multilang_index', 'cn')

    -- 音频配置文件
    g_conf_mgr.register_native_conf('game_audio_info', {
        isCanPlayMusic = true,
        isCanPlaySound = true,
    })
end

-- 全局环境下的逻辑初始化
local function _processSearchPaths()
    -- 重启情况的处理
    local newSearchPaths = {}
    for _, v in ipairs(g_fileUtils:getSearchPaths()) do
        if not string.find(v, 'res/') and not string.find(v, 'patch_bin_folder/') then
            table.insert(newSearchPaths, v)
        end
    end
    g_fileUtils:setSearchPaths(newSearchPaths)
    g_fileUtils:addSearchPath('res/', true)

    -- 增加多国语言版本文件的搜索路径
    g_fileUtils:addSearchPath(g_fileUtils:getWritablePath() .. 'patch_bin_folder/', true)
    local languageIndex = g_native_conf.cur_multilang_index
    if languageIndex ~= 'cn' then
        g_fileUtils:addSearchPath(string.format('res/res_%s/', languageIndex), true)
        g_fileUtils:addSearchPath(string.format('%spatch_bin_folder/res_%s/', g_fileUtils:getWritablePath(), languageIndex), true)
    end
end

local function _registerGlobalEvents()
    --color dialog 编辑回调
    g_eventHandler:RegisterEvent('global_on_choose_color')

    -- 程序进入后来和切回到前台的事件
    g_eventHandler:RegisterEvent('event_applicationDidEnterBackground')
    g_eventHandler:RegisterEvent('event_applicationWillEnterForeground')

    -- 增加一个平台通知lua的全局接口
    g_eventHandler:RegisterEvent('global_platform_call_lua_func')

    -- 全局打印事件
    g_eventHandler:RegisterEvent('global_print')
end

local function _registerLogicEvents()
    g_logicEventHandler:RegisterEvent('logic_dialog_closed')  --窗口关闭时候触发该事件
    g_logicEventHandler:RegisterEvent('logic_dialog_opened')  --窗口创建时候触发该事件
    g_logicEventHandler:RegisterEvent('logic_button_clicked')
    g_logicEventHandler:RegisterEvent('logic_servertime_update')
    g_logicEventHandler:RegisterEvent('logic_event_restart_app') -- 游戏准备重启发起的事件(用于清里自定义资源避免内存泄漏)
    g_logicEventHandler:RegisterEvent('logic_event_on_drop_file') --注册拖拽文件事件
end

local function _init_uisystem()
    import('cocos_ext.ui_system.__uicontrols')
    import('cocos_ext.ui_system.__init_animations')

    local constant = g_constant_conf['constant_uisystem']

    g_uisystem.set_template_path(constant.template_path)
    g_uisystem.set_ani_template_path(constant.ani_template_path)

    local fontTypes = {}
    for _, fontInfo in pairs(constant.RichLabelFontType) do
        cc.RichLabel:rich_label_set_default_font(fontInfo.tp, fontInfo.font)
        table.insert(fontTypes, fontInfo.tp)
    end

    if cc.RichLabel.set_font_type then
        cc.RichLabel:set_font_type(fontTypes)
    end

    cc.RichLabel:set_ascii_font_type(constant.default_font_ascii_type)

    cc.RichLabel:set_default_create_font_size(constant.rich_label_font_size)

    ccext_update_design_resolution(nil, nil, constant.design_resolution_size.width, constant.design_resolution_size.height)
end

local function _init()
    import_add_search_path('src/?.lua')
    import_add_search_path('src/logic/?.lua')

    rawset(_G, 'g_conf_mgr', import('cocos_ext.common.native_conf_manager'))
    rawset(_G, 'g_conf', g_conf_mgr.conf)
    rawset(_G, 'g_constant_conf', g_conf_mgr.constant_conf)
    rawset(_G, 'g_native_conf', g_conf_mgr.native_conf)
    rawset(_G, 'g_script_conf', g_conf_mgr.script_conf)
    _registerConfig()

    _processSearchPaths()

    rawset(_G, 'g_log_mgr', import('cocos_ext.common.log_mgr'))
    rawset(_G, 'g_event_mgr', import('cocos_ext.common.event_manager'))
    
    rawset(_G, 'g_eventHandler', g_event_mgr.new_event_handler())
    _registerGlobalEvents()

    rawset(_G, 'g_async_task_mgr', import('cocos_ext.common.async_task_manager'))

    rawset(_G, 'g_audio_mgr', import('cocos_ext.common.audio_utils'))
    rawset(_G, 'g_net_mgr', import('cocos_ext.net.net_manager'))

    g_net_mgr.add_net_search_path('cocos_ext/net')
    g_net_mgr.add_net_search_path('logic/net', true)

    rawset(_G, 'g_logicEventHandler', g_event_mgr.new_event_handler())
    _registerLogicEvents()


    rawset(_G, 'g_ui_event_mgr', import('cocos_ext.common.ui_event_manager'))
    rawset(_G, 'g_uisystem', import('cocos_ext.ui_system.uisystem'))
    rawset(_G, 'g_panel_mgr', import('cocos_ext.ui_system.panel_mgr'))

    _init_uisystem()
end

-- @desc:
--     程序入口
xpcall(function()
    print('===============================lua enter main')
    _try_init_and_debug(_init)
    print('===============================lua enter main end\n\n')
end, __G__TRACKBACK__)
