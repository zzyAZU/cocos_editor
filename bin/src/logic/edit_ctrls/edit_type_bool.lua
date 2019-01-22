
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_check')

-- override
function EditCtrl:on_init_ui()
    self.check.OnChecked = function(bCheck)
        if self:UpdateData(bCheck) then
            self._editCallback(self._data)
        end
    end

    self.name:SetString(self._validateParm['name'])
end

-- override
function EditCtrl:on_update_data()
   self.check:SetCheck(self._data, false)
end
