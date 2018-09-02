--[[
    ui 编辑器 主界面
]]
local constant_uieditor = g_constant_conf['constant_uieditor']


Panel = g_panel_mgr.new_panel_class('editor/anieditor/anieditor_main_panel')


local function _check_panel_exists_onclick(node, callback)
    assert(tolua_is_obj(node))
    assert(is_function(callback))

    node.OnClick = function()
        local curPanel = g_ani_multi_doc_manager.get_cur_open_panel()
        if curPanel then
            callback(curPanel)
        else
            message('当前没有打开任何配置文件，无法操作')
        end
    end
end

local function _curPanel(fun)
    local panel = g_ani_multi_doc_manager.get_cur_open_panel()
    if panel then
        fun(panel)
    else
        message('当前没有打开任何配置文件，无法操作')
    end
end

-- overwrite
function Panel:init_panel()
    self:_initUIEditorBase()

    self:add_logic_event_callback('anieditor_multi_doc_status_changed', bind(self._updatePanelStatus, self))
end

-- 更新当前显示页的状态信息
function Panel:_updatePanelStatus()
    local openPanelList = g_ani_multi_doc_manager.get_open_panel_list()
    local panelCount = #openPanelList
    local curPanelIndex, curPanel = g_ani_multi_doc_manager.get_cur_open_panel_index()

    --all panels visibility
    for _, panel in ipairs(openPanelList) do
        panel:ShowConfigView(panel == curPanel)
    end

    -- refresh tab buttons
    local tabBtns = {}
    local selIndex

    self.tabTitleHorzList:SetInitCount(panelCount, true)

    for i, panel in ipairs(openPanelList) do
        if panel == curPanel then 
            selIndex = i
        end

        local item = self.tabTitleHorzList:GetItem(i)
        table.insert(tabBtns, item)

        local name = panel:GetTemplateName()
        if name then
            name = name:match('.+/(.+)') or name
        else
            name = 'untitled'
        end
        item:SetTextAndAjustSize(name, 20, 15)
        item.btnClose:SetPosition('i10', 'i10')
        item:SetGroup(tabBtns)
        item:SetCheck(false, false)

        --换页
        item.OnChecked = function(is_check, index)
            g_ani_multi_doc_manager.show_panel_by_index(index)
        end

        --关闭
        item.btnClose.OnClick = function()
            g_ani_multi_doc_manager.close_file(panel)
        end
    end

    self.tabTitleHorzList:_refreshContainer()
    if selIndex then
        local selBtn = tabBtns[selIndex]
        selBtn:SetCheck(true, false)
        if not selBtn:IsVisible() then
            self.tabTitleHorzList:CenterWithNode(selBtn, 0.1)
        end
    end
end

