--[[
	通用tips界面
]]

Panel = g_panel_mgr.new_panel_class('common/common_tips_panel')


-- overwrite
function Panel:init_panel(msg)
	self.lContent:SetString(tostring(msg))
	local w, h = self.lContent:GetContentSize()
	self.sBG:SetContentSize(w + 35, 72)

	self.nodeAni.eventHandler:RegisterEvent('on_open_ani_end')
	self.nodeAni.newHandler.on_open_ani_end = function()
		self:close_panel()
	end
	self.sBG:PlayAnimation('ani_open')
end