--[[====================================
=
=           CCCheckButton 扩展
=
========================================]]
local constant = g_constant_conf.constant_uisystem
local BUTTON_STATE = constant.BUTTON_STATE
local BUTTON_STATE_NODE_NAME = constant.BUTTON_STATE_NODE_NAME

local CCCheckButton, Super = tolua_get_class('CCCheckButton')

--override
function CCCheckButton:_init()
    Super._init(self)
    self._bCheck = false
    self._groupList = nil
    return self
end

--override
function CCCheckButton:_registerInnerEvent()
    Super._registerInnerEvent(self)

    self:_regInnerEvent('OnCheck')
    self:_regInnerEvent('OnChecked')

    self.newHandler.OnClick = function(pt)
        local result = self.eventHandler:Trigger('OnCheck', not self._bCheck)
        
        --_regInnerEvent 默认增加了一个回调
        if not result[result.__count__] then
            return
        end
        
        self:SetCheck(not self._bCheck, true)
    end
end

function CCCheckButton:SetCheck(bCheck, bTrigger)
    --gourp can not unset check
    if self._groupList and self._bCheck then
        return
    end

    if not self:_setCheck(bCheck) then
        return
    end

    local index = nil
    if self._groupList then
        for i, check in ipairs(self._groupList) do
            if check == self then
                index = i
            else
                check:_setCheck(false)
            end
        end
    end

    if bTrigger then
        self.eventHandler:Trigger('OnChecked', self._bCheck, index)
    end
end

function CCCheckButton:GetCheck()
    return self._bCheck
end

function CCCheckButton:_setCheck(bCheck)
    if self._bCheck == bCheck then return end
    self._bCheck = bCheck
    self:_updateCurState()
    return true
end

function CCCheckButton:SetGroup(list)
    if self._groupList == list then
        return
    end

    if self._groupList then
        table.arr_remove_v(self._groupList, self)
    end

    self._groupList = list

    if list and not table.find_v(list, self) then
        table.insert(list, self)
    end

    return true
end

-- override
function CCCheckButton:_updateCurState(state)
    if state ~= nil then
        self._curState = state
    end

    local curState = self._curState
    local bCheck = self._bCheck

    if self._text then
        if curState == BUTTON_STATE.STATE_DISABLED then
            self._text:setTextColor(self._display_textsColors[curState])
        else
            self._text:setTextColor(self._display_textsColors[bCheck and BUTTON_STATE.STATE_SELECTED or BUTTON_STATE.STATE_NORMAL])
        end
    end

    for state = BUTTON_STATE.STATE_NORMAL, BUTTON_STATE.STATE_DISABLED do
        local spt = self._displaySpts[state]
        if spt then
            if curState == BUTTON_STATE.STATE_DISABLED then
                spt:setVisible(state == curState)
            else
                spt:setVisible(state == (bCheck and BUTTON_STATE.STATE_SELECTED or BUTTON_STATE.STATE_NORMAL))
            end
        end

        local stateChildNode = self[BUTTON_STATE_NODE_NAME[state]]
        if stateChildNode then
            stateChildNode:setVisible(curState == BUTTON_STATE.STATE_DISABLED and state == curState or
                                    state == (bCheck and BUTTON_STATE.STATE_SELECTED or BUTTON_STATE.STATE_NORMAL))
        end
    end
end


-- static utityties
function CCCheckButton.LinkCheckView(checkButtons, viewNodes, selIndex)
    local group = {}
    for i, check in ipairs(checkButtons) do
        check:SetGroup(group)
        check:SetCheck(false, false)
        check.newHandler.OnChecked = function()
            for j, viewNode in ipairs(viewNodes) do
                viewNode:setVisible(j == i)
            end
        end
    end

    if selIndex then
        checkButtons[selIndex]:SetCheck(selIndex, true)
    end
end