
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_editbox_btn2')

-- override
function EditCtrl:on_init_ui()
    self.edit.OnEditReturn = function(value)
        if self:UpdateData(value) then
            self._editCallback(self._data)
        end
    end

    local title = self._validateParm['title'] or '选择文件'
    local file_type_name = self._validateParm['file_type_name'] or '文件'
    local ext = file_type_name .. '|' .. self._validateParm['file_ext'] or '*.*'
    --第一个按钮选择文件按钮
    self.btn1.OnClick = function()
        value = win_open_file(title, g_logic_editor.get_project_res_path(), ext)
        if not is_valid_str(value) then
            return
        end

        if self:UpdateData(value) then
            self._editCallback(self._data)
        end
    end

    self.btn2.OnClick = function()
        if g_fileUtils:isFileExist(self._data) then
            os.execute('explorer /select, ' .. string.gsub(g_logic_editor.get_project_res_path() .. self._data, '/', '\\'))
        end
    end

    self.name:SetString(self._validateParm['name'])
    self.btn1:SetText('选择')
    self.btn2:SetText('打开')
end

-- override
function EditCtrl:on_update_data()
    self.edit:SetText(tostring(self._data))
end