-- 初始化UI编辑器主界面
function Panel:_initUIEditorBase()
    --功能:最近打开文件
    self.comboRecentOpenFile.OnBeforPopup = function()
        self.comboRecentOpenFile:SetItems({})
        for _, templateName in ipairs(g_ani_multi_doc_manager.get_recent_open_file_list()) do
            self.comboRecentOpenFile:AddMenuItem(templateName, function()
                g_ani_multi_doc_manager.open_file(templateName)
            end)
        end
    end

    _check_panel_exists_onclick(self.btnOpenFolder, function(curPanel) curPanel:OpenContainFolder() end)

    ----------------------------file
    --新建
    local function OnNewFile()
        g_ani_multi_doc_manager.new_file()
    end

    self:add_key_event_callback({'KEY_CTRL', 'KEY_N'}, OnNewFile)
    self.comboFile:AddMenuItem('新建(ctrl + n)', OnNewFile)
    self.btnNew.OnClick = OnNewFile

    --打开
    local function OnOpenFile()
        g_ani_multi_doc_manager.open_file()
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_O'}, OnOpenFile)
    self.comboFile:AddMenuItem('打开(ctrl + o)', OnOpenFile)
    self.btnOpen.OnClick = OnOpenFile

    --保存
    local function OnSaveFile()
        _curPanel(function(panel)
            g_ani_multi_doc_manager.save_file(panel, panel:GetTemplateName())
        end)
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_S'}, OnSaveFile)
    self.comboFile:AddMenuItem('保存(ctrl + s)', OnSaveFile)
    self.btnSave.OnClick = OnSaveFile

    --另存
    local function OnSaveAsFile()
        _curPanel(function(panel)
            g_ani_multi_doc_manager.save_file(panel)
        end)
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_SHIFT', 'KEY_S'}, OnSaveAsFile)
    self.comboFile:AddMenuItem('另存(shift + ctrl + s)', OnSaveAsFile)
    self.btnSaveAs.OnClick = OnSaveAsFile

    -- 刷新
    local function OnReloadFile()
        _curPanel(function(panel)
            panel:OPReloadFile()
        end)
    end
    self.btnReload.OnClick = OnReloadFile

    --关闭
    local function OnCloseCurFile()
        _curPanel(function()
            g_ani_multi_doc_manager.close_file()
        end)
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_W'}, OnCloseCurFile)
    self.comboFile:AddMenuItem('关闭(ctrl + w)', OnCloseCurFile)

    --undo
    local function OnUndo()
        _curPanel(function(curPanel)
            curPanel:OPEditUndo()
        end)
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_Z'}, OnUndo)
    self.comboEdit:AddMenuItem('撤销(ctrl + z)', OnUndo)
    self.btnUndo.OnClick = OnUndo

    --redo
    local function OnRedo()
        _curPanel(function(curPanel)
            curPanel:OPEditRedo()
        end)
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_Y'}, OnRedo)
    self.comboEdit:AddMenuItem('还原(ctrl + y)', OnRedo)
    self.btnRedo.OnClick = OnRedo

    --copy
    local function OnCopy()
        _curPanel(function(panel)
            panel:CopySelItem()
        end)
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_C'}, OnCopy)
    self.comboEdit:AddMenuItem('拷贝(ctrl + c)', OnCopy)
    
    --cut
    local function OnCut()
        _curPanel(function(panel)
            panel:CutSelItem()
        end)
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_X'}, OnCut)
    self.comboEdit:AddMenuItem('剪切(ctrl + x)', OnCut)

    --paste
    local function OnPaste()
        _curPanel(function(panel)
            panel:PasteAsChildItem()
        end)
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_V'}, OnPaste)
    self.comboEdit:AddMenuItem('粘贴(ctrl + v)', OnPaste)

    --paste as front
    local function OnPasteAsFront()
        _curPanel(function(panel)
            panel:PasteAsFrontItem()
        end)
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_F'}, OnPasteAsFront)
    self.comboEdit:AddMenuItem('粘贴到前面(ctrl + f)', OnPasteAsFront)

    --paste as back
    local function OnPasteAsBack()
        _curPanel(function(panel)
            panel:PasteAsBackItem()
        end)
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_B'}, OnPasteAsBack)
    self.comboEdit:AddMenuItem('粘贴到后面(ctrl + b)', OnPasteAsBack)
    
    --Delete
    local function OnDelete()
        _curPanel(function(panel)
            panel:DeleteSelItem()
        end)
    end
    self:add_key_event_callback({'KEY_DELETE'}, OnDelete)
    self.comboEdit:AddMenuItem('删除(Delete)', OnDelete)

    -- ctrl + tab 切换页面
    self:add_key_event_callback({'KEY_CTRL', 'KEY_TAB'}, function()
        _curPanel(function()
            g_ani_multi_doc_manager.switch_panel()
        end)
    end)

    -- 移动当前页面
    self.btnDocShiftLeft.OnClick = function()
        _curPanel(function(panel)
            g_ani_multi_doc_manager.move_panel(panel, -1)
        end)
    end

    self.btnDocShiftRight.OnClick = function()
        _curPanel(function(panel)
            g_ani_multi_doc_manager.move_panel(panel, 1)
        end)
    end

    -- 节点折叠
    for i = 0, 9 do
        self:add_key_event_callback({'KEY_CTRL', 'KEY_K', string.format('KEY_%d', i)}, function()
            _curPanel(function(panel)
                panel:OPWrapNode(i)
            end)
        end)
    end

    self.comboOther:AddMenuItem('设置', function()
        g_panel_mgr.show('editor.dlg_setting_panel')
    end)

    self.comboAddActions.OnMouseMoveInside = function(text, itemName)
        self:_showActionDemon(text, itemName)
    end

    -- create ani types
    for _, groupInfo in ipairs(constant_uieditor.ani_edit_types) do
        local popUpItem = self.comboAddActions:AddPopupMenuItem(groupInfo.name)
        for _, typeInfo in ipairs(groupInfo.list) do
            self.comboAddActions:AddMenuItem(typeInfo[2] or typeInfo[1], nil, popUpItem, function()
                _curPanel(function(panel)
                    local defConf = constant_uieditor.ani_edit_info[typeInfo[1]].def
                    panel:OPAddAniConfig(typeInfo[1], defConf or {})
                    g_panel_mgr.close('uieditor.dlg_action_demon_panel')
                end)
            end)
        end
    end

    -- create spec ani types
    local popUpItem = self.comboAddActions:AddPopupMenuItem(constant_uieditor.spect_ani_edit_types.name)
    for _, groupInfo in ipairs(constant_uieditor.spect_ani_edit_types.list) do
        local popUpItemNodeType = self.comboAddActions:AddPopupMenuItem(groupInfo.name, popUpItem)
        for _, typeInfo in ipairs(groupInfo.list) do
            self.comboAddActions:AddMenuItem(typeInfo[2] or typeInfo[1], nil, popUpItemNodeType, function()
                _curPanel(function(panel)
                    local defConf = constant_uieditor.ani_edit_info[typeInfo[1]].def
                    panel:OPAddAniConfig(typeInfo[1], defConf or {})
                    g_panel_mgr.close('uieditor.dlg_action_demon_panel')
                end)
            end)
        end
    end
end

-- 新创建一个 uieditor config view
function Panel:NewAniEditorPanel(templateName)
    return g_panel_mgr.show_multiple_with_parent('dlg_anieditor_config_view_panel', self.multiDocNode, templateName)
end

function Panel:_showActionDemon(text, itemName)
    for i,key in ipairs(constant_uieditor.show_demon_anctions) do
        if key == text then
            if(not g_panel_mgr.get_panel('uieditor.dlg_action_demon_panel')) then --未打开
                g_panel_mgr.show_in_top_scene('uieditor.dlg_action_demon_panel',text)
            else 
                g_panel_mgr.run_on_panel('uieditor.dlg_action_demon_panel', function(panel)
                    panel:updateAction(text)
                end)
            end
            return
        end
    end
end