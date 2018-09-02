
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_combo')

-- override
function EditCtrl:on_init_ui()
    self.combo:SetItems({})
    for _, info in ipairs(self._validateParm['list']) do
        local sub_group = info['sub_group']
        if sub_group then
            local sub_group_name = info['sub_group_name']
            local popUpItem = self.combo:AddPopupMenuItem(sub_group_name)
            for _, subInfo in ipairs(sub_group) do
                local name, value = subInfo[1], subInfo[2]
                self.combo:AddMenuItem(name, nil, popUpItem, function()
                    if value ~= self._data then
                        self.combo:SetString(name)
                        self._data = value
                        self._editCallback(self._data)
                    end
                end)

                if is_equal(self._data, value) then
                    self.combo:SetString(name)
                end
            end
        else
            local name, value = info[1], info[2]
            self.combo:AddMenuItem(name, function()
                if value ~= self._data then
                    self.combo:SetString(name)
                    self._data = value
                    self._editCallback(self._data)
                end
            end)

            if is_equal(self._data, value) then
                self.combo:SetString(name)
            end
        end
    end

    self.name:SetString(self._validateParm['name'])
end

-- override
function EditCtrl:on_update_data()
end
