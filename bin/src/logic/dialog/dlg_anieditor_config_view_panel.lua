--[[
    UI编辑器配置对应的显示视图
]]
local constant_uieditor = g_constant_conf['constant_uieditor']
local constant_uisystem = g_constant_conf['constant_uisystem']

-- 貌似复制太快马上再获取剪切板的内容会获得空
Panel = g_panel_mgr.new_panel_class('editor/anieditor/anieditor_config_view')

function Panel:_initMainPanel()
    -- drag & drop list object
    self.listObjects:EnableDragAndDrop(function(item)
        if self.listObjects:IsItemSelected(item) then
            local spt = g_uisystem.load_template_create('editor/anieditor/items/ani_tree_view_item')
            spt.text:SetString(item.text:GetString())
            return spt
        end
    end)

    self.listObjects.OnDragAndDrop = function(pt, srcItem, destItem)
        if destItem then
            self:OPMoveItem(destItem)
        end
    end
end

-- override
function Panel:init_panel(templateName)
    self._templateName = nil  -- 模板名称(未保存模板名为空)

    -- 编辑操作
    self._editData = {}
    self._editCurIndex = 0
    self._editCurSaveIndex = 0
    self._editOPCount = 0

    -- init
    self:_initMainPanel()

    -- 加载配置
    if templateName then
        if self:_addConf(templateName) then
            --cur panel template name
            self.editPanelName:SetText(templateName)

            self._templateName = templateName
            self:EditPush()
            self:EditOnSave()
        end
    end
end

-- 当前面板的模板名称
function Panel:GetTemplateName()
    return self._templateName
end

-- 面板的内容可否保存
function Panel:CanSave()
    return not self.listObjects:IsEmpty()
end

-- 判断当前面板的状态是否需要保存
function Panel:NeedSave()
    return self:CanSave() and (self:GetTemplateName() == nil or self:IsEditChanged())
end

-- 保存 panel 对应的配置
function Panel:SaveConfig(templateName)
    if templateName ~= nil then
        self._templateName = templateName
    end

    g_ani_multi_doc_manager.save_template_conf(self)

    self:EditOnSave()

    self.editPanelName:SetText(self:GetTemplateName() or '')
end

-- 判断当前 文档是否有修改过
function Panel:IsEditChanged()
    return self._editCurIndex ~= self._editCurSaveIndex
end

function Panel:EditOnSave()
    while #self._editData > self._editCurIndex do
        table.remove(self._editData)
    end
    self._editCurSaveIndex = self._editCurIndex
end

function Panel:EditOperateBegin()
    self._editOPCount = self._editOPCount + 1
end

function Panel:EditOperateEnd()
    assert(self._editOPCount > 0)
    self._editOPCount = self._editOPCount - 1
end

function Panel:EditOperatePush()
    self:EditOperateEnd()
    self:EditPush()
end

function Panel:EditPush()
    if self._editOPCount > 0 then
        return
    end

    while #self._editData > self._editCurIndex do
        table.remove(self._editData)
    end

    if self._editCurSaveIndex > self._editCurIndex then
        self._editCurSaveIndex = 0
    end

    --1： cfg 、 2:sel index list
    table.insert(self._editData, {self:GetAniConfig(), self.listObjects:GetSelectedIndexList()})
    self._editCurIndex = self._editCurIndex + 1

    print('edit push ##################')
end

-- 刷新当前编辑数据的选中数据
function Panel:_editRefreshCurselData()
    if self._editCurIndex > 0 then
        self._editData[self._editCurIndex][2] = self.listObjects:GetSelectedIndexList()
    end
end

function Panel:_editUpdateData()
    if self._editCurIndex > 0 then
        local data = self._editData[self._editCurIndex]
        self:_clearRootItem()
        assert(self:_addConf(data[1]))
        self.listObjects:SetSelectedItems(table.from_arr_trans_fun(data[2], function(_, indexList)
            return self.listObjects:GetItemByIndexList(indexList)
        end))
    end
end

-- 控制当前文档的可见性
function Panel:ShowConfigView(bShow)
    self:get_layer():setVisible(bShow)
end

-- 获取该配置文件的保存路径
function Panel:GetSaveFilePath()
    if self._templateName then
        local filePath = g_logic_editor.get_project_ani_template_path() .. self._templateName .. constant_uieditor.config_file_ext
        return filePath
    end
end

