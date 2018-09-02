
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_editbox_btn')

-- override
function EditCtrl:on_init_ui()
    self.edit.OnEditReturn = function(value)
        if self:UpdateData(value) then
            self._editCallback(self._data)
        end
    end

    --第一个按钮选择文件按钮
    self.btn.OnClick = function()
        g_panel_mgr.show('uieditor.dlg_select_multilang_panel', self.btn, self._data, function(content)
            if self:UpdateData(content) then
                self._editCallback(self._data)
            end
        end)
    end

    self.name:SetString(self._validateParm['name'])
    self.btn:SetText('多国')
end

-- override
function EditCtrl:on_update_data()
    self.edit:SetText(tostring(self._data))
end
