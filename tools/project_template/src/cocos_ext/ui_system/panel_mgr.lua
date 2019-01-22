--[[====================================
=
=         界面管理逻辑
=
========================================]]
-- 所有打开的面板的字典，通过面板名可找到实例
local _panelMap = {}
local _multiPanelMap = {}
local _sceneInfoStack = {}

local mBasePanel = import('cocos_ext.ui_system.base_panel')
local BasePanel = mBasePanel.BasePanel

local function _getSecneInfo(panel)
    local layer = panel:get_layer()
    if not layer:IsValid() then
        return
    end

    local curScene = layer:GetRootScene()
    if not curScene then
        return
    end

    for i = #_sceneInfoStack, 1, -1 do
        local sceneInfo = _sceneInfoStack[i]
        if sceneInfo.scene == curScene then
            return sceneInfo
        end
    end
end

local function _processPanelSceneInfo(panel, ...)
    local args = {...}
    local numParm = select('#', ...)
    local lastParam = args[numParm]
    if is_table(lastParam) and lastParam['__custom_info__'] then
        local sceneInfo = _getSecneInfo(panel)
        assert(sceneInfo.panels[panel] == true)
        sceneInfo.panels[panel] = lastParam
        numParm = numParm - 1
    end

    return unpack(args, 1, numParm)
end

local function _appendShowTopSceneParms(...)
    local args = {...}
    local n = select('#', ...) + 1
    args[n] = {
        __exists_in_top_scene__ = true,
        __custom_info__ = true,
    }
    return unpack(args, 1, n)
end

