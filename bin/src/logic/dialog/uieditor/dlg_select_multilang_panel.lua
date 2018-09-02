--[[
    ui编辑器多国语选择界面
]]
Panel = g_panel_mgr.new_panel_class('editor/dialog/select_multi_lang_panel')


-- overwrite
function Panel:init_panel(btn, content, callback)
    self:add_key_event_callback('KEY_ESCAPE', function()
        self:close_panel()
    end)

    self._layer.OnClick = function()
        self:close_panel()
    end

    local pos = btn:convertToWorldSpace(ccp(0, 0))
    self.bg:setPosition(pos)

    self.edit:SetText(is_number(content) and tostring(content) or '0')
    
    self.btnOK.OnClick = function()
        local num = tonumber(self.edit:getText())
        if num then
            self:close_panel()
            callback(math.round_number(num))
        else
            message('请输入合法的多国ID')
        end
    end
end
