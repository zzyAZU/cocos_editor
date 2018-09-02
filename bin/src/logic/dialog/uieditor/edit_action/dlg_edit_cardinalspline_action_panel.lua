Panel = g_panel_mgr.new_panel_class('editor/uieditor/uieditor_edit_cardinalspline_action')

local function _get_x_y(content)
	local splitContents = string.split(content, ' ')
	if not splitContents or #splitContents ~= 2 then
		return
	end

	local positionX = splitContents[1]
	local positionY = splitContents[2]
	return positionX, positionY
end

local function _getCurFormatType(content)
	if string.find(content, '%%') then
		return 1
	elseif string.find(content, 'i') then
		return 2
	end
	return 0
end


local function _isValid(positionX, positionY)
	if not positionX or not positionY then
		return false
	end
	if tonumber(positionX) == nil and string.match(positionY, "^i([%d%.]+)$") == nil and string.match(positionX, "^([%d%.]+)%%[-+]?([%d%.]*)$") == nil then
		return false
	end

	if tonumber(positionY) == nil and string.match(positionY, "^i([%d%.]+)$") == nil and string.match(positionY, "^([%d%.]+)%%[-+]?([%d%.]*)$") == nil then
		return false
	end

	return true
end

---------------------------ControllerPoint------------------------------------------------------

ControllerPoint = CreateClass()

function ControllerPoint:__init__(panel, layer, initPos, index)
	self.isRemove = false
	self._panel = panel
	self.__layer = layer
	self._current_pos = initPos
	self._index = index
	self.__layer.label_name:SetString(string.format('控制点%s:', index))

	self:Update()
	self:_initCtrls()
	self:_updateFormatType()
end

function ControllerPoint:GetSavePosition()
	return self._current_pos.x, self._current_pos.y
end

function ControllerPoint:_initCtrls()
	local lastPosition = ccp(self._current_pos.x, self._current_pos.y)
	local hasMove = false
	self.__layer.OnBegin = function(pos)

		--isBy 第一个静止拖动
		if self._panel._isCardinalSplineBy and self._index == 1 then
			return false
		end

		hasMove = false
		lastPosition = ccp(self._current_pos.x, self._current_pos.y)
		return true
	end
	self.__layer.OnDrag = function(pos)
		hasMove = true

    	local localPos = self.__layer:getParent():convertToNodeSpace(pos)
    	local fromat_x, format_y = self:_convertPositionFormat(localPos.x, localPos.y)
    	self:Update(ccp(fromat_x, format_y))

    	self._panel:OnPreView()
		return true
	end
	self.__layer.OnEnd = function(pos)
		if not hasMove then
			return true
		end
		local currPosition = ccp(self._current_pos.x, self._current_pos.y)
    	local _setPositionCommand = SetPositionCommand:New(self._panel, self, currPosition, nil, lastPosition, nil)
    	self._panel:PushCommand(_setPositionCommand)

		return true
	end

	self.__layer.OnClick = function()
		self._panel:OnSelectItem(self)
	end

	self.__layer.label_edit.OnEditReturn = function()
		local lastPosition = ccp(self._current_pos.x, self._current_pos.y)
		local lastFormat = {self._pos_x_format_type, self._pos_y_format_type}
		local positionX, positionY = _get_x_y(self.__layer.label_edit:GetString())
		positionX, positionY = _get_x_y(self.__layer.label_edit:GetString())
		if not _isValid(positionX, positionY) then
			positionX, positionY = lastPosition.x, lastPosition.y
			self.__layer.label_edit:SetText(string.format('%s %s',positionX, positionY))
			return
		end
		self.__layer.label_edit:SetText(string.format('%s %s',positionX, positionY))
		self:_updateFormatType()
		self:Update(ccp(positionX, positionY))

		local currPosition = ccp(self._current_pos.x, self._current_pos.y)
		local currFormat = {self._pos_x_format_type, self._pos_y_format_type}
    	local _setPositionCommand = SetPositionCommand:New(self._panel, self, currPosition, currFormat, lastPosition, lastFormat)
    	self._panel:PushCommand(_setPositionCommand)
    end

end

function ControllerPoint:Update(newPos)
	if newPos then
		self._current_pos = newPos
	end
	self.__layer.label_edit:SetText(string.format('%s %s', tostring(self._current_pos.x), tostring(self._current_pos.y)))
	self.__layer:SetPosition(self._current_pos.x, self._current_pos.y)
end

