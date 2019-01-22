
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_editbox_btn2')

-- override
function EditCtrl:on_init_ui()
    self.edit.OnEditReturn = function(value)
        if self:UpdateData(value) then
            self._editCallback(self._data)
        end
    end

    self.btn1.OnClick = function()
        local ext = '*.json'
        local value = win_open_file('选择模板', g_logic_editor.get_project_ui_template_path(), ext)
        if is_valid_str(value) then
            if self:UpdateData(string.sub(value, 1, -#ext)) then
                self._editCallback(self._data)
            end
        end
    end

    -- 第二个按钮辅助性功能按钮(一般打开)
    self.btn2.OnClick = function()
        g_multi_doc_manager.open_file(self._data)
    end

    self.name:SetString(self._validateParm['name'])
    self.btn1:SetText('选择')
    self.btn2:SetText('打开')
end

-- override
function EditCtrl:on_update_data()
    self.edit:SetText(tostring(self._data))
end
