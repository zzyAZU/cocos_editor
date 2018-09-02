Panel = g_panel_mgr.new_panel_class('editor/uieditor/uieditor_edit_bezier_action')

SetPositionCommand = CreateClass()

function SetPositionCommand:__init__(panel, target, position, positionFormat, lastPosition, lastPositionFormat)
	self.panel = panel
	self.target = target
	self.currPosition = position
	self.currPositionFormat = positionFormat
	self.lastPosition = lastPosition
	self.lastPositionFormat = lastPositionFormat	
end

function SetPositionCommand:execute(isUndo)
	if isUndo then
		if self.lastPositionFormat then
			self.panel._positionFormat[self.target][1] = self.lastPositionFormat[1]
			self.panel._positionFormat[self.target][2] = self.lastPositionFormat[2]
		end
		if self.lastPosition then
			self.target:SetPosition(self.lastPosition.x, self.lastPosition.y)
		end
	else
		if self.currPositionFormat then
			self.panel._positionFormat[self.target][1] = self.currPositionFormat[1]
			self.panel._positionFormat[self.target][2] = self.currPositionFormat[2]
		end
		self.target:SetPosition(self.currPosition.x, self.currPosition.y)
	end
	

	self.panel:_updateItemPostionTips(self.target)
	self.panel:_previewBezier()

	self.panel:_refreshOperate()
end

function Panel:init_panel(actionName, actionConf, callback, saveCallback)
	self._actionName = actionName
	self._isBezierBy = self._actionName == 'BezierBy'

	self._callback = callback
	self._saveCallback = saveCallback
	self._actionConf = table.deepcopy(actionConf)
	

	self.btnClose.OnClick = function()
		self:close_panel()
	end

	self:_initItem(self.startPoint)
	self:_initItem(self.controller1)
	self:_initItem(self.controller2)
	self:_initItem(self.endPoint)

	self.drawNode = cc.DrawNode:create()
    self.container:addChild(self.drawNode)

    self.editParentSize.OnEditReturn = function()
    	local editParentSizeContent = self.editParentSize:GetString()
		local splitContents = string.split(editParentSizeContent, ' ')
		if not splitContents or #splitContents ~= 2 then
			return
		end
		local sizeX = splitContents[1]
		local sizeY = splitContents[2]

		local targetSize = self.container:CalcSize(sizeX, sizeY)

		self:_initItemXYFromat()
		self:_resetActionConf()
		self:_onChangeSurfaceSize(targetSize)
    end

    self:_initItemXYFromat()
    self:_resetActionConf()
    self:_onChangeSurfaceSize(cc.size(self.container:GetContentSize()))

    local function OnUndo()
    	self:_undoCommand()
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_Z'}, OnUndo)

    --redo
    local function OnRedo()
    	self:_reDoCommand()
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_Y'}, OnRedo)

    local function OnSaveFile()
    	if self._saveCallback then
    		self._saveCallback()
    	end
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_S'}, OnSaveFile)
end

local function _getCurFormatType(content)
	if string.find(content, '%%') then
		return 1
	elseif string.find(content, 'i') then
		return 2
	end
	return 0
end

function Panel:_initItemXYFromat()
	self._positionFormat = {}
	self._positionFormat[self.startPoint] = {1, 1} --百分比为1, 数值为0
	self._positionFormat[self.controller1] = {_getCurFormatType(self._actionConf.p1.x), _getCurFormatType(self._actionConf.p1.y)}
	self._positionFormat[self.controller2] = {_getCurFormatType(self._actionConf.p2.x), _getCurFormatType(self._actionConf.p2.y)}
	self._positionFormat[self.endPoint] = {_getCurFormatType(self._actionConf.p.x), _getCurFormatType(self._actionConf.p.y)}
end

function Panel:_onChangeSurfaceSize(targetSize)
	self:_clearState()

	self.container:SetContentSize(targetSize.width, targetSize.height)
	self.container:SetPosition('50%', '50%')
	self.containerColor:SetContentSize('100%', '100%')

	self.containerColor:setVisible(false)
	self.containerColor:setVisible(true)
	self.containerColor:SetPosition('50%', '50%')

	self:_refreshItems()
	
	local commands = {}
	table.insert(commands, SetPositionCommand:New(self, self.controller1, ccp(self.controller1:GetPosition()), {self._positionFormat[self.controller1][1], self._positionFormat[self.controller1][2]}))
	table.insert(commands, SetPositionCommand:New(self, self.controller2, ccp(self.controller2:GetPosition()), {self._positionFormat[self.controller2][1], self._positionFormat[self.controller2][2]}))
	table.insert(commands, SetPositionCommand:New(self, self.endPoint, ccp(self.endPoint:GetPosition()), {self._positionFormat[self.endPoint][1], self._positionFormat[self.endPoint][2]}))
	self:_pushCommand(commands)
