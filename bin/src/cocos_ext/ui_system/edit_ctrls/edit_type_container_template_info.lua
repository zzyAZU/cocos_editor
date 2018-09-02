
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_editbox_btn')

-- override
function EditCtrl:on_init_ui()
    self.edit.OnEditReturn = function(value)
        if self:UpdateData(value) then
            -- 更新后缓存又自动生成了
            self._editCallback(table.copy(self._data))
        end
    end

    --第一个按钮选择文件按钮
    self.btn.OnClick = function()
        local templateName = self._editConf[self._validateParm['default_template']]
        local curPanelLayer = g_multi_doc_manager.get_cur_open_panel():get_layer()
        g_panel_mgr.show_multiple_with_parent('uieditor.dlg_edit_container_template_attr_panel', curPanelLayer, templateName, self._data, self.btn, function(data)
            -- print('~~~~ dlg_edit_container_template_attr_panel callback', data)
            if is_table(data) and self:UpdateData(data) then
                -- 更新后缓存又自动生成了
                self._editCallback(table.copy(self._data))
            end
        end)
    end

    self.name:SetString(self._validateParm['name'])
    self.btn:SetText('编辑')
end

-- override
function EditCtrl:on_update_data()
    self.edit:SetText(repr(self._data))
end
