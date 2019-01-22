
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_combo')

-- override
function EditCtrl:on_init_ui()
    self.combo:SetItems({})

    local list = self._validateParm.list
    if is_function(list) then
        list = list(self)
    end

    self:_createPopupMenuItem(list)

    self.name:SetString(self._validateParm['name'])
end

-- override
function EditCtrl:on_update_data()
end

function EditCtrl:_createPopupMenuItem(info, popUpItem)

    local sub_group = info['sub_group']
    if sub_group then
        local sub_group_name = info['sub_group_name']
        local popUpItemNodeType = self.combo:AddPopupMenuItem(sub_group_name, popUpItem)
        self:_createPopupMenuItem(info.sub_group, popUpItemNodeType) 
    else
        for _, typeInfo in ipairs(info) do
            if typeInfo.sub_group then
                self:_createPopupMenuItem(typeInfo, popUpItem)
            else
                self:_createChildMenuItem(typeInfo, popUpItem)
            end
        end
    end
end

function EditCtrl:_createChildMenuItem(typeInfo, popUpItem)
    local name, value = typeInfo[1], typeInfo[2]
    if is_equal(self._data, value) then
        self.combo:SetString(name)
    end
    self.combo:AddMenuItem(name, nil, popUpItem, function()
        if name ~= self._data then
            self.combo:SetString(name)
            self._data = value
            self._editCallback(self._data)
        end
    end)
end