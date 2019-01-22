-- dialog code generated at 2018-12-14 16:15

Panel = g_panel_mgr.new_panel_class('editor/uieditor/uieditor_dialog_list_panel')

local function _curPanel(fun)
    local panel = g_multi_doc_manager.get_cur_open_panel()
    if panel then
        fun(panel)
    else
        message('当前没有打开任何配置文件，无法操作')
    end
end

-- override
function Panel:init_panel()
    cc.CCCheckButton.LinkCheckView({self.chDialog, self.chTemplateCtrls, self.chAniTemplates}, {self.listTemplate, self.listCtrlsTemplate, self.listAniTemplate}, 1)

    self.listCtrlsTemplate:EnableDragAndDrop(function(item)
        if item._templateName then
            return g_uisystem.load_template_create(item._templateName)
        end
    end)

    self.listCtrlsTemplate.OnDragAndDrop = function(pt, srcItem, destItem)
        _curPanel(function(panel)
            if destItem == nil and srcItem._templateName then
                panel:AddDragConfig(srcItem._templateName, pt)
            end
        end)
    end

    -- 拖拽
    local startPos
    local startTouchPos
    local minXpos = self._layer:GetContentSize()
    local maxXpos = g_director:getWinSize().width
    self.layerMoveListDialog.OnBegin = function(pos)
        startPos = ccp(self._layer:getPosition())
        startTouchPos = pos
        return true
    end

    self.layerMoveListDialog.OnDrag = function(pos)
        local x = startPos.x + pos.x - startTouchPos.x
        if x < minXpos then
            x = minXpos
        elseif x > maxXpos then
            x = maxXpos
        end
        self._layer:SetPosition(x, startPos.y)
    end

    self.btnRefreshFileList.OnClick = function()
        if self.listTemplate:isVisible() then
            self:_refreshDialogTemplate()
        elseif self.listCtrlsTemplate:isVisible() then
            self:_refreshCtrlsTemplate()
        else
            self:_refreshAniTemplate()
        end
    end

    self.btnHideListDialog.OnClick = function()
        self._layer:setVisible(false)
    end
end

