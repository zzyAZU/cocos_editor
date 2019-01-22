
EditCtrl = relative_import('edit_utils').create_edit_class('edit_type_string')

-- override
function EditCtrl:on_update_data()
   self.edit:SetString(tostring(self._data))
end
