
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_editbox_btn2')

-- override
function EditCtrl:on_init_ui()
    self.edit.OnEditReturn = function(value)
        if self:UpdateData(value) then
            self._editCallback(self._data)
        end
    end

    --选择图片
    local title = '选择显示帧'
    local ext = '图像文件|*.plist,*.png,*.jpg'

    local function _tryFindPlistPath()
        local filePath = win_open_file(title, g_logic_editor.get_project_res_path(), ext)
        if editor_utils_is_valid_sprite_plist(filePath) then
            local plist = filePath
            if g_fileUtils:isFileExist(plist) then
                g_panel_mgr.show('uieditor.dlg_select_spriteframe_panel', plist, self._data['path'], function(selectFrameName)
                    if self:UpdateData({plist=plist, path=selectFrameName}) then
                        self._editCallback(self._data)
                    end
                end)
            end
        elseif self:UpdateData(filePath) then
            self._editCallback(self._data)
        end
    end

    --第一个按钮选择文件按钮
    self.btn1.OnClick = function()
        local plist = self._data['plist']
        if editor_utils_is_valid_sprite_plist(plist) then
            g_panel_mgr.show('uieditor.dlg_select_spriteframe_panel', plist, self._data['path'], function(selectFrameName)
                if selectFrameName then
                    if self:UpdateData({plist=plist, path=selectFrameName}) then
                        self._editCallback(self._data)
                    end
                else
                    _tryFindPlistPath()
                end
            end)
        else
            _tryFindPlistPath()
        end
    end

    --第二个按钮辅助性功能按钮(一般打开)
    self.btn2.OnClick = function()
        local plist = self._data['plist']
        local path = self._data['path']
        if g_fileUtils:isFileExist(plist) then
            os.execute('explorer /select, ' .. string.gsub(g_logic_editor.get_project_res_path() .. plist, '/', '\\'))
        elseif g_fileUtils:isFileExist(path) then
            os.execute('explorer /select, ' .. string.gsub(g_logic_editor.get_project_res_path() .. path, '/', '\\'))
        end
    end

    self.name:SetString(self._validateParm['name'])
    self.btn1:SetText('选择')
    self.btn2:SetText('打开')
end

-- override
function EditCtrl:on_update_data()
    local plist = self._data['plist']
    local path = self._data['path']
    if is_valid_str(plist) and is_valid_str(path) then
        self.edit:SetText(string.format("%s %s", plist, path))
    elseif is_valid_str(path) then
        self.edit:SetText(path)
    end
end