local _scriptsTemplateInfo = {}
local function _getDialogScriptUITemplate(scriptFilePath)
    local ret = _scriptsTemplateInfo[scriptFilePath]
    if ret ~= nil then
        return ret
    end

    local f = io.open(scriptFilePath)
    if f then
        for line in f:lines() do
            if string.find(line, 'g_panel_mgr.new_panel_class', nil, true) then
                local pattern = [[Panel\s*=\s*g_panel_mgr.new_panel_class\(('|")([a-zA-Z_/]+)('|")]]
                local match = luaext_string_search(line, pattern)
                if match then
                    ret = match[2]
                    if g_fileUtils:isFileExist(g_logic_editor.get_ui_template_file_path(ret)) then
                        _scriptsTemplateInfo[scriptFilePath] = ret
                        f:close()
                        return ret
                    else
                        ret = nil
                    end
                end
                break
            end
        end
        f:close()
    end

    if ret == nil then
        _scriptsTemplateInfo[scriptFilePath] = false
    end

    return false
end

local function _isDialogDirEmpty(dir)
    for _, fileInfo in ipairs(win_list_files(dir)) do
        if fileInfo.is_dir then
            if not _isDialogDirEmpty(fileInfo.path) then
                return false
            end
        elseif _getDialogScriptUITemplate(fileInfo.path) then
            return false
        end
    end

    return true
end

function Panel:_refreshDialogTemplate()
    self.listTemplate:DeleteAllSubItem()
    local scriptPath = g_logic_editor.get_project_script_dialog_path()
    if not scriptPath then
        return
    end

    local function _loadFileItem(info, parentItem, name)
        if is_string(info) and _isDialogDirEmpty(info) then
            -- avoid unused folders
            print('skip', info)
            return
        end

        local item = self.listTemplate:AddTemplateItem(parentItem)
        item.text:SetString(name)
        local w = item.text:GetContentSize()
        item:SetContentSizeAndReposChild(w + 20, 30)
        if is_string(info) then
            self.listTemplate:ExpandItem(item, false)
            item.btn.OnClick = function()
                self.listTemplate:ExpandItem(item, not self.listTemplate:IsItemExpanded(item))
            end

            local bLoaded = false
            item.OnExpand = function(bExband)
                if not bExband or bLoaded then
                    return
                end

                for _, fileInfo in ipairs(win_list_files(info)) do
                    if fileInfo.is_dir then
                        _loadFileItem(fileInfo.path, item, fileInfo.name)
                    else
                        local templateName = _getDialogScriptUITemplate(fileInfo.path)
                        if templateName then
                            -- local relativeFilePath = string.sub(fileInfo.path, #scriptPath + 1)
                            local info = {
                                template = templateName,
                                -- relative_path = relativeFilePath,
                                -- script_path = fileInfo.path,
                                -- file_name = fileInfo.name,
                            }
                            _loadFileItem(info, item, fileInfo.name)
                        end
                    end
                end

                bLoaded = true
            end

            if parentItem == nil then
                item.btn.OnClick()
            end
        else
            item.btn.OnClick = function()
                self.listTemplate:SetSelectedItems({item})
                g_multi_doc_manager.open_file(info.template)
            end

            local flashSpt = nil
            item._touchLayer_.OnMouseMove = function(bInside, pos, bFirst)
                if bFirst then
                    if bInside then
                        assert(flashSpt == nil)
                        flashSpt = g_uisystem.load_template_create('editor/uieditor/dialog_template/preview')
                        flashSpt.lTemplateName:SetString(info.template)
                        editor_utils_capture_template_sprite(info.template, flashSpt.bg)
                        g_director:getRunningScene():addChild(flashSpt, 99999)
                        editor_utils_adjust_popup_layer_pos(flashSpt, pos)
                    else
                        flashSpt:removeFromParent()
                        flashSpt = nil
                    end
                end
            end
        end
    end

    _scriptsTemplateInfo = {}
    _loadFileItem(scriptPath, nil, 'dialog')
end

function Panel:_refreshCtrlsTemplate()
    self.listCtrlsTemplate:DeleteAllSubItem()

    local templateCtrlsInfo = g_logic_editor:get_template_ctrls_info()
    if not templateCtrlsInfo then
        return
    end

    local function _loadFileItem(info, parentItem, name)
        local item = self.listCtrlsTemplate:AddTemplateItem(parentItem)
        item.text:SetString(name)
        local w = item.text:GetContentSize()
        item:SetContentSizeAndReposChild(w + 20, 30)
        if info._list_ then
            for _, v in ipairs(info._list_) do
                _loadFileItem(v, item, v.file_name)
            end

            self.listCtrlsTemplate:ExpandItem(item, false)
            item.btn.OnClick = function()
                self.listCtrlsTemplate:ExpandItem(item, not self.listCtrlsTemplate:IsItemExpanded(item))
            end

            local bLoaded = false
            item.OnExpand = function(bExband)
                if not bExband or bLoaded then
                    return
                end

                for k, v in pairs(info) do
                    if k ~= '_list_' then
                        _loadFileItem(v, item, k)
                    end
                end
                bLoaded = true
            end

            if parentItem == nil then
                item.btn.OnClick()
            end
        else
            item._templateName = info.template

            item.btn:HandleDoubleClickEvent()
            item.btn.OnDoubleClick = function()
                self.listTemplate:SetSelectedItems({item})
                g_multi_doc_manager.open_file(info.template)
            end

            -- local flashSpt = nil
            -- item._touchLayer_.OnMouseMove = function(bInside, pos, bFirst)
            --     if bFirst then
            --         if bInside then
            --             assert(flashSpt == nil)
            --             flashSpt = g_uisystem.load_template_create(info.template)
            --             flashSpt:SetTouchEnabledRecursion(false)
            --             g_director:getRunningScene():addChild(flashSpt, 99999)
            --             editor_utils_adjust_popup_layer_pos(flashSpt, pos)
            --         else
            --             flashSpt:removeFromParent()
            --             flashSpt = nil
            --         end
            --     end
            -- end

            local flashSpt = g_uisystem.load_template_create(info.template, item.flashBG)
            flashSpt:SetTouchEnabledRecursion(false)

            local w, h = flashSpt:GetContentSize()
            local sx, sy = flashSpt:getScaleX(), flashSpt:getScaleY()
            w = w * sx
            h = h * sy
            local maxW, maxH = 150, 66
            if w > maxW or h > maxH then
                local s = math.min(maxW / w, maxH / h)
                flashSpt:setScaleX(sx * s)
                flashSpt:setScaleY(sy * s)
                w = w * s
                h = h * s
            end

            flashSpt:SetPosition(0, 0)
            flashSpt:setAnchorPoint(ccp(0, 0))
            item:SetContentSizeAndReposChild(math.max(130, w + 30), 45 + h)
        end
    end

    _loadFileItem(templateCtrlsInfo, nil, 'ctrls')
end

function Panel:_refreshAniTemplate()
    self.listAniTemplate:DeleteAllSubItem()

    local templateAniInfo = g_logic_editor:get_ani_template_info()
    if not templateAniInfo or table.is_empty(templateAniInfo) then
        message('无动画信息')
        return
    end

    local function _loadFileItem(info, parentItem, name)
        local item = self.listAniTemplate:AddTemplateItem(parentItem)
        item.text:SetString(name)
        local w = item.text:GetContentSize()
        item:SetContentSizeAndReposChild(w + 20, 30)
        if info._list_ then
            for _, v in ipairs(info._list_) do
                _loadFileItem(v, item, v.file_name)
            end

            self.listAniTemplate:ExpandItem(item, false)
            item.btn.OnClick = function()
                self.listAniTemplate:ExpandItem(item, not self.listAniTemplate:IsItemExpanded(item))
            end

            local bLoaded = false
            item.OnExpand = function(bExband)
                if not bExband or bLoaded then
                    return
                end

                for k, v in pairs(info) do
                    if k ~= '_list_' then
                        _loadFileItem(v, item, k)
                    end
                end
                bLoaded = true
            end

            if parentItem == nil then
                item.btn.OnClick()
            end
        else
            item._templateName = info.template

            item.btn.OnClick = function()
                self.listTemplate:SetSelectedItems({item})
                g_multi_doc_manager.open_file(info.template)
            end

            local flashSpt = nil
            item._touchLayer_.OnMouseMove = function(bInside, pos, bFirst)
                if bFirst then
                    if bInside then
                        assert(flashSpt == nil)
                        flashSpt = g_uisystem.load_template_create(info.template)
                        flashSpt:SetTouchEnabledRecursion(false)
                        g_director:getRunningScene():addChild(flashSpt, 99999)
                        editor_utils_adjust_popup_layer_pos(flashSpt, pos)
                    else
                        flashSpt:removeFromParent()
                        flashSpt = nil
                    end
                end
            end
        end
    end

    _loadFileItem(templateAniInfo, nil, 'template')
end
