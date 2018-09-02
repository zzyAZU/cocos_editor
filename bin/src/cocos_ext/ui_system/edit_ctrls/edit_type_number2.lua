
EditCtrl = relative_import('edit_utils').create_edit_class('edit_type_string')

-- override
function EditCtrl:on_update_data()
    local t1, t2 = unpack(self._validateParm['target'])
   self.edit:SetString(tostring(self._data[t1] .. ' ' .. self._data[t2]))
end