local function _create_panel(panelName, parent, bMultiple)
    if parent == nil then
        local curSceneInfo = _sceneInfoStack[#_sceneInfoStack]
        if curSceneInfo then
            parent = curSceneInfo.scene
        else
            -- 如果当前场景信息没有那么创建面板失败
            return
        end
    end

    local mName = 'logic.dialog.'..panelName
    if g_native_conf['debug_control'].bIsReloadPanel then
        import_reload(mName)
    end

    printf('======create panel:[%s]', panelName)
    local panel = direct_import(mName).Panel:New(parent, panelName, bMultiple)

    -- 将 panel 信息加入到 scene stack 中
    _getSecneInfo(panel).panels[panel] = true

    if bMultiple then
        local panelList = _multiPanelMap[panelName]
        if panelList == nil then
            panelList = {}
            _multiPanelMap[panelName] = panelList
        end
        table.insert(panelList, panel)
    else
        assert(_panelMap[panelName] == nil)
        _panelMap[panelName] = panel
    end

    g_logicEventHandler:Trigger('logic_dialog_opened', panelName)

    return panel
end

local function _create_existing_node_panel(panelName, node)
    local mName = 'logic.dialog.'..panelName
    if g_native_conf['debug_control'].bIsReloadPanel then
        import_reload(mName)
    end

    local panel = direct_import(mName).Panel:New(node:getParent(), panelName, false, node)

    -- 将 panel 信息加入到 scene stack 中
    _getSecneInfo(panel).panels[panel] = true

    assert(_panelMap[panelName] == nil)
    _panelMap[panelName] = panel

    g_logicEventHandler:Trigger('logic_dialog_opened', panelName)

    return panel
end



function new_panel_class(bindTemplateName, basePanel)
    if is_valid_str(basePanel) then
        basePanel = mBasePanel[basePanel]
    elseif basePanel == nil then
        basePanel = BasePanel
    end

    assert(issubclass(basePanel, BasePanel))

    local panelCls, Super = CreateClass(basePanel)
    if is_valid_str(bindTemplateName) then
        function panelCls:on_get_template_name()
            return bindTemplateName
        end
    end

    return panelCls, Super
end



-- get single panel instance
function get_panel(panelName)
    local panel = _panelMap[panelName]
    if panel then
        if panel:is_valid() then
            return panel
        else
            -- reset invalid panel
            _panelMap[panelName] = nil
        end
    end
end

-- get multi panel instance list
function get_multi_panel(panelName)
    local ret = {}

    local multiList = _multiPanelMap[panelName]
    if multiList then
        local bInvalid = false
        for _, p in ipairs(multiList) do
            if p:is_valid() then
                table.insert(ret, p)
            else
                bInvalid = true
            end
        end

        if bInvalid then
            -- reset invalid panel
            _multiPanelMap[panelName] = table.copy(ret)
        end
    end

    return ret
end

function show_with_parent(panelName, parent, ...)
    close_single_panel(panelName)
    local panel = _create_panel(panelName, parent, false)
    if panel then
        panel:init_panel(_processPanelSceneInfo(panel, ...))
        panel:on_init_end()
        return panel
    end
end

function show(panelName, ...)
    return show_with_parent(panelName, nil, ...)
end

function show_with_blur(panelName, parent, ...)
    close_single_panel(panelName)
    local panel = _create_panel(panelName, parent, false)
    if panel then
        panel:init_panel(_processPanelSceneInfo(panel, ...))
        panel._is_show_blur_bg = true
        panel:on_init_end()
        return panel
    end
end

function show_with_zorder_info(panelName, info, ...)
    panel = g_panel_mgr.show(panelName, ...)
    panel:change_panel_zorder(info[1],info[2])
end

function show_with_existing_node(panelName, baseNode, ...)
    close_single_panel(panelName)
    local panel = _create_existing_node_panel(panelName, baseNode)
    if panel then
        panel:init_panel(_processPanelSceneInfo(panel, ...))
        panel:on_init_end()
        return panel
    end
end

function show_in_top_scene(panelName, ...)
   return show_with_parent(panelName, nil, _appendShowTopSceneParms(...))
end

function show_in_new_scene(...)
    local ret
    local function createCallback(panel)
        ret = panel
    end

    local args = {...}
    local numParm = select('#', ...) + 1
    args[numParm] = createCallback

    show_in_new_scene_with_create_callback(unpack(args, 1, numParm))

    return ret
end

function show_in_new_scene_with_create_callback(panelName, ...)
    -- create scene
    local scene = cc.Scene:create()
    if g_director:getRunningScene() then
        g_director:pushScene(scene)
    else
        g_director:runWithScene(scene)

        local args = {...}
        local numParm = select('#', ...)
        delay_call(0, function()
            assert(g_director:getRunningScene() ~= nil)
            show_in_new_scene_with_create_callback(panelName, unpack(args, 1, numParm))
        end)
        return
    end

    -- add scene info
    local curSceneInfo = {
        scene = scene,
        panels = {}
    }
    local preSceneinfo = _sceneInfoStack[#_sceneInfoStack]
    if preSceneinfo then
        for panel, custom_attr in pairs(preSceneinfo.panels) do
            local panelBaseNode = panel:get_layer()
            if is_table(custom_attr) and custom_attr['__exists_in_top_scene__'] and panelBaseNode:IsValid() then
                -- move top scene panel
                assert(preSceneinfo.scene == panelBaseNode:getParent())

                local zorder = panelBaseNode:getLocalZOrder()
                panelBaseNode:retain()
                panelBaseNode:removeFromParent(false)
                scene:addChild(panelBaseNode, zorder)
                panelBaseNode:release()

                preSceneinfo.panels[panel] = nil
                curSceneInfo.panels[panel] = custom_attr
            end
        end
    end
    table.insert(_sceneInfoStack, curSceneInfo)

    select(-1, ...)(show_with_parent(panelName, scene, ...))
end

function show_multiple_in_top_scene(panelName, ...)
    return show_multiple_with_parent(panelName, nil, _appendShowTopSceneParms(...))
end

-- 显示的面板可以共存
function show_multiple(panelName, ...)
    return show_multiple_with_parent(panelName, nil, ...)
end

function show_multiple_with_parent(panelName, parent, ...)
    local panel = _create_panel(panelName, parent, true)
    if panel then
        panel:init_panel(_processPanelSceneInfo(panel, ...))
        panel:on_init_end()
        return panel
    end
end


local function _do_close_panel(panel)
    if panel == nil then
        return
    end

    --  clear _sceneInfoStack
    local sceneInfo = _getSecneInfo(panel)
    if sceneInfo then
        sceneInfo.panels[panel] = nil
    end

    -- clear panel map
    if panel:is_multi_panel() then
        local l = _multiPanelMap[panel._panelName]
        if l then
            table.arr_remove_v(l, panel)
        end
    else
        _panelMap[panel._panelName] = nil
    end

    panel:_destroy()

    g_logicEventHandler:Trigger('logic_dialog_closed', panel:get_panel_name())
end

function close_single_panel(panelName)
    _do_close_panel(_panelMap[panelName])
end

function close_multi_panel(panelName)
    local panels = _multiPanelMap[panelName]
    if panels then
        for _, multiPanel in ipairs(panels) do
            _do_close_panel(multiPanel)
        end
    end
end

-- 关闭指定文件名的面板
function close(panel)
    if is_string(panel) then
        close_single_panel(panel)
        close_multi_panel(panel)
    else
        _do_close_panel(panel)
    end
end

-- destroy top scene
function close_cur_scene_and_panels()
    local curSceneInfo = _sceneInfoStack[#_sceneInfoStack]
    if curSceneInfo == nil then
        return
    end

    -- 这里可能会同一帧 执行多次场景操作导致 running scene 的值不正确 所以不能判断 running scene
    -- local curScene = g_director:getRunningScene()
    -- if curSceneInfo.scene ~= curScene then
    --     return
    -- end

    table.remove(_sceneInfoStack)

    local nextSceneInfo = _sceneInfoStack[#_sceneInfoStack]

    for panel, custom_attr in pairs(curSceneInfo.panels) do
        local panelBaseNode = panel:get_layer()
        if nextSceneInfo and is_table(custom_attr) and custom_attr['__exists_in_top_scene__'] and panelBaseNode:IsValid() then
            -- move top scene panel
            assert(curSceneInfo.scene == panelBaseNode:getParent())

            local zorder = panelBaseNode:getLocalZOrder()
            panelBaseNode:retain()
            panelBaseNode:removeFromParent(false)
            nextSceneInfo.scene:addChild(panelBaseNode, zorder)
            panelBaseNode:release()

            assert(nextSceneInfo.panels[panel] == nil)
            nextSceneInfo.panels[panel] = custom_attr
        else
            close(panel)
        end
    end

    g_director:popScene()
end

close_panel_and_related_scene = close_cur_scene_and_panels

function close_all_scenes_and_panels()
    for index = #_sceneInfoStack, 1, -1 do
        local sceneInfo = _sceneInfoStack[index]
        for panel, _ in pairs(sceneInfo.panels) do
            close(panel)
        end
        g_director:popScene()
    end
    _sceneInfoStack = {}
end

----------------------------------------------------------------- utilities
-- 如果panel存在时，执行指定方法
function run_on_panel(panelName, fn)
    if is_string(panelName) then
        panelName = {panelName}
    end

    for _, pname in ipairs(panelName) do
        local panel = get_panel(pname)
        if panel then
            fn(panel)
        else
            --multi面板
            local panelList = get_multi_panel(pname)
            if panelList then
                for i,panel in ipairs(panelList) do
                    fn(panel)
                end
            end
        end
    end
end
