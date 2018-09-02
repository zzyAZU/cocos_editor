--[[====================================
=
=           CCButton 扩展
=
========================================]]
local constant = g_constant_conf.constant_uisystem

local BUTTON_STATE = constant.BUTTON_STATE
local BUTTON_STATE_NODE_NAME = constant.BUTTON_STATE_NODE_NAME

local CCButton, Super = tolua_get_class('CCButton')

-- static override
function CCButton:Create()
    return cc.Layer:create():CastTo(self):_init()
end

--override
function CCButton:_init()
    Super._init(self)

    self._b9Spt = false
    self._displaySpts = {}     --3个状态显示的图

    self._bEnableText = true
    self._text = nil --显示的文本控件
    self._text_offset = {x = '50%', y ='50%'}--文本坐标
    self._display_textsColors = {} --3个状态显示的文本的颜色

    self._bEnable = true
    self._curState = BUTTON_STATE.STATE_NORMAL

    self._zoomScale = 0.8
    self.__oldScale = nil  -- 按下时保存原有的按钮的scale值，用于恢复scale属性的时候使用

    self:setTouchEnabled(true)

    return self
end

--override
function CCButton:_registerInnerEvent()
    Super._registerInnerEvent(self)

    self:_regInnerEvent('OnDragInside')
    self:_regInnerEvent('OnDragOutside')
    
    local _bDragInside
    self.newHandler.OnBegin = function()
        self:_updateCurState(BUTTON_STATE.STATE_SELECTED)
        return true
    end

    self.newHandler.OnEnd = function(pt)
        self:_updateCurState(BUTTON_STATE.STATE_NORMAL)
        _bDragInside = nil
    end

    self.newHandler.OnCancel = function()
        self:_updateCurState(BUTTON_STATE.STATE_NORMAL)
        _bDragInside = nil
    end

    self.newHandler.OnDrag = function(pt)
        if self:IsPointIn(pt) then
            if not _bDragInside then
                _bDragInside = true
                self:_updateCurState(BUTTON_STATE.STATE_SELECTED)
                self.eventHandler:Trigger('OnDragInside', pt)
            end
        else
            if _bDragInside == true then
                _bDragInside = false
                self:_updateCurState(BUTTON_STATE.STATE_NORMAL)
                self.eventHandler:Trigger('OnDragOutside', pt)
            end
        end
    end

    self.newHandler.OnClick = function(pt)
        g_logicEventHandler:Trigger('logic_button_clicked', self, pt)
    end
end

--override
function CCButton:SetContentSize(sw, sh)
    local size
    if self._b9Spt or table.is_empty(self._displaySpts) then
        size = Super.SetContentSize(self, sw, sh)
        for _, spt in pairs(self._displaySpts) do
            spt:setContentSize(size)
        end
    else
        --是sprite则跟sprite一样大，否则自定义大小
        size = self._displaySpts[BUTTON_STATE.STATE_NORMAL]:getContentSize()
        self:setContentSize(size)
    end
    
    if self._text then
        self._text:SetPosition(self._text_offset.x, self._text_offset.y)
    end
    
    return size
end

function CCButton:SetEnableText(bEnable)
    self._bEnableText = bEnable
end

function CCButton:SetText(text, font_size, color1, color2, color3)
    if not self._bEnableText then
        return
    end
    if self._text == nil then
        self._text = cc.RichLabel:Create(text, font_size)
        self:AddChild(nil, self._text, 1)
    else
        self._text:SetString(text)
    end

    if color1 then
        self._display_textsColors[BUTTON_STATE.STATE_NORMAL] = ccc3FromHex(color1)
        self._display_textsColors[BUTTON_STATE.STATE_SELECTED] = ccc3FromHex(color2)
        self._display_textsColors[BUTTON_STATE.STATE_DISABLED] = ccc3FromHex(color3)
    end
end

function CCButton:SetString(...)
    local ret = GetTextByLanguageI(...)
    self:SetText(ret)
    return ret
end

function CCButton:SetTextOffset(text_offset)
    self._text_offset = text_offset
end

--[[设置Button的三态按钮信息]]
function CCButton:SetFrames(plist, paths, b9Spt, capInsets)
    paths = paths or {}
    self._b9Spt = b9Spt

    assert(table.is_empty(self._displaySpts))

    for state, path in ipairs(paths) do
        local frame = get_sprite_frame(path, plist)
        if not frame and state ~= BUTTON_STATE.STATE_NORMAL then
            frame = get_sprite_frame(paths[BUTTON_STATE.STATE_NORMAL], plist)
        end
        if frame then
            local spt = cc.Sprite:createWithSpriteFrame(frame)
            if b9Spt then
                spt:setStretchEnabled(true)
                spt:setCenterRect(capInsets)
            else
                spt:setStretchEnabled(false)
            end
            spt:setAnchorPoint(ccp(0,0))
            self:addChild(spt)
            self._displaySpts[state] = spt
        elseif state == BUTTON_STATE.STATE_NORMAL then
            break
        end
    end
end

function CCButton:SetZoomScale(scale)
    self._zoomScale = scale
end

--[[按钮有效性设置]]
function CCButton:SetEnable(bEnable)
    if bEnable == self._bEnable then return end

    self._bEnable = bEnable
    self:setTouchEnabled(bEnable)

    self:_updateCurState(bEnable and BUTTON_STATE.STATE_NORMAL or BUTTON_STATE.STATE_DISABLED)
end

--[[更新按钮的三态]]
function CCButton:_updateCurState(state)
    if state ~= nil then
        self._curState = state
    end

    local curState = self._curState

    if self._text then
        self._text:setTextColor(self._display_textsColors[curState])
    end

    for state = BUTTON_STATE.STATE_NORMAL, BUTTON_STATE.STATE_DISABLED do
        local spt = self._displaySpts[state]
        if spt then
            spt:setVisible(state == curState)
        end

        -- 不同状态节点可见性切换
        local stateChildNode = self[BUTTON_STATE_NODE_NAME[state]]
        if stateChildNode then
            stateChildNode:setVisible(state == curState)
        end
    end

    if curState == BUTTON_STATE.STATE_SELECTED then
        if self.__oldScale == nil then
            self.__oldScale = {self:getScaleX(), self:getScaleY()}
            self:setScaleX(self.__oldScale[1] * self._zoomScale)
            self:setScaleY(self.__oldScale[2] * self._zoomScale)
        end
    elseif curState == BUTTON_STATE.STATE_NORMAL then
        if self.__oldScale then
            self:setScaleX(self.__oldScale[1])
            self:setScaleY(self.__oldScale[2])
            self.__oldScale = nil
        end
    end
end

function CCButton:SetTextAndAjustSize(text, w, h)
    if text then
        self:SetText(text)
    end
    local tw, th = self._text:GetContentSize()
    return self:SetContentSize(w + tw, h + th)
end