function ControllerPoint:_convertPositionFormat(targetPosX, targetPosY, delta_x, delta_y)
	local layer_width, layer_height = self.__layer:getParent():GetContentSize()

	if not delta_x then
		delta_x = 0
	end

	if not delta_y then
		delta_y = 0
	end


	local percent_x_str = math.floor(targetPosX - delta_x)

	if self._pos_x_format_type == 1 then
		local p = math.round_number((targetPosX - delta_x) / layer_width * 100)
    	local n = math.round_number((targetPosX - delta_x) - layer_width * p / 100)
    	percent_x_str = p..'%'..tostring(n == 0 and '' or n)
    elseif self._pos_x_format_type == 2 then
    	percent_x_str = "i" .. tostring(math.round_number(layer_width - percent_x_str))
	end
	

	local percent_y_str = math.floor(targetPosY - delta_y)
	if self._pos_y_format_type == 1 then
		local p = math.round_number((targetPosY - delta_y) / layer_height * 100)
    	local n = math.round_number((targetPosY - delta_y) - layer_height * p / 100)
    	percent_y_str = p..'%'..tostring(n == 0 and '' or n)
    elseif self._pos_y_format_type == 2 then
    	percent_y_str = "i" .. tostring(math.round_number(layer_width - percent_y_str))
	end
    
    return percent_x_str, percent_y_str
end


function ControllerPoint:_updateFormatType()

	local positionX, positionY = _get_x_y(self.__layer.label_edit:GetString())

	self._pos_x_format_type = _getCurFormatType(tostring(positionX))
	self._pos_y_format_type = _getCurFormatType(tostring(positionY))
end

function ControllerPoint:Remove()
	self.isRemove = true
	self.__layer:setVisible(false)
end

function ControllerPoint:ReAdd()
	self.isRemove = false
	self.__layer:setVisible(true)
end

---------------------------ControllerPoint------------------------------------------------------

ParentCommand = CreateClass()

function ParentCommand:__init__(panel, subCommands)
	self.panel = panel
	self.subCommands = subCommands
	for _, subCommand in ipairs(self.subCommands or {}) do
		subCommand.parentCommand = self
	end
end

function ParentCommand:execute(isUndo)
	for _, subCommand in ipairs(self.subCommands or {}) do
		subCommand:execute(isUndo)
	end

	self.panel:OnPreView()
	self.panel:SavePositionConf()

end

function ParentCommand:CanExecute()
	return true
end

SetPositionCommand = CreateClass()

--position和lastPosition都是需要格式化的
function SetPositionCommand:__init__(panel, controllerPoint, position, positionFormat, lastPosition, lastPositionFormat)
	self.panel = panel
	self.controllerPoint = controllerPoint
	self.currPosition = position
	self.currPositionFormat = positionFormat
	self.lastPosition = lastPosition
	self.lastPositionFormat = lastPositionFormat	
end


function SetPositionCommand:execute(isUndo)
	if isUndo then
		if self.lastPositionFormat then
			self.controllerPoint._pos_x_format_type = self.lastPositionFormat[1]
			self.controllerPoint._pos_y_format_type = self.lastPositionFormat[2]
		end

		if self.lastPosition then
			self.controllerPoint:Update(self.lastPosition) 
		end
	else

		if self.currPositionFormat then
			self.controllerPoint._pos_x_format_type = self.currPositionFormat[1]
			self.controllerPoint._pos_y_format_type = self.currPositionFormat[2]
		end

		if self.currPosition then
			self.controllerPoint:Update(self.currPosition) 
		end
	end
	
	if not self.parentCommand then
		self.panel:OnPreView()
		self.panel:SavePositionConf()
	end
	
end

function SetPositionCommand:CanExecute()
	if self.controllerPoint and not self.controllerPoint.isRemove then
		return true
	end
	return false
end

CreateControllerPointCommand = CreateClass()

function CreateControllerPointCommand:__init__(panel, controllerPoint)
	self.panel = panel
	self.controllerPoint = controllerPoint
	self.hasCreate = true
end

function CreateControllerPointCommand:execute(isUndo)

	if (isUndo and not self.hasCreate) or (not isUndo and self.hasCreate) then

		if not self.parentCommand then
			self.panel:OnPreView()
			self.panel:SavePositionConf()
		end
	
		return
	end

	if isUndo then
		self.hasCreate = false
		self.panel:RemoveControllerPoint(self.controllerPoint)
	else
		self.controllerPoint = self.panel:CreateCopyControllerPoint(self.controllerPoint)
		self.hasCreate = true
	end
	
	if not self.parentCommand then
		self.panel:OnPreView()
		self.panel:SavePositionConf()
	end