end

--重置为之前传进来的控制点数据
function Panel:_resetActionConf()
	if self._isBezierBy then
		self.startPoint.label:SetString(string.format('%s %s', '50%', '50%'))
	else
		self.startPoint.label:SetString(string.format('%s %s', '0', '0'))
	end

	self.controller1.label:SetString(string.format('%s %s', self._actionConf.p1.x, self._actionConf.p1.y))
	self.controller2.label:SetString(string.format('%s %s', self._actionConf.p2.x, self._actionConf.p2.y))
	self.endPoint.label:SetString(string.format('%s %s', self._actionConf.p.x, self._actionConf.p.y))

	self._commandList = {}
	self._currCommand = 0
end

function Panel:_refreshItems()
	
	self:_resetItem(self.startPoint)
	self:_resetItem(self.controller1)
	self:_resetItem(self.controller2)
	self:_resetItem(self.endPoint)

end

function Panel:_resetItem(target)
	local deltaPos = self.startPoint:CalcPos(self.startPoint:GetPosition())
	local p = target:CalcPos(self:_getItemShowPosition(target))
	if not self._isBezierBy or target == self.startPoint then
		deltaPos.x = 0
		deltaPos.y = 0
	end

	target:SetPosition(deltaPos.x + p.x, deltaPos.y + p.y)	
end

function Panel:_initItem(target)
	local lastPosition = ccp(target:GetPosition())
	target.OnBegin = function(pos)
		self._curr_select_item = target
		lastPosition = ccp(target:GetPosition())
		return true
	end
	target.OnDrag = function(pos)
		if not self._curr_select_item then
			return
		end
		
    	local localPos = self.container:convertToNodeSpace(pos)
		self._curr_select_item:SetPosition(localPos.x, localPos.y)
		self:_updateItemPostionTips(self._curr_select_item)

		self:_previewBezier()
		return true
	end
	target.OnEnd = function(pos)
		self._curr_select_item = nil

		self:_refreshOperate()
		local commands = {}

		local positionFormat = {self._positionFormat[target][1], self._positionFormat[target][2]}
		table.insert(commands, SetPositionCommand:New(self, target, ccp(target:GetPosition()), positionFormat, lastPosition, positionFormat))
		self:_pushCommand(commands)
		return true
	end

	target.label.OnEditReturn = function()
		local content = target.label:GetString()
		local splitContents = string.split(content, ' ')
		if not splitContents or #splitContents ~= 2 then
			return
		end

		local positionX = splitContents[1]
		local positionY = splitContents[2]

		target.label:SetText(string.format('%s %s',positionX, positionY))
		positionX = tonumber(positionX) or positionX
		positionY = tonumber(positionY) or positionY

		local positionFormat = {self._positionFormat[target][1], self._positionFormat[target][2]}

		local commands = {}
		table.insert(commands, SetPositionCommand:New(self, target, ccp(positionX, positionY), {_getCurFormatType(positionX), _getCurFormatType(positionY)}, ccp(target:GetPosition()), positionFormat))
		self:_pushCommand(commands)
    end

end

function Panel:_clearState()
	self.drawNode:clear()
end

function Panel:_updateItemPostionTips(item)
	local str_x, str_y = self:_getItemFormatPosition(item)
	item.label:SetText(string.format('%s %s', str_x, str_y))
end

function Panel:_previewBezier()

	self:_clearState()

    self.drawNode:drawLine(cc.p(self.startPoint:GetPosition()), cc.p(self.controller1:GetPosition()), cc.c4f(0, 0, 0, 1))
    self.drawNode:drawLine(cc.p(self.endPoint:GetPosition()), cc.p(self.controller2:GetPosition()), cc.c4f(0, 0, 0, 1))
    self.drawNode:drawCubicBezier(cc.p(self.startPoint:GetPosition()), cc.p(self.controller1:GetPosition()), cc.p(self.controller2:GetPosition()), cc.p(self.endPoint:GetPosition()), 90, cc.c4f(0, 1, 0, 1))