function Panel:_addAniConf(conf, parentItem, index, bNotUpdate)
    local type_name = conf['type_name']
    local bIsDecorateAction = g_uisystem.get_decorate_action_info()[type_name] ~= nil
    if parentItem and parentItem['_conf'] then
        local parentTypeName = parentItem['_conf']['type_name']
        local bIsParentDecorateAction = g_uisystem.get_decorate_action_info()[parentTypeName] ~= nil
        if bIsParentDecorateAction then
            message('修饰动作不允许被其他动作修饰')
            return
        elseif not bIsDecorateAction and not constant_uieditor.common_ani_has_children[parentTypeName] then
            message('动作[{1}]不允许有非修饰动作的子节点', parentTypeName)
            return
        end
    elseif bIsDecorateAction then
        message('修饰动作不能单独存在')
        return
    end


    local item = self.listObjects:AddTemplateItem(parentItem, index, bNotUpdate)
    conf = table.deepcopy(conf)
    item['_conf'] = conf
    self:RefreshItemName(item)
    
    item.btn.OnClick = function()
        if g_ui_event_mgr.is_ctrl_down() then
            local bSelect = self.listObjects:IsItemSelected(item)
            self.listObjects:MultiSelectItem(item, not bSelect)
        elseif g_ui_event_mgr.is_shift_down() then
            local selItem = self.listObjects:GetSelectedItem()
            if selItem and selItem ~= item then
                --shift多选
                local y1 = selItem:convertToWorldSpace(ccp(0, 0)).y
                local y2 = item:convertToWorldSpace(ccp(0, 0)).y
                local miny, maxy = math.min(y1, y2), math.max(y1, y2)
                local items = {}
                self.listObjects:ForEachItem(function(it)
                    if not self.listObjects:IsItemFolded(it) then
                        local y = it:convertToWorldSpace(ccp(0, 0)).y
                        if y >= miny and y <= maxy then
                            table.insert(items, it)
                        end
                    end
                end)
                self.listObjects:SetSelectedItems(items)
            end
        else
            self.listObjects:SelectItem(item, true)
        end

        self:_editRefreshCurselData()

        self:RefreshSelItemPropertyConf()
    end

    local child_list = conf['child_list']
    if is_table(child_list) then
        for _, v in ipairs(child_list) do
            self:_addAniConf(v, item, nil, bNotUpdate)
        end
        conf['child_list'] = nil
    end

    return item
end

function Panel:GenItemAniConf(item)
    local ret = table.deepcopy(item['_conf'])
    local child_list = self.listObjects:GetItemChildList(item)
    if child_list then
        ret['child_list'] = table.from_arr_trans_fun(child_list, function(_, v)
            return self:GenItemAniConf(v)
        end)
    end

    return ret
end

function Panel:GetAniConfig()
    return table.from_arr_trans_fun(self.listObjects:GetRootItemChildList(), function(_, v)
        return self:GenItemAniConf(v)
    end)
end

-- items op
function Panel:_addConf(conf)
    if is_string(conf) then
        conf = g_uisystem.load_ani_template(conf)
    end

    if conf == nil then
        return
    end

    return table.from_arr_trans_fun(conf, function(_, v)
        return self:_addAniConf(v)
    end)
end

function Panel:_clearRootItem()
    self.listObjects:DeleteAllSubItem()
end

local _curCopyAniConfs

function Panel:_copyControlItems(items)
    _curCopyAniConfs = table.from_arr_trans_fun(items, function(_, v)
        return self:GenItemAniConf(v)
    end)

    return _curCopyAniConfs
end

function Panel:_cutControlItems(items)
    local ret = self:_copyControlItems(items)
    for _, v in ipairs(items) do
        self.listObjects:DeleteItem(v)
    end

    return ret
end

function Panel:_pasteAsChildItem(destItem, index, conf)
    local selItems = table.from_arr_trans_fun(conf, function(i, config)
        return self:_addAniConf(config, destItem, index and index + i - 1)
    end)
    self.listObjects:SetSelectedItems(selItems)

    return selItems
end

function Panel:_pasteAsFrontItem(destItem, conf)
    local parentItem = self.listObjects:GetParentItem(destItem)
    local pos = table.find_v(self.listObjects:GetItemChildList(parentItem), destItem)
    return self:_pasteAsChildItem(parentItem, pos, conf)
end

function Panel:_pasteAsBackItem(destItem, conf)
    local parentItem = self.listObjects:GetParentItem(destItem)
    local pos = table.find_v(self.listObjects:GetItemChildList(parentItem), destItem) + 1
    return self:_pasteAsChildItem(parentItem, pos, conf)
end

function Panel:_doReload()
    self:_clearRootItem()
    g_uisystem.reload_ani_template(self._templateName)
    self:_addConf(self._templateName)
    self:RefreshSelItemPropertyConf()
end


