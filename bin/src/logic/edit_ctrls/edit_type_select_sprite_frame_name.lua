
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_editbox_btn2')

-- override
function EditCtrl:on_init_ui()
    self.edit.OnEditReturn = function(value)
        if self:UpdateData(value) then
            self._editCallback(self._data)
        end
    end

    --第一个按钮选择文件按钮
    self.btn1.OnClick = function()
        local plist = self._validateParm['edit_conf'][self._validateParm['plist']]
        if is_valid_str(plist) and editor_utils_is_valid_sprite_plist(plist) then
            g_panel_mgr.show('uieditor.dlg_select_spriteframe_panel', plist, self._data, function(selectFrameName)
                if selectFrameName then
                    if self:UpdateData(selectFrameName) then
                        self._editCallback(self._data)
                    end
                end
            end)
        else
            local title = '选择显示帧'
            local ext = '图像文件|*.png,*.jpg'
            local filePath = win_open_file(title, g_logic_editor.get_project_res_path(), ext)
            if is_valid_str(filePath) and self:UpdateData(filePath) then
                self._editCallback(self._data)
            end
        end
    end

    --第二个按钮辅助性功能按钮(一般打开)
    self.btn2.OnClick = function()
        local plist = self._validateParm['edit_conf'][self._validateParm['plist']]
        local path = self._data
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
    self.edit:SetText(self._data)
end