end


function Panel:_refreshAllItemFormatPosition()
	
	local startX, startY = self.startPoint:GetPosition()
	if not self._isBezierBy then
		startX = 0
		startY = 0
	end
	local controller1_pos_x,controller1_pos_y = self:_getItemFormatPosition(self.controller1, true, startX, startY)
	local controller2_pos_x,controller2_pos_y = self:_getItemFormatPosition(self.controller2, true, startX, startY)
	local end_pos_x,end_pos_y = self:_getItemFormatPosition(self.endPoint, true, startX, startY)

    self._controller1_pos_x_str, self._controller1_pos_y_str = controller1_pos_x, controller1_pos_y
    self._controller2_pos_x_str, self._controller2_pos_y_str = controller2_pos_x, controller2_pos_y
    self._end_pos_x_str, self._end_pos_y_str = end_pos_x, end_pos_y
end

--获取item对应的位置格式,自动判断by or to
--notUseIType:不用i格式
function Panel:_getItemFormatPosition(item, notUseIType, delta_x, delta_y)

	local positionFormatXType = self._positionFormat[item][1]
	local positionFormatYType = self._positionFormat[item][2]

	if notUseIType then
		if positionFormatXType == 2 then
			positionFormatXType = 0
		end
		if positionFormatYType == 2 then
			positionFormatYType = 0
		end
	end
	local targetPosX, targetPosY = item:GetPosition()
	return self:_convertPositionFormat(targetPosX, targetPosY, positionFormatXType, positionFormatYType, delta_x, delta_y)
end

function Panel:_convertPositionFormat(targetPosX, targetPosY, formatX, formatY, delta_x, delta_y)
	local layer_width, layer_height = self.container:GetContentSize()

	if not delta_x then
		delta_x = 0
	end

	if not delta_y then
		delta_y = 0
	end


	local percent_x_str = math.floor(targetPosX - delta_x)

	if formatX == 1 then
		local p = math.round_number((targetPosX - delta_x) / layer_width * 100)
    	local n = math.round_number((targetPosX - delta_x) - layer_width * p / 100)
    	percent_x_str = p..'%'..tostring(n == 0 and '' or n)
    elseif formatX == 2 then
    	percent_x_str = "i" .. tostring(math.round_number(width - percent_x_str))
	end
	

	local percent_y_str = math.floor(targetPosY - delta_y)
	if formatY == 1 then
		local p = math.round_number((targetPosY - delta_y) / layer_height * 100)
    	local n = math.round_number((targetPosY - delta_y) - layer_height * p / 100)
    	percent_y_str = p..'%'..tostring(n == 0 and '' or n)
    elseif formatY == 2 then
    	percent_y_str = "i" .. tostring(math.round_number(width - percent_y_str))
	end
    
    return percent_x_str, percent_y_str
end

--获取item文本框对应的位置
function Panel:_getItemShowPosition(item)
	local content = item.label:GetString()
	local splitContents = string.split(content, ' ')
	if not splitContents or #splitContents ~= 2 then
		return
	end
	return splitContents[1], splitContents[2]
end

--刷新操作 保存配置
function Panel:_refreshOperate()
	self:_refreshAllItemFormatPosition()

	local return_conf = {}
	return_conf.p = ccp(self._end_pos_x_str, self._end_pos_y_str)
	return_conf.p1 = ccp(self._controller1_pos_x_str, self._controller1_pos_y_str)
	return_conf.p2 = ccp(self._controller2_pos_x_str, self._controller2_pos_y_str)

	if self._callback then
		self._callback(return_conf)
	end
end

function Panel:_pushCommand(command)
	while self._currCommand ~= #self._commandList do
		table.remove(self._commandList, #self._commandList)
	end
	table.insert(self._commandList, command)
	self._currCommand = #self._commandList
	self:_executeCurrentCommand(false)
end

function Panel:_undoCommand()

	if self._currCommand <= 1 then
		return
	end

	self:_executeCurrentCommand(true)
	self._currCommand = self._currCommand - 1
end

function Panel:_reDoCommand()
	self._currCommand = math.min(self._currCommand + 1, #self._commandList)
	self:_executeCurrentCommand(false)
end

function Panel:_executeCurrentCommand(isUndo)
	local commands = self._commandList[self._currCommand]
	if commands then
		for _, command in ipairs(commands) do
			command:execute(isUndo)
		end
	end
end



