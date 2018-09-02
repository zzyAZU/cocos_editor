
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_edit')

-- override
function EditCtrl:on_init_ui()
    self.edit.OnEditReturn = function(value)
        if self:UpdateData(value) then
            self._editCallback(self._data)
        end
    end

    self.name:SetString(self._validateParm['name'])
end

-- override
function EditCtrl:on_update_data()
   self.edit:SetString(self._data)
end
