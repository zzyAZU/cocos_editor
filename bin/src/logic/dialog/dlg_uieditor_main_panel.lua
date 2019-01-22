--[[
    ui 编辑器 主界面
]]
local constant_uieditor = g_constant_conf['constant_uieditor']


Panel = g_panel_mgr.new_panel_class('editor/uieditor/uieditor_main_panel')


local function _check_panel_exists_onclick(node, callback)
    assert(tolua_is_obj(node))
    assert(is_function(callback))

    node.OnClick = function()
        local curPanel = g_multi_doc_manager.get_cur_open_panel()
        if curPanel then
            callback(curPanel)
        else
            message('当前没有打开任何配置文件，无法操作')
        end
    end
end

local function _curPanel(fun)
    local panel = g_multi_doc_manager.get_cur_open_panel()
    if panel then
        fun(panel)
    else
        message('当前没有打开任何配置文件，无法操作')
    end
end

-- overwrite
function Panel:init_panel()
    self:_initUIEditorBase()

    self:add_logic_event_callback('uieditor_multi_doc_status_changed', bind(self._updatePanelStatus, self))
end


-- 更新当前显示页的状态信息
function Panel:_updatePanelStatus()
    local openPanelList = g_multi_doc_manager.get_open_panel_list()
    local panelCount = #openPanelList
    local curPanelIndex, curPanel = g_multi_doc_manager.get_cur_open_panel_index()

    -- all panels visibility
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
            g_multi_doc_manager.show_panel_by_index(index)
        end

        --关闭
        item.btnClose.OnClick = function()
            g_multi_doc_manager.close_file(panel)
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
        for _, templateName in ipairs(g_multi_doc_manager.get_recent_open_file_list()) do
            self.comboRecentOpenFile:AddMenuItem(templateName, function()
                g_multi_doc_manager.open_file(templateName)
            end)
        end
    end

    -- 拖拽打开文件
    self._layer:HandleMouseEvent()
    self._layer.OnDropFile = function(filePaths)
        local project_res_path = g_logic_editor:get_project_ui_template_path()
        local pattern = string.format('^%s(.+)%%.json$', project_res_path)

        for _, filePath in ipairs(filePaths) do
            local templateName = string.match(filePath, pattern)
            if templateName then
                g_multi_doc_manager.open_file(templateName)
            end
        end
    end

    -- 对齐
    local ALIGN_TYPE = constant_uieditor.ALIGN_TYPE
    _check_panel_exists_onclick(self.btnAlignTop, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.TOP) end)
    _check_panel_exists_onclick(self.btnVertCenter, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.VCENTER) end)
    _check_panel_exists_onclick(self.btnAlignBottom, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.BOTTOM) end)
    _check_panel_exists_onclick(self.btnAlignLeft, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.LEFT) end)
    _check_panel_exists_onclick(self.btnHorzCenter, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.HCENTER) end)
    _check_panel_exists_onclick(self.btnAlignRight, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.RIGHT) end)
    _check_panel_exists_onclick(self.btnHorzEqDis, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.H_EQUIDISTANCE) end)
    _check_panel_exists_onclick(self.btnVertEqDis, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.V_EQUIDISTANCE) end)
    _check_panel_exists_onclick(self.btnHorAddSpace, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.H_ADD_SPACE) end)
    _check_panel_exists_onclick(self.btnHorSubSpace, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.H_SUB_SPACE) end)
    _check_panel_exists_onclick(self.btnVerAddSpace, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.V_ADD_SPACE) end)
    _check_panel_exists_onclick(self.btnVerSubSpace, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.V_SUB_SPACE) end)
    _check_panel_exists_onclick(self.btnSameWidth, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.SAME_WIDTH) end)
    _check_panel_exists_onclick(self.btnSameHeight, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.SAME_HEIGHT) end)
    _check_panel_exists_onclick(self.btnSameSize, function(curPanel) curPanel:AlignSelect(ALIGN_TYPE.SAME_SIZE) end)

    -- 打开模板文件
    _check_panel_exists_onclick(self.btnOpenFolder, function(curPanel) curPanel:OpenContainFolder() end)
    -- _check_panel_exists_onclick(self.btnAddToTemplate, function(curPanel) curPanel:AddToTemplateList() end)

    -- 预览
    _check_panel_exists_onclick(self.btnPreview, function(panel) panel:OPPreviewPanel() end)

    -- 显示全屏边框
    _check_panel_exists_onclick(self.btnShowBorder, function(panel) panel:OPShowBoarder() end)

    -- 视图居中
    _check_panel_exists_onclick(self.btnCenterview, function(panel) panel:OPShowCenterView() end)

    -- 生成代码
    _check_panel_exists_onclick(self.btnGenCode, function(panel) panel:OPGenDlgCode() end)


    --新建
    local function OnNewFile()
        g_multi_doc_manager.new_file()
    end

    self:add_key_event_callback({'KEY_CTRL', 'KEY_N'}, OnNewFile)
    self.comboFile:AddMenuItem('新建(ctrl + n)', OnNewFile)
    self.btnNew.OnClick = OnNewFile

    --打开
    local function OnOpenFile()
        g_multi_doc_manager.open_file()
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_O'}, OnOpenFile)
    self.comboFile:AddMenuItem('打开(ctrl + o)', OnOpenFile)
    self.btnOpen.OnClick = OnOpenFile

    --保存
    local function OnSaveFile()
        _curPanel(function(panel)
            g_multi_doc_manager.save_file(panel, panel:GetTemplateName())
        end)
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_S'}, OnSaveFile)
    self.comboFile:AddMenuItem('保存(ctrl + s)', OnSaveFile)
    self.btnSave.OnClick = OnSaveFile

    --另存
    local function OnSaveAsFile()
        _curPanel(function(panel)
            g_multi_doc_manager.save_file(panel)
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
            g_multi_doc_manager.close_file()
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


    local parms = {0, '0%', 'i0'}
    for _, key in ipairs({'KEY_P', 'KEY_S'}) do
        for i, v in ipairs(parms) do
            self:add_key_event_callback({key, string.format('KEY_%d', i)}, function()
                _curPanel(function(panel)
                    if key == 'KEY_P' then
                        panel:OPChangeNodePosFormat(v, v)
                    else
                        panel:OPChangeNodeSizeFormat(v, v)
                    end
                end)
            end)

            for _, subKey in ipairs({'KEY_Q', 'KEY_W'}) do
                for i, v in ipairs(parms) do
                    self:add_key_event_callback({key, subKey, string.format('KEY_%d', i)}, function()
                        _curPanel(function(panel)
                            if key == 'KEY_P' then
                                if subKey == 'KEY_Q' then
                                    panel:OPChangeNodePosFormat(v, nil)
                                else
                                    panel:OPChangeNodePosFormat(nil, v)
                                end
                            else
                                if subKey == 'KEY_Q' then
                                    panel:OPChangeNodeSizeFormat(v, nil)
                                else
                                    panel:OPChangeNodeSizeFormat(nil, v)
                                end
                            end
                        end)
                    end)
                end
            end
        end
    end

    self.comboEdit:AddMenuItem('坐标位置转换为数值(PS+(QW)+123)', function()
        _curPanel(function(panel)
            panel:OPChangeNodePosFormat(0, 0)
            panel:OPChangeNodeSizeFormat(0, 0)
        end)
    end)

    -- KEY_ESCAPE
    local function OnEsc()
        _curPanel(function(panel)
            panel:SelectControlItem(nil)
        end)
    end
    self:add_key_event_callback('KEY_ESCAPE', OnEsc)
    self.comboEdit:AddMenuItem('取消选中(Esc)', OnDelete)

    -- ctrl + a 全选节点
    local function OnSelectAll()
        _curPanel(function(panel)
            panel:OPSelectAllItems()
        end)
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_A'}, OnSelectAll)
    self.comboEdit:AddMenuItem('全选(ctrl + a)', OnSelectAll)

    local pos_quick_setting = constant_uieditor.pos_quick_setting
    local popUpItem = self.comboEdit:AddPopupMenuItem(pos_quick_setting.text_name)
    for _, pos_type_config in ipairs(pos_quick_setting.list) do
        self.comboEdit:AddMenuItem(pos_type_config.text_name, nil, popUpItem, function()
            _curPanel(function(panel)
                if pos_type_config.att_type == 1 then
                    panel:OPChangeNodePosFormat(parms[pos_type_config.op_type], nil)
                elseif pos_type_config.att_type == 2 then
                    panel:OPChangeNodePosFormat(nil, parms[pos_type_config.op_type])
                end
            end)
            
        end)
    end

    local size_quick_setting = constant_uieditor.size_quick_setting
    popUpItem = self.comboEdit:AddPopupMenuItem(size_quick_setting.text_name)
    for _, sizes_type_config in ipairs(size_quick_setting.list) do
        self.comboEdit:AddMenuItem(sizes_type_config.text_name, nil, popUpItem, function()
            _curPanel(function(panel)
                _curPanel(function(panel)
                    if sizes_type_config.att_type == 1 then
                        panel:OPChangeNodeSizeFormat(parms[sizes_type_config.op_type], nil)
                    elseif sizes_type_config.att_type == 2 then
                        panel:OPChangeNodeSizeFormat(nil, parms[sizes_type_config.op_type])
                    end
                end)
                
            end)
        end)
    end

    -- move
    local function _getLen()
        if g_ui_event_mgr.is_ctrl_down() then
            return constant_uieditor.arrow_ctrl_move_len
        elseif g_ui_event_mgr.is_alt_down() then
            return constant_uieditor.arrow_alt_move_len
        elseif g_ui_event_mgr.is_shift_down() then
            return constant_uieditor.arrow_shift_move_len
        else
            return constant_uieditor.arrow_move_len
        end
    end

    self:add_control_key_event_callback({'KEY_LEFT_ARROW'}, function()
        _curPanel(function(panel)
            panel:MoveSelectedCtrl(-_getLen(), 0)
        end)
    end)

    self:add_control_key_event_callback({'KEY_RIGHT_ARROW'}, function()
        _curPanel(function(panel)
            panel:MoveSelectedCtrl(_getLen(), 0)
        end)
    end)

    self:add_control_key_event_callback({'KEY_UP_ARROW'}, function()
        _curPanel(function(panel)
            panel:MoveSelectedCtrl(0, _getLen())
        end)
    end)

    self:add_control_key_event_callback({'KEY_DOWN_ARROW'}, function()
        _curPanel(function(panel)
            panel:MoveSelectedCtrl(0, -_getLen())
        end)
    end)

    -- ctrl + tab 切换页面
    self:add_key_event_callback({'KEY_CTRL', 'KEY_TAB'}, function()
        _curPanel(function()
            g_multi_doc_manager.switch_panel()
        end)
    end)

    -- 移动当前页面
    self.btnDocShiftLeft.OnClick = function()
        _curPanel(function(panel)
            g_multi_doc_manager.move_panel(panel, -1)
        end)
    end

    self.btnDocShiftRight.OnClick = function()
        _curPanel(function(panel)
            g_multi_doc_manager.move_panel(panel, 1)
        end)
    end

    self:add_key_event_callback({'KEY_CTRL', 'KEY_0'}, function()
        _curPanel(function(panel)
            panel:OPSetPanelScale(1)
        end)
    end)

    self:add_key_event_callback({'KEY_CTRL', 'KEY_MINUS'}, true, function()
        _curPanel(function(panel)
            panel:OPSetPanelScale(panel.layerDevice:getScale() - 0.025)
        end)
    end)

    self:add_key_event_callback({'KEY_CTRL', 'KEY_EQUAL'}, true, function()
        _curPanel(function(panel)
            panel:OPSetPanelScale(panel.layerDevice:getScale() + 0.025)
        end)
    end)

    self.comboOther:AddMenuItem('预览', function()
        _curPanel(function(panel)
            panel:OPPreviewPanel()
        end)
    end)

    self.comboOther:AddMenuItem('视图边框', function()
        _curPanel(function(panel)
            panel:OPShowBoarder()
        end)
    end)

    self.comboOther:AddMenuItem('视图居中', function()
        _curPanel(function(panel)
            panel:OPShowCenterView()
        end)
    end)

    self.comboOther:AddMenuItem('生成代码', function()
        _curPanel(function(panel)
            panel:OPGenDlgCode()
        end)
    end)

    -- dialog list
    local dialogListPanel = g_panel_mgr.show_with_parent('dlg_uieditor_main_dialog_list_panel', self._layer)
    local function _switchFileDialog()
        local bOpen = not dialogListPanel._layer:isVisible()
        dialogListPanel._layer:setVisible(bOpen)
    end
    self.comboOther:AddMenuItem('游戏面板视图(Tab)', _switchFileDialog)
    self:add_key_event_callback({'KEY_TAB'}, _switchFileDialog)


    self.comboHelp:AddMenuItem('编辑器使用操作文档', function()
        g_application:openURL(g_script_conf['editor_help_info']['op_doc_url'])
    end)

    self.comboHelp:AddMenuItem('安装环境', function()
        g_application:openURL(g_script_conf['editor_help_info']['evn_doc_url'])
    end)

    -- 创建控件列表初始化
    for _, groupInfo in ipairs(constant_uieditor.controls) do
        local popUpItem = self.comboAddControl:AddPopupMenuItem(groupInfo.text_name)
        for _, class in ipairs(groupInfo.list) do
            self.comboAddControl:AddMenuItem(class.text_name, nil, popUpItem, function()
                _curPanel(function(panel)
                    panel:AddUIControlItem(class.name, class.defConf or {})
                end)
            end)
        end
    end
end

-- 新创建一个 uieditor config view
function Panel:NewUIEditorPanel(templateName)
    return g_panel_mgr.show_multiple_with_parent('dlg_uieditor_config_view_panel', self.multiDocNode, templateName)
end
