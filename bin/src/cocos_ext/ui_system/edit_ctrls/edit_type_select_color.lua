
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_editbox_btn')

-- override
function EditCtrl:on_init_ui()
    self.edit.OnEditReturn = function(value)
        if self:UpdateData(value) then
            self._editCallback(self._data)
        end
    end

    self.btn.OnClick = function()
        local color = ccc3FromHex(self._data)
        win_choose_color(color.r or 0, color.g or 0, color.b or 0, function(r, g, b)
            if self:UpdateData({r=r, g=g, b=b}) then
                self._editCallback(self._data)
            end
        end)
    end

    self.name:SetString(self._validateParm['name'])
    self.btn:SetText('选择')
end

-- override
function EditCtrl:on_update_data()
   self.edit:SetText(string.format("%06X", self._data))
end