end

function CreateControllerPointCommand:CanExecute()
	return true
end

DeleteControllerPointCommand = CreateClass()

function DeleteControllerPointCommand:__init__(panel, controllerPoint)
	self.panel = panel
	self.controllerPoint = controllerPoint
	self.hasDelete = false
end

function DeleteControllerPointCommand:execute(isUndo)
	if (isUndo and not self.hasDelete) or (not isUndo and self.hasDelete) then

		if not self.parentCommand then
			self.panel:OnPreView()
			self.panel:SavePositionConf()
		end

		return
	end

	if isUndo then
		self.hasDelete = false
		self.controllerPoint = self.panel:CreateCopyControllerPoint(self.controllerPoint)
	else
		self.panel:RemoveControllerPoint(self.controllerPoint)
		self.hasDelete = true
	end
	
	if not self.parentCommand then
		self.panel:OnPreView()
		self.panel:SavePositionConf()
	end
end

function DeleteControllerPointCommand:CanExecute()
	return true
end

function Panel:init_panel(actionName, actionConf, callback, saveCallback)

	self._commandList = {}
	self._currCommand = 0

	self.drawNode = cc.DrawNode:create()
    self.container:addChild(self.drawNode)

	self._actionName = actionName
	self._isCardinalSplineBy = self._actionName == 'CardinalSplineBy'

	self._callback = callback
	self._saveCallback = saveCallback
	self._actionConf = table.deepcopy(actionConf)
	if self._isCardinalSplineBy then
		local firstPoint = self._actionConf.p_list[1]
		firstPoint.x = '50%'
		firstPoint.y = '50%'
	end

	self.btnClose.OnClick = function()
		self:close_panel()
	end

	self.btnInsert.OnClick = function()
		local controllerPoint = self:CreateConrollerPoint()
		local createCommand = CreateControllerPointCommand:New(self, controllerPoint)
		self:PushCommand(createCommand)
	end

	local originParentSizeX = '100%'
	local originParentSizeY = '100%'
	self.editParentSize.OnEditReturn = function()

		local sizeX, sizeY = _get_x_y(self.editParentSize:GetString())

		if sizeX == nil then
			sizeX = originParentSizeX
			sizeY = originParentSizeY
		end
		self.editParentSize:SetText(string.format("%s %s", sizeX, sizeY))

		local targetSize = self.container:CalcSize(sizeX, sizeY)

		self.container:SetContentSize(targetSize.width, targetSize.height)
		self.container:SetPosition('50%', '50%')
		self.containerColor:SetContentSize('100%', '100%')

		self.containerColor:setVisible(false)
		self.containerColor:setVisible(true)
		self.containerColor:SetPosition('50%', '50%')


		self._currCommand = 0
		self._commandList = {}

		local _initCommands = {}
		for _, controllerPoint in ipairs(self._allControllerPoints or {}) do
			local setCommand = SetPositionCommand:New(self, controllerPoint, ccp(controllerPoint._current_pos.x, controllerPoint._current_pos.y))
			table.insert(_initCommands, setCommand)
		end
		local parentCommand = ParentCommand:New(self, _initCommands)
		self:PushCommand(parentCommand)

		self:OnPreView()
    end

	self.maskLayer.OnClick = function()
		self._curr_select_item = nil
	end

	self.maskLayer:HandleMouseEvent()
	self.maskLayer.newHandler.OnMouseWheel = function(scrollValue)
		local scrollRate = 0.05
		local delta_scale = scrollValue * scrollRate * -1
		local current_scale = self.bg:getScale() + delta_scale
		current_scale = math.max(math.min(current_scale, 1), 0.3)
		self.bg:setScale(current_scale)
	end

	self._allControllerPoints = {}
	local _initCommands = {}
	for index = 1, #self._actionConf.p_list do
		local pos = self._actionConf.p_list[index]
		local controllerPoint = self:CreateConrollerPoint(pos)
		local createCommand = CreateControllerPointCommand:New(self, controllerPoint)
		table.insert(_initCommands, createCommand)
	end
	local parentCommand = ParentCommand:New(self, _initCommands)
	self:PushCommand(parentCommand)


	local function OnUndo()
    	self:UndoCommand()
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_Z'}, OnUndo)

    --redo
    local function OnRedo()
    	self:ReDoCommand()
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_Y'}, OnRedo)

	local function OnSaveFile()
    	if self._saveCallback then
    		self._saveCallback()
    	end
    end
    self:add_key_event_callback({'KEY_CTRL', 'KEY_S'}, OnSaveFile)

    local function OnDeletePoint()
    	if self._curr_select_item and #self._allControllerPoints > 1 then
    		local deleteCommand = DeleteControllerPointCommand:New(self, self._curr_select_item)
    		self:PushCommand(deleteCommand)
    		
    		
			self._curr_select_item = nil
    	end
    end
    self:add_key_event_callback({'KEY_DELETE'}, OnDeletePoint)

    self:OnPreView()
