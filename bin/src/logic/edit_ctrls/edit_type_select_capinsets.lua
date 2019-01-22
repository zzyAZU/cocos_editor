
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
        local edit_sprite_frame = self._validateParm['edit_sprite_frame']
        local spriteFrame
        if is_table(edit_sprite_frame) then
            local t1, t2 = unpack(edit_sprite_frame)
            spriteFrame = {plist=self._editConf[t1], path=self._editConf[t2]}
        else
            spriteFrame = self._editConf[edit_sprite_frame]
        end

        local plist, path = spriteFrame.plist, spriteFrame.path

        if get_sprite_frame(path, plist) then
            g_panel_mgr.show('uieditor.dlg_select_caps_insets_panel', plist, path, self._data, function(value)
                if self:UpdateData(value) then
                    self._editCallback(self._data)
                end
            end)
        else
            message('当前编辑的图无效，请设置有效的图片路径')
        end
    end

    self.name:SetString(self._validateParm['name'])
    self.btn:SetText('选择')
end

-- override
function EditCtrl:on_update_data()
    local capInsets = self._data
    self.edit:SetText(capInsets.x..' '..capInsets.y..' '..capInsets.width..' '..capInsets.height)
end
