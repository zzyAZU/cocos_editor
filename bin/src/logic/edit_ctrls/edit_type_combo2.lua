
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_combo2')

-- override
function EditCtrl:on_init_ui()
    local t1, t2 = unpack(self._validateParm['target'])

    self.combo1:SetItems({})
    for _, info in ipairs(self._validateParm['list1'] or self._validateParm['list']) do
        local name, value = info[1], info[2]
        self.combo1:AddMenuItem(name, function()
            if self._data[t1] ~= value then
                self.combo1:SetString(name)
                self._data[t1] = value
                self._editCallback(self._data)
            end
        end)

        if is_equal(self._data[t1], value) then
            self.combo1:SetString(name)
        end
    end

    self.combo2:SetItems({})
    for _, info in ipairs(self._validateParm['list2'] or self._validateParm['list']) do
        local name, value = info[1], info[2]
        self.combo2:AddMenuItem(name, function()
            if self._data[t2] ~= value then
                self.combo2:SetString(name)
                self._data[t2] = value
                self._editCallback(self._data)
            end
        end)

        if is_equal(self._data[t2], value) then
            self.combo2:SetString(name)
        end
    end

    self.name1:SetString(self._validateParm['name1'])
    self.name2:SetString(self._validateParm['name2'])
end

-- override
function EditCtrl:on_update_data()
end