--[[刷新一下选中按钮的属性列表]]
function Panel:RefreshSelItemPropertyConf(bScrollToTop)
    -- local offset = self.listProperty:getContentOffset()
    self.listProperty:DeleteAllSubItem()

    local item = self.listObjects:GetSelectedItem()
    if item == nil then
        return
    end

    local conf = item['_conf']
    local type_name = conf['type_name']
    local editInfo = constant_uieditor.ani_edit_info[type_name]

    local ani_type_name_info = {}
    for _, info in ipairs(constant_uieditor.ani_edit_types) do
        local bExists = table.find_if(info.list, function(_, v)
            return v[1] == type_name
        end)

        if bExists then
            for _, i in ipairs(info.list) do
                table.insert(ani_type_name_info, {i[1], i[1]})
            end
            break
        end
    end
    -- type_name
    local parm = {
        name = '类型',
        list = ani_type_name_info,
    }
    local ctrl = editor_utils_create_edit_ctrls('edit_type_combo', type_name, parm, nil, function(value)
        -- change type
        local def = constant_uieditor.ani_edit_info[value]['def'] or {}
        def = table.copy(def)
        for k, v in pairs(conf) do
            if def[k] ~= nil then
                def[k] = v
            end
        end
        table.clear(conf)
        conf['type_name'] = value
        table.merge(conf, def)

        self:RefreshItemName(item)
        self:EditPush()
        self:RefreshSelItemPropertyConf()
    end):GetCtrl()
    self.listProperty:AddControl(ctrl)

    for _, info in ipairs(editInfo.edit_attrs or {}) do
        local attr = info['attr']
        local ctrl = editor_utils_create_edit_ctrls(info['tp'], conf[attr], info['parm'], conf, function(value)
            conf[attr] = value
            self:EditPush()
            self:RefreshItemName(item)
        end):GetCtrl()

        self.listProperty:AddControl(ctrl)
    end

    self:_tryAddEditActionAttributeBtn(type_name, conf, item)
    -- self.listProperty:setContentOffset(offset)

    if bScrollToTop then
        self.listProperty:ScrollToTop()
    else
        self.listProperty:ResetContentOffset() 
    end
end

function Panel:_tryAddEditActionAttributeBtn(type_name, conf, item)

    local editActionInfo = constant_uieditor.need_custome_edit_actions[type_name]
    if not editActionInfo then
        return
    end

    local ctrl = editor_utils_create_edit_ctrls('edit_ctrl_callback_btn', type_name, { edit_name = editActionInfo.edit_name}, nil, function()
        g_panel_mgr.show_with_parent(editActionInfo.file, self:get_layer():getParent(), type_name, conf, function(custom_conf)
            for key, originValue in pairs(conf) do
                if custom_conf[key] then
                    conf[key] = custom_conf[key]
                end
            end
            self:EditPush()
            self:RefreshItemName(item)
            self:RefreshSelItemPropertyConf()
        end, function()
            g_ani_multi_doc_manager.save_file(self, self:GetTemplateName())
        end)
    end):GetCtrl()
    self.listProperty:AddControl(ctrl)

    
end

function Panel:RefreshItemName(item)
    if not item then
         item = self.listObjects:GetSelectedItem()
        if item == nil then
            return
        end
    end
   
    local conf = item['_conf']
    local type_name = conf['type_name']

    local textContent = type_name
    local node_name = conf['name']
    if node_name and node_name ~= '' then
        textContent = string.format('[#c00ff00%s#n]%s', node_name, type_name)
    end
    item.text:SetString(textContent)
end

local _delayShowTips
function Panel:ShowTips(...)
    local tips = string.format(...)
    assert(is_valid_str(tips))
    self.lTips:SetString(tips)

    if _delayShowTips then
        _delayShowTips('cancel')
    end

    _delayShowTips = self._layer:DelayCall(3, function()
        self.lTips:SetString('')
    end)
end


------------------------------------------ OP
function Panel:OPEditUndo()
    if self._editCurIndex > 1 then
        self._editCurIndex = self._editCurIndex - 1
        self:_editUpdateData()
        return true
    else
        return false
    end
end

function Panel:OPEditRedo()
    if self._editCurIndex < #self._editData then
        self._editCurIndex = self._editCurIndex + 1
        self:_editUpdateData()
        return true
    else
        return false
    end
end

function Panel:OPReloadFile()
    local savePath = self:GetSaveFilePath()
    if savePath == nil or not g_fileUtils:isFileExist(savePath) then
        message('当前文档未曾保存过,无法刷新成本地配置')
        return
    end

    if self:IsEditChanged() then
        win_confirm_yes_no(nil, "当前的工作未保存，是否重新加载？", function()
            self:_doReload()
            self:EditPush()
            self:EditOnSave()
        end)
    else
        self:_doReload()
        self:EditPush()
        self:EditOnSave()
    end