end

function Panel:CreateConrollerPoint(pos)
	if not pos then
		pos = ccp(0, 0)
	end

	local layer = g_uisystem.load_template_create('editor/uieditor/edit_action/uieditor_action_point', self.container)
	local index = #self._allControllerPoints + 1
	local controllerPoint = ControllerPoint:New(self, layer, pos, index)
	if self._isCardinalSplineBy and index ~= 1 then
		local first_layer_x, first_layer_y = self._allControllerPoints[1].__layer:GetPosition()
		local curr_x, curr_y = controllerPoint.__layer:GetPosition()
		local real_x, real_y = curr_x + first_layer_x, curr_y + first_layer_y
		local fromat_x, format_y = controllerPoint:_convertPositionFormat(real_x, real_y)
    	controllerPoint:Update(ccp(fromat_x, format_y))
	end
	table.insert(self._allControllerPoints, controllerPoint)

	return controllerPoint
end

function Panel:CreateCopyControllerPoint(copyControllerPoint)
	copyControllerPoint:ReAdd()
	table.insert(self._allControllerPoints, copyControllerPoint._index, copyControllerPoint)

	for i = 1, #self._allControllerPoints do
		local controllerPoint = self._allControllerPoints[i]
		controllerPoint._index = i
		controllerPoint.__layer.label_name:SetString(string.format('控制点%s:', i))
	end

	return copyControllerPoint
end

function Panel:RemoveControllerPoint(controllerPoint)
	local index = controllerPoint._index
    controllerPoint:Remove()
    table.remove(self._allControllerPoints, index)

    for i = 1, #self._allControllerPoints do
		local controllerPoint = self._allControllerPoints[i]
		controllerPoint._index = i
		controllerPoint.__layer.label_name:SetString(string.format('控制点%s:', i))
	end

    self:SavePositionConf()
end

function Panel:OnSelectItem(item)
	self._curr_select_item = item
end

--保存配置
function Panel:SavePositionConf()
	local newConf = {}
	newConf.p_list = {}

	local first_x, first_y = self._allControllerPoints[1].__layer:GetPosition()
	for index, controllerPoint in ipairs(self._allControllerPoints or {}) do
		local curr_x, curr_y = self._allControllerPoints[index].__layer:GetPosition()

		local target_x, target_y = curr_x - first_x, curr_y - first_y
		if not self._isCardinalSplineBy then
			target_x = curr_x
			target_y = curr_y
		end

		local target_x_str, target_y_str = self._allControllerPoints[index]:_convertPositionFormat(target_x, target_y)
		--对于CardinalSplineBy，第一个永远是(0, 0)
		if self._isCardinalSplineBy and index == 1 then
			target_x_str = 0
			target_y_str = 0
		end

		table.insert(newConf.p_list, ccp(target_x_str, target_y_str))
	end

	if self._callback then
		self._callback(newConf)
	end
end


function Panel:PushCommand(command)

	while self._currCommand ~= #self._commandList do
		table.remove(self._commandList, #self._commandList)
	end
	table.insert(self._commandList, command)
	self._currCommand = #self._commandList
	self:ExecuteCurrentCommand(false)
end

function Panel:UndoCommand()
	if self._currCommand <= 1 then
		return
	end
	
	self:ExecuteCurrentCommand(true)
	self._currCommand = self._currCommand - 1
end

function Panel:ReDoCommand()
	self._currCommand = math.min(self._currCommand + 1, #self._commandList)
	self:ExecuteCurrentCommand(false)
end


function Panel:ExecuteCurrentCommand(isUndo)
	local command = self._commandList[self._currCommand]
	if command:CanExecute() then
		command:execute(isUndo)
	end
end


function Panel:OnPreView()
	self.drawNode:clear()

	local all_points = {}
	for _, controllerPoint in ipairs(self._allControllerPoints or {}) do
		table.insert(all_points, ccp(controllerPoint.__layer:GetPosition()))
	end
	self.drawNode:drawCardinalSpline(all_points, self._actionConf.tension or 0.1, 90, cc.c4f(0, 1, 0, 1))
end