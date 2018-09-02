--[[
    ui编辑器选择spriteFrame界面
]]
Panel = g_panel_mgr.new_panel_class('editor/dialog/select_sprite_frame_panel')

-- overwrite
function Panel:init_panel(plist, path, callback)
    self:add_key_event_callback('KEY_ESCAPE', function()
        self:close_panel()
    end)

    self._layer.OnClick = function()
        self:close_panel()
        callback(nil)
    end

    local info = utils_get_plist_conf(plist)['frames']
    self.list:SetInitCount(0)
    for name, _ in pairs(info) do
        local item = self.list:AddTemplateItem()

        item:HandleMouseEvent()
        item.OnMouseMove = function(bMoveInside, pos, bFirst)
            if bFirst then
                item.bg:setVisible(bMoveInside)
            end
        end
        
        item.txt:SetString(name)

        if name == path then
            item.txt:setTextColor(ccc3FromHex(0xff0000))
        end
        
        local spt = item.spt
        spt:SetPath(plist, name)
        local _, h = spt:GetContentSize()
        if h > 100 then
            spt:setScale(100 / h)
        end
        item.OnClick = function()
            self:close_panel()
            callback(name)
        end
    end
end
