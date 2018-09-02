
Panel = g_panel_mgr.new_panel_class('editor/uieditor/uieditor_action_demon')

-- overwrite
function Panel:init_panel(actionName)
    self.startPositionX = self.sp:getPositionX()
    self.high = self.sp:getPositionY()
    self.drawNode = cc.DrawNode:create()
    self.bg:addChild(self.drawNode)

    self:updateAction(actionName)
    self:get_layer():DelayCall(0.01, function()
        self:everyFrame()
        return 0.01
    end)
end

function Panel:updateAction(actionName)
    if actionName == self.actionName then
        self:close_panel()
    else
        self.actionName = actionName
        self.sp:stopAllActions()
        self.sp:SetPosition('25%','50%')
        self.sp:PlayAnimation(actionName)
        self:reset()
    end
end

function Panel:reset()
    self.lastPosition = cc.p(0,0)
    self.drawNode:clear()
    self.frame = 0
end

function Panel:everyFrame()
    if self.frame ~= nil and self.frame < 90 then
        local curPositionX = self.sp:getPositionX()
        self.frame = self.frame + 1
        local curPosition = cc.p(curPositionX - self.startPositionX,self.frame/90 * self.high)
        self.drawNode:drawSegment(self.lastPosition,curPosition,2,cc.c4f(0, 1, 0, 1))
        self.lastPosition = curPosition
    end
end