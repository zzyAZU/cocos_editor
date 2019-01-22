
EditCtrl = relative_import('edit_utils').create_edit_class('edit_type_string')

-- override
function EditCtrl:on_update_data()
   self.edit:SetText(tostring(self._data.width) .. ' ' .. tostring(self._data.height))
end