end


--[[在选中的控件的子列表中添加一个新的控件]]
function Panel:OPAddAniConfig(typeName, defCfg)
    local conf = table.merge({type_name = typeName}, defCfg)

    local item = self.listObjects:GetSelectedItem()
    local addItem

    if item == nil then
        addItem = self:_addAniConf(conf, item)
    else
        if g_ui_event_mgr.is_ctrl_down() then
            addItem = self:_pasteAsBackItem(item, {conf})[1]
        elseif g_ui_event_mgr.is_alt_down() then
            addItem = self:_pasteAsFrontItem(item, {conf})[1]
        else
            addItem = self:_addAniConf(conf, item)
        end
    end

    self.listObjects:SelectItem(addItem)
    self:RefreshSelItemPropertyConf()

    if addItem then
        self:EditPush()
    end
end

--复制当前选中的items
function Panel:CopySelItem()
    self:_copyControlItems(self.listObjects:GetNoSelParentSelItems())
end

--剪切当前选中的items
function Panel:CutSelItem()
    self:_cutControlItems(self.listObjects:GetNoSelParentSelItems())
    self:RefreshSelItemPropertyConf()
    self:EditPush()
end

function Panel:PasteAsBackItem()
    if _curCopyAniConfs == nil then
        return
    end

    local selItem = self.listObjects:GetSelectedItem()
    if selItem == nil then 
        return
    end

    if #self:_pasteAsBackItem(selItem, _curCopyAniConfs) > 0 then
        self:RefreshSelItemPropertyConf()
        self:EditPush()
    end
end

function Panel:PasteAsFrontItem()
    local selItem = self.listObjects:GetSelectedItem()
    if selItem == nil then
        return 
    end

    if #self:_pasteAsFrontItem(selItem, _curCopyAniConfs) > 0 then
        self:RefreshSelItemPropertyConf()
        self:EditPush()
    end
end

--拷贝为选中项的子项
function Panel:PasteAsChildItem()
    if #self:_pasteAsChildItem(self.listObjects:GetSelectedItem(), nil, _curCopyAniConfs) > 0 then
        self:RefreshSelItemPropertyConf()
        self:EditPush()
    end
end

--将选中的节点移到指定节点下
function Panel:OPMoveItem(destItem)
    local srcItems = self.listObjects:GetSelectedItems()
    -- 如果目标节点是拖动节点的子节点则忽略
    for _, srcItem in ipairs(srcItems) do
        if self.listObjects:IsAncestor(srcItem, destItem) then
            return
        end
    end

    --OP
    local copyConf = self:_copyControlItems(srcItems)
    local pasteItems
    if g_ui_event_mgr.is_ctrl_down() then
        pasteItems = self:_pasteAsBackItem(destItem, copyConf)
    elseif g_ui_event_mgr.is_alt_down() then
        pasteItems = self:_pasteAsFrontItem(destItem, copyConf)
    else
        pasteItems = self:_pasteAsChildItem(destItem, nil, copyConf)
    end

    if #pasteItems > 0 then
        for _, v in ipairs(srcItems) do
            self.listObjects:DeleteItem(v)
        end
        self:RefreshSelItemPropertyConf()
        self:EditPush()
    end
end

-- 删除选中的所有节点
function Panel:DeleteSelItem()
    if not self.listObjects:GetSelectedItem() then
        return
    end

    for _, v in ipairs(self.listObjects:GetNoSelParentSelItems()) do
        self.listObjects:DeleteItem(v)
    end
    self:RefreshSelItemPropertyConf()
    self:EditPush()
end

--打开配置文件所在文件夹
function Panel:OpenContainFolder()
    local path = self:GetSaveFilePath()
    if g_fileUtils:isFileExist(path) then
        os.execute('explorer /select, ' .. string.gsub(path, '/', '\\'))
    else
        message('文件夹不存在')
    end
end

function Panel:OPWrapNode(level)
    if level == 0 then
        self.listObjects:ForEachItem(function(v)
            self.listObjects:ExpandItem(v, true)
        end)
    else
        local wrapItems = self.listObjects:GetRootItemChildList()
        for i = 1, level do
            local childList = {}
            for _, v in ipairs(wrapItems) do
                self.listObjects:ExpandItem(v, i ~= level)
                table.arr_extend(childList, self.listObjects:GetItemChildList(v))
            end
            wrapItems = childList
        end
    end
end
