--[[====================================
=
=           cocos 扩展
=
========================================]]
--[[使用到的类]]
-- cocos
-- cc.Node
-- cc.Layer
-- cc.LayerColor
-- cc.LayerGradient
-- cc.Label
-- cc.Sprite
-- cc.DrawNode
-- cc.ProgressTimer
-- cc.ParticleSystemQuad
-- cc.ClippingNode

-- cocos_extension
-- cc.ParticleSystem3D
-- cc.ControlHuePicker
-- cc.ControlColourPicker
-- cc.PUParticleSystem3D
-- cc.ControlSlider
-- cc.ControlSaturationBrightnessPicker
-- cc.ControlPotentiometer
-- cc.ControlSwitch
-- cc.ScrollView

-- cocos_ui
-- ccui.EditBox
-- ccui.LoadingBar
-- ccui.Slider
local config_double_click_default_interval = 0.25
local config_double_click_schedule_flag = 10000
local config_loadingbar_ani_delt = 0.05
local config_loadingbar_ani_tag = 10001

local LabelType = {
    TTF = 0,
    BMFONT = 1,
    CHARMAP = 2,
    STRING_TEXTURE = 3,
}

local constant_uisystem = g_constant_conf.constant_uisystem



-- override static
function cc.Node:Create(...)
    return self:create(...):_init()
end

-- override
-- @desc:
--     初始化调用 return self
-- 如果有不需要使用事件的节点可以在Create的时候不用 _init
function cc.Node:_init()
    self.eventHandler = g_event_mgr.new_event_handler()  --节点事件处理
    self.newHandler = self.eventHandler.newHandler  -- 快速注册事件变量
    self:_registerInnerEvent()
    return self
end

-- 判断该节点是否为脚本创建
function cc.Node:IsScriptsNode()
    return self.eventHandler ~= nil
end

-- override
-- @desc:
--     初始化类的内部事件调用
function cc.Node:_registerInnerEvent()
end

--内部使用注册事件方法
function cc.Node:_regInnerEvent(event)
    self.eventHandler:RegisterEvent(event)
    self.eventHandler:AddCallback(event, function(...)
        if is_function(self[event]) then
            return self[event](...)
        else
            return true
        end
    end, 1)
end

function cc.Node:HandleMouseEvent()
    self:_regInnerEvent('OnMouseMove')
    self:_regInnerEvent('OnMousePress')
    self:_regInnerEvent('OnMouseWheel')
    self:_regInnerEvent('OnMouseDown')
    self:_regInnerEvent('OnMouseUp')
    g_ui_event_mgr.add_mouse_event(self)
end

-- pos & size
cc.Node.CalcSize = ccext_node_calc_size
cc.Node.CalcPos = ccext_node_calc_pos
cc.Node.SetContentSize = ccext_node_set_content_size  -- override
cc.Node.SetPosition = ccext_node_set_position
cc.Node.GetPosition = cc.Node.getPosition

function cc.Node:SetPosition(x, y)
    self._x = x
    self._y = y
    return ccext_node_set_position(self, x, y)
end

function cc.Node:SetContentSize(w, h)
    self._w = w
    self._h = h
    return ccext_node_set_content_size(self, w, h)
end

function cc.Node:GetContentSize()
    local size = self:getContentSize()
    return size.width, size.height
end

-- override
-- @desc:
--     判断pt是否在Node内部，pt在世界坐标系
function cc.Node:_isPointIn(pt)
    local p = self:convertToNodeSpace(pt)
    local w, h = self:GetContentSize()
    return w >= p.x and p.x >= 0 and h >= p.y and p.y >= 0
end

-- @desc:
--     指定点是否在该节点内部
function cc.Node:IsPointIn(pt)
    return (self._clipObj == nil or self._clipObj:IsPointIn(pt)) and self:_isPointIn(pt)
end

-- #设置触碰的裁剪节点，如果裁剪节点没触碰到，则该节点也不可能触碰到，不能设置循环引用的clipobject
function cc.Node:SetClipObject(clip_object)
    assert(tolua_is_obj(clip_object) or clip_object == nil)
    
    local clipObj = clip_object

    --clip object 引用的节点不能够循环引用
    while clipObj do
        assert(clipObj ~= self)
        clipObj = clipObj._clipObj
    end
    
    self._clipObj = clip_object
end

function cc.Node:AddChild(name, obj, zorder)
    if name then
        self[name] = obj
    end
    return self:addChild(obj, zorder or 0)
end

function cc.Node:IsValid()
    return tolua_is_obj(self)
end

function cc.Node.IsInstance(cls)
    return tolua_is_instance(self, cls)
end

function cc.Node:ConvertToWorldSpace(sx, sy)
    return self:convertToWorldSpace(self:CalcPos(sx, sy))
end

-- 节点是否可视，会追溯向上判断所有父节点
function cc.Node:IsVisible()
    if not self:IsAttrVisible() then return false end
    local parent = self:getParent()
    while parent do
        if parent:CanCastTo(cc.ScrollView) then
            if not parent:IsNodeVisible(self) then
                return false
            end
        end
        parent = parent:getParent()
    end
       
    return true
end

function cc.Node:IsAttrVisible()
    if not self:isVisible() then
        return false
    end

    local parent = self:getParent()
    while parent do
        if not parent:isVisible() then
            return false
        end
        parent = parent:getParent()
    end
    return true
end

-- 判断能否向上类型转换
function cc.Node:CanCastTo(class)
    return tolua_is_instance(self, class)
end

-- 向上转型
function cc.Node:CastTo(class)
    assert(tolua_is_subclass(getmetatable(self), class))
    debug.setmetatable(self, getmetatable(class))
    return self
end

function cc.Node:GetClassName()
    return tolua_get_class_name(self)
end

-- runAction 延迟一段时间触发的定时器，只触发一次
function cc.Node:SetTimeOut(delay_second, func)
    local act = cc.Sequence:create(
        cc.DelayTime:create(delay_second),
        cc.CallFunc:create(func)
    )

    self:runAction(act)
    return act
end

-- runAction 延迟一段时间触发的定时器，会指定Tag标识
function cc.Node:SetTimeOutWithTag(delay_second, tag, func)
    local act = self:SetTimeOut(delay_second, func)
    act:setTag(tag)
    return act
end

-- runAction DelayCall
function cc.Node:DelayCall(delay, func)
    local function on_timer()
        if func == nil then return end

        local next_delay = func()
        
        if next_delay then
            self:SetTimeOut(next_delay, on_timer)
        end
    end
    self:SetTimeOut(delay, on_timer)
    
    --返回一个函数用户控制当前 timer stop
    return function() func = nil end
end

--runAction DelayCallWithTag
function cc.Node:DelayCallWithTag(delay, tag, func)
    local function on_timer()
        local next_delay = func()
        if next_delay then
            self:SetTimeOutWithTag(next_delay, tag, on_timer)
        end
    end

    self:stopActionByTag(tag)
    self:SetTimeOutWithTag(delay, tag, on_timer)
end

function cc.Node:SetTouchEnabledRecursion(bEnable)
    if self:CanCastTo(cc.Layer) then
        self:setTouchEnabled(bEnable)
    end

    for _, child in ipairs(self:getChildren()) do
        if child:IsScriptsNode() then
            child:SetTouchEnabledRecursion(bEnable)
        end
    end
end

function cc.Node:SetSwallowTouchRecursion(bSwallowTouch)
    if self:CanCastTo(cc.Layer) then
        self:setSwallowsTouches(bSwallowTouch)
    end

    for _, child in ipairs(self:getChildren()) do
        if child:IsScriptsNode() then
            child:SetSwallowTouchRecursion(bSwallowTouch)
        end
    end
end

function cc.Node:SetClipObjectRecursion(clip_object)
    self:SetClipObject(clip_object)
    
    for _, child in ipairs(self:getChildren()) do
        if child:IsScriptsNode() then
            child:SetClipObjectRecursion(clip_object)
        end
    end
end

function cc.Node:SetClipLayerObjectRecursion(clip_object)
    if self:CanCastTo(cc.Layer) then
        self:SetClipObject(clip_object)
    end

    for _, child in ipairs(self:getChildren()) do
        if child:IsScriptsNode() then
            child:SetClipLayerObjectRecursion(clip_object)
        end
    end
end

function cc.Node:SetNoEventAfterMoveRecursion(flag, move_dist)
    if self:CanCastTo(cc.Layer) then
        self:SetNoEventAfterMove(flag, move_dist)
    end

    for _, child in ipairs(self:getChildren()) do
        if child:IsScriptsNode() then
            child:SetNoEventAfterMoveRecursion(flag, move_dist)
        end
    end
end

function cc.Node:SetEnableCascadeOpacityRecursion(bEnable)
    self:setCascadeOpacityEnabled(bEnable)
    for _, child in ipairs(self:getChildren()) do
        child:SetEnableCascadeOpacityRecursion(bEnable)
    end
end

function cc.Node:SetEnableCascadeColorRecursion(bEnable)
    self:setCascadeColorEnabled(bEnable)
    for _, child in ipairs(self:getChildren()) do
        child:SetEnableCascadeColorRecursion(bEnable)
    end
end

function cc.Node:SetAnimationConf(aniConf)
    self._aniConf = aniConf
end

function cc.Node:PlayAnimation(aniName)
    local aniConf = self._aniConf

    if aniConf == nil or aniConf[aniName] == nil then
        printf('PlayAnimation failed [%s] [%s]:%s', self:GetClassName(), aniName, str(aniConf), debug.traceback())
        return
    end

    for _, aniInfo in ipairs(aniConf[aniName]) do
        g_uisystem.gen_action_and_run(aniInfo[1], aniInfo[2])
    end
end

function cc.Node:PlayAction(actionName, customizeInfo)
    for aniName, aniInfos in pairs(self._aniConf or {}) do
        for _, aniInfo in ipairs(aniInfos) do
            for _, ani_path in ipairs(aniInfo[2] or {}) do
                if ani_path == actionName then
                    g_uisystem.gen_action_and_run(aniInfo[1], {ani_path}, customizeInfo)
                    return
                end
            end
        end
    end
end

function cc.Node:GetRootScene()
    local cur = self
    while cur do
        if cur:CanCastTo(cc.Scene) then
            return cur:CastTo(cc.Scene)
        else
            cur = cur:getParent()
        end
    end
end

-- 设置位置，根据父节点空间矩形
function cc.Node:SetPositonByRect(rect)
    local anchor = self:isIgnoreAnchorPointForPosition() and ccp(0,0) or self:getAnchorPoint()
    self:setPosition(rect.x + rect.width * anchor.x, rect.y + rect.height * anchor.y)
end

-- 获取在父节点坐标系的矩形区域
function cc.Node:GetBoundingBox()
    local w, h = self:GetContentSize()
    local mat = self:getNodeToParentTransform()
    local p1 = mat4_transformVector(mat, cc.vec4(0, 0, 0, 1))
    local p2 = mat4_transformVector(mat, cc.vec4(0, h, 0, 1))
    local p3 = mat4_transformVector(mat, cc.vec4(w, 0, 0, 1))
    local p4 = mat4_transformVector(mat, cc.vec4(w, h, 0, 1))

    local minx = math.min(p1.x, p2.x, p3.x, p4.x)
    local maxx = math.max(p1.x, p2.x, p3.x, p4.x)
    local miny = math.min(p1.y, p2.y, p3.y, p4.y)
    local maxy = math.max(p1.y, p2.y, p3.y, p4.y)
    return CCRect(minx, miny, maxx - minx, maxy - miny)
end

-- 设置左边坐标
function cc.Node:SetLeftPosition(x)
    local box = self:GetBoundingBox()
    box.x = x
    self:SetPositonByRect(box)
end

-- 设置右边坐标
function cc.Node:SetRightPosition(x)
    local box = self:GetBoundingBox()
    box.x = x - box.width
    self:SetPositonByRect(box)
end

-- 设置上边坐标
function cc.Node:SetTopPosition(y)
    local box = self:GetBoundingBox()
    box.y = y - box.height
    self:SetPositonByRect(box)
end

function cc.Node:SetBottomPosition(y)
    local box = self:GetBoundingBox()
    box.y = y
    self:SetPositonByRect(box)
end

function cc.Node:SetXCenterPosition(x)
    local box = self:GetBoundingBox()
    box.x = x - (box.width / 2)
    self:SetPositonByRect(box)
end

function cc.Node:SetYCenterPosition(y)
    local box = self:GetBoundingBox()
    box.y = y - (box.height / 2)
    self:SetPositonByRect(box)
end

function cc.Node:GetLeftBottomPosition()
    local box = self:GetBoundingBox()
    return box.x, box.y
end

function cc.Node:GetRightTopPosition()
    local box = self:GetBoundingBox()
    return box.x + box.width, box.y + box.height
end

function cc.Node:GetMinMaxWorldPosition()
    local w, h = self:GetPosition()
    local p1 = self:convertToWorldSpace(ccp(0, 0))
    local p2 = self:convertToWorldSpace(ccp(w, h))

    return math.min(p1.x, p2.x), math.min(p1.y, p2.y), math.max(p1.x, p2.x), math.max(p1.y, p2.y)
end

function cc.Node:GetTotalScale()
    local s = self:getScale()
    local p = self:getParent()
    while p do
        s = s * p:getScale()
        p = p:getParent()
    end
    return s
end

function cc.Node:EnableGrayEffect()
end

function cc.Node:SetEnableCascadeGrayEffect()
    self:EnableGrayEffect()
    for _, child in ipairs(self:getChildren()) do
        child:SetEnableCascadeGrayEffect()
    end
end


function cc.Node:DisableExtEffect()
end

function cc.Node:SetDisableExtCascadeEffect()
    self:DisableExtEffect()
    for _, child in ipairs(self:getChildren()) do
        child:SetDisableExtCascadeEffect()
    end
end

-- override
function cc.Layer:_init()
    tolua_super(cc.Layer)._init(self)
    self._bNoEventAfterMove = nil  -- 是否按下去移动一段位移就取消回调触摸事件
    self._nNoEventMoveDist = 0     -- 取消触摸事件的移动位移
    self._bForceHandleTouch = false  -- 不管节点的大小直接拥有touch属性
    self._bSwallowTouch = false

    self._touchListener = nil
    self._multiTouchListener = nil

    return self
end

-- override
function cc.Layer:_registerInnerEvent()
    tolua_super(cc.Layer)._registerInnerEvent(self)
    self:_regInnerEvent('OnBegin')
    self:_regInnerEvent('OnDrag')
    self:_regInnerEvent('OnEnd')
    self:_regInnerEvent('OnClick')
    self:_regInnerEvent('OnUpOutside')
    self:_regInnerEvent('OnCancel')
end

-- override c++
function cc.Layer:setTouchEnabled(bEnable)
    if bEnable and self._touchListener == nil then
        local function OnTouchCancel(pos)
            -- print('OnTouchCancel', pos)
            self.eventHandler:Trigger('OnCancel', pos)
        end
        
        local prePos
        local nMovedDist  -- 按下去移动的位移
        local function OnTouchBegan(pos)
            -- print('OnTouchBegan', pos)
            nMovedDist = 0
            if self:IsVisible() and (self._bForceHandleTouch or self:IsPointIn(pos)) then
                local result = self.eventHandler:Trigger('OnBegin', pos)
                prePos = pos

                --_regInnerEvent 默认增加了一个回调
                return result[result.__count__]
            else
                return false
            end
        end

        local function OnTouchMove(pos)
            -- print('OnTouchMove', pos)
            nMovedDist = nMovedDist + cc.pGetLength(cc.pSub(pos, prePos))
            prePos = pos
            if self._bNoEventAfterMove and nMovedDist > self._nNoEventMoveDist then
                self:setTouchEnabled(false)
                self:setTouchEnabled(true)
                OnTouchCancel(pos)
                return
            end
            
            self.eventHandler:Trigger('OnDrag', pos)
        end

        local function OnTouchEnd(pos)
            -- print('OnTouchEnd', str(pos))
            self.eventHandler:Trigger('OnEnd', pos) -- self may be destroyed
            if self:IsPointIn(pos) then
                self.eventHandler:Trigger('OnClick', pos)
            else
                self.eventHandler:Trigger('OnUpOutside', pos)
            end
        end

        local touchOneByOneListener = cc.EventListenerTouchOneByOne:create()
        touchOneByOneListener:registerScriptHandler(function(touch)
            return OnTouchBegan(touch:getLocation())
        end, cc.Handler.EVENT_TOUCH_BEGAN)
        touchOneByOneListener:registerScriptHandler(function(touch)
            OnTouchMove(touch:getLocation())
        end, cc.Handler.EVENT_TOUCH_MOVED)
        touchOneByOneListener:registerScriptHandler(function(touch)
            OnTouchEnd(touch:getLocation())
        end, cc.Handler.EVENT_TOUCH_ENDED)
        touchOneByOneListener:registerScriptHandler(function(touch)
            OnTouchCancel(touch:getLocation())
        end, cc.Handler.EVENT_TOUCH_CANCELLED)

        touchOneByOneListener:setSwallowTouches(self._bSwallowTouch)

        self:getEventDispatcher():addEventListenerWithSceneGraphPriority(touchOneByOneListener, self)

        self._touchListener = touchOneByOneListener
    elseif not bEnable and self._touchListener then
        self:getEventDispatcher():removeEventListener(self._touchListener)
        self._touchListener = nil
    end
end

-- override c++
function cc.Layer:isTouchEnabled()
    return self._touchListener ~= nil
end

-- override c++
function cc.Layer:setSwallowsTouches(bEnable)
    self._bSwallowTouch = bEnable
    if self._touchListener then
        self._touchListener:setSwallowTouches(bEnable)
    end
end

-- override c++
function cc.Layer:isSwallowsTouches()
    return self._bSwallowTouch
end

function cc.Layer:HandleMultiTouches()
    if self._multiTouchListener then
        return
    end
    self:setTouchEnabled(false)
    self:_regInnerEvent('OnTouchesBegan')
    self:_regInnerEvent('OnTouchesMoved')
    self:_regInnerEvent('OnTouchesEnded')
    self:_regInnerEvent('OnTouchesCancel')
    
    self.touches = {}
    local function OnTouchBegan(touch)
        local pos = touch:getLocation()
        if self:IsVisible() and (self._bForceHandleTouch or self:IsPointIn(pos)) then
            table.insert(self.touches,touch)
            local result = self.eventHandler:Trigger('OnTouchesBegan', self.touches)
            return result[result.__count__]
        else
            return false
        end
    end

    local function OnTouchMove(touch)
        self.eventHandler:Trigger('OnTouchesMoved', self.touches)
    end

    local function OnTouchEnd(touch)
        for index,curTouch in ipairs(self.touches) do
            if touch == curTouch then
               table.remove(self.touches,index)
               break
            end
        end
        self.eventHandler:Trigger('OnTouchesEnded', self.touches) 
    end
    
    local function OnTouchCancel(touch)
        for index,curTouch in ipairs(self.touches) do
            if touch == curTouch then
               table.remove(self.touches,index)
               break
            end
        end
        self.eventHandler:Trigger('OnTouchesCancel', self.touches) 
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(function(touch)
        return OnTouchBegan(touch)
    end, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(function(touch)
        OnTouchMove(touch)
    end, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(function(touch)
        OnTouchEnd(touch)
    end, cc.Handler.EVENT_TOUCH_ENDED)
    listener:registerScriptHandler(function(touch)
        OnTouchCancel(touch)
    end, cc.Handler.EVENT_TOUCH_CANCELLED)
    listener:setSwallowTouches(self._bSwallowTouch)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)
    self._multiTouchListener = listener
end

function cc.Layer:HandleTouchMove(bEnable, bSwallow, bNoEventAfterMove, move_dist, bForceHandleTouch)
    self:setTouchEnabled(bEnable)
    self:setSwallowsTouches(bSwallow)
    self:SetNoEventAfterMove(bNoEventAfterMove, move_dist)
    self:SetForceHandleTouch(bForceHandleTouch)
end

-- 不受点击区域的限制产生触摸事件
function cc.Layer:SetForceHandleTouch(bForceHandleTouch)
    self._bForceHandleTouch = bForceHandleTouch
end

function cc.Layer:SetNoEventAfterMove(flag, move_dist)
    self._bNoEventAfterMove = flag
    self._nNoEventMoveDist = ccext_get_scale(move_dist or 0)
end

function cc.Layer:HandleDoubleClickEvent(interval)
    self:_regInnerEvent('OnDoubleClick')

    if interval == nil then
        interval = config_double_click_default_interval
    end

    local scheduleFlag
    self.newHandler.OnClick = function(pt)
        if scheduleFlag then
            scheduleFlag = nil
            self.eventHandler:Trigger('OnDoubleClick', pt)
        else
            scheduleFlag = true
            self:DelayCallWithTag(interval, config_double_click_schedule_flag, function()
                scheduleFlag = nil
            end)
        end
    end
end

-- override
function cc.ScrollView:_registerInnerEvent()
    tolua_super(cc.ScrollView)._registerInnerEvent(self)
    self:_regInnerEvent('OnScroll')
    self:_regInnerEvent('OnScrollH')
    self:_regInnerEvent('OnScrollLeft')
    self:_regInnerEvent('OnScrollRight')
    self:_regInnerEvent('OnScrollV')
    self:_regInnerEvent('OnScrollUp')
    self:_regInnerEvent('OnScrollDown')
    self:_regInnerEvent('OnZoom')
end

function cc.ScrollView:HandleScrollEvent()
    local function scrollViewDidScroll()
        self.eventHandler:Trigger('OnScroll', self)
    end
    self:setDelegate()
    self:registerScriptHandler(scrollViewDidScroll, cc.SCROLLVIEW_SCRIPT_SCROLL)
end

function cc.ScrollView:HandleHorzScrollEvent()
    self.newHandler.OnScroll = function()
        self.__viewSize = self.__viewSize or self:getViewSize()
        self.__contentSize = self.__contentSize or self:getContentSize()
        local offset = self:getContentOffset()
        if offset.x >= 0 then
            if not self.__scrolll then
                self.__scrolll = true
                self.eventHandler:Trigger('OnScrollLeft', self)
                -- print('OnScrollLeft')
            end
        elseif self.__contentSize.width + offset.x <= self.__viewSize.width then
            if not self.__scrollr then
                self.__scrollr = true
                self.eventHandler:Trigger('OnScrollRight', self)
                -- print('OnScrollRight')
            end
        else
            self.__scrolll = nil
            self.__scrollr = nil
            self.eventHandler:Trigger('OnScrollH', self)
        end
    end
end

function cc.ScrollView:HandleVertScrollEvent()
    self.newHandler.OnScroll = function()
        self.__viewSize = self.__viewSize or self:getViewSize()
        self.__contentSize = self.__contentSize or self:getContentSize()
        local offset = self:getContentOffset()
        if offset.y >= 0 then
            if not self.__scrolld then
                self.__scrolld = true
                self.eventHandler:Trigger('OnScrollDown', self)
                -- print('OnScrollDown')
            end
        elseif self.__contentSize.height + offset.y <= self.__viewSize.height then
            if not self.__scrollt then
                self.__scrollt = true
                self.eventHandler:Trigger('OnScrollUp', self)
                -- print('OnScrollUp')
            end
        else
            self.__scrolld = nil
            self.__scrollt = nil
            self.eventHandler:Trigger('OnScrollV', self)
        end
    end
end

function cc.ScrollView:HandleZoomEvent()
    local function scrollViewDidZoom()
        self.eventHandler:Trigger('OnZoom', self)
    end
    self:registerScriptHandler(scrollViewDidZoom,cc.SCROLLVIEW_SCRIPT_ZOOM)
end

function cc.ScrollView:_set_up_ctrl(ctrl)
    ctrl:SetClipObjectRecursion(self)
end

function cc.ScrollView:SetContainer(container)
    self:setContainer(container)
    self:_set_up_ctrl(container)
    self:ResetContentOffset()
end

-- override
function cc.ScrollView:SetContentSize(sw, sh)
    local sz = self:CalcSize(sw, sh)
    self:setViewSize(sz)
    return sz
end

-- override
function cc.ScrollView:GetContentSize()
    local size = self:getViewSize()
    return size.width, size.height
end

function cc.ScrollView:ScrollToTop(duration)
    local offset = self:getContentOffset()
    local minOffset = self:minContainerOffset()
    if duration then
        self:setContentOffsetInDuration(ccp(offset.x, minOffset.y), duration)
    else
        self:setContentOffset(ccp(offset.x, minOffset.y))
    end
end

function cc.ScrollView:ScrollToBottom(duration)
    local offset = self:getContentOffset()
    if duration then
        self:setContentOffsetInDuration(ccp(offset.x, 0), duration)
    else
        self:setContentOffset(ccp(offset.x, 0))
    end
end

function cc.ScrollView:ScrollToLeft(duration)
    local offset = self:getContentOffset()
    if duration then
        self:setContentOffsetInDuration(ccp(0, offset.y), duration)
    else
        self:setContentOffset(ccp(0, offset.y))
    end
end

function cc.ScrollView:ScrollToRight(duration)
    local offset = self:getContentOffset()
    local minOffset = self:minContainerOffset()
    if duration then
        self:setContentOffsetInDuration(ccp(minOffset.x, offset.y), duration)
    else
        self:setContentOffset(ccp(minOffset.x, offset.y))
    end
end

--根据当前container的偏移值重新移动到边界处
function cc.ScrollView:ResetContentOffset(duration)
    local minOffset = self:minContainerOffset()
    local curPos = self:getContentOffset()
    local x = math.min(math.max(minOffset.x, curPos.x), 0)
    local y = math.min(math.max(minOffset.y, curPos.y), 0)
    if duration then
        self:setContentOffsetInDuration(ccp(x, y), duration)
    else
        self:setContentOffset(ccp(x, y))
    end
end

function cc.ScrollView:CenterWithPos(x, y, duration)
    local viewSize = self:getViewSize()
    local contentSize = self:getContentSize()
    local scale = self:getZoomScale()

    local max_off_x = contentSize.width  * scale - viewSize.width
    local max_off_y = contentSize.height * scale - viewSize.height

    local x_off = -math.min(math.max((x * scale - viewSize.width / 2), 0), max_off_x)
    local y_off = -math.min(math.max((y * scale - viewSize.height / 2), 0), max_off_y)

    local dest = ccp(x_off, y_off)
    if duration then
        self:setContentOffsetInDuration(dest, duration)
    else
        self:setContentOffset(dest)
    end
end

function cc.ScrollView:CenterWithNode(node, duration)
    local w, h = node:GetContentSize()
    local worldPos = node:convertToWorldSpace(ccp(w / 2, h / 2))
    local scrolPos = self:getContainer():convertToNodeSpace(worldPos)
    self:CenterWithPos(scrolPos.x, scrolPos.y, duration)
end

-- @desc:
--  该函数能够检测所有的节点
--     selfRect : 如果使用外部提供的selfRect，这个rect的坐标系需要为世界坐标
--  scrollview 缩放不要为负数不然有问题
function cc.ScrollView:IsNodeVisible(node, selfRect)
    local lb = node:convertToWorldSpace(ccp(0, 0))
    local rt = node:convertToWorldSpace(ccp(node:GetContentSize()))
    
    if not selfRect then
        local selfLB = self:convertToWorldSpace(ccp(0, 0))
        local selfRT = self:convertToWorldSpace(ccp(self:GetContentSize()))
        selfRect = CCRect(selfLB.x, selfLB.y, selfRT.x - selfLB.x, selfRT.y - selfLB.y)
    end
    return cc.rectIntersectsRect(selfRect, CCRect(lb.x, lb.y, rt.x - lb.x, rt.y - lb.y))
end

--绑定scrollArrows进度指示器返回回调ui回调用于手动删除回调
function cc.ScrollView:BindPageArrows(page_arrows)
    local function OnScrolled()
        local minOffset = self:minContainerOffset()
        local offset = self:getContentOffset()

        local down = page_arrows['down']
        if tolua_is_obj(down) then down:setVisible(offset.y < 0) end

        local up = page_arrows['up']
        if tolua_is_obj(up)then up:setVisible(offset.y > minOffset.y) end

        local left = page_arrows['left']
        if tolua_is_obj(left)then left:setVisible(offset.x < 0) end

        local right = page_arrows['right']
        if tolua_is_obj(right)then right:setVisible(offset.x > minOffset.x) end
    end
    self.newHandler.OnScrolled = OnScrolled
    OnScrolled()
    return function()
        self.eventHandler:RemoveCallback('OnScrolled', OnScrolled)
    end
end

--绑定scrollpointer进度指示器返回回调ui回调用于手动删除回调
function cc.ScrollView:BindScrollPointer(sliderBar)
    local function OnScroll()
        local minOffset = self:minContainerOffset()
        local offset = self:getContentOffset()
        if sliderBar:IsVertical() then
            sliderBar:SetPercentage(offset.y / minOffset.y * 100)
        else
            sliderBar:SetPercentage(offset.x / minOffset.x * 100)
        end
    end
    OnScroll(self)
    self.newHandler.OnScroll = OnScroll
    return function()
        self.eventHandler:RemoveCallback('OnScroll', OnScroll)
    end
end

function cc.ScrollView:EnableMouseWheelAndScroll(bHorz)
    self:HandleMouseEvent()
    self.newHandler.OnMouseWheel = function(scrollValue)
        local offset = self:getContentOffset()
        local distance = scrollValue * (scrollRate or constant_uisystem.default_mouse_scroll_rate)
        if bHorz then
            self:setContentOffset(ccp(offset.x + distance, offset.y))
        else
            self:setContentOffset(ccp(offset.x , offset.y - distance))
        end
        self:ResetContentOffset()
    end
end

-- @desc:
-- if font == '' then use sys font else use ttf font
-- override static
function cc.Label:Create(text, font, fontSize, szDemensions, hAlign, vAlign)
    if text == nil then
        text = ''
    else
        text = GetTextByLanguageI(text)    
    end

    if font == nil then
        font = ''
    end

    if fontSize == nil then
        fontSize = 25
    end

    if szDemensions == nil then
        szDemensions = CCSize(0, 0)
    end

    if hAlign == nil then
        hAlign = cc.TEXT_ALIGNMENT_LEFT
    end

    if vAlign == nil then
        vAlign = cc.VERTICAL_TEXT_ALIGNMENT_TOP
    end

    local self

    if font == '' then
        self = cc.Label:createWithSystemFont(text, '', fontSize, szDemensions, hAlign, vAlign)
        self._labelType = LabelType.STRING_TEXTURE
    else
        self = cc.Label:createWithTTF(luaext_fribidi_convert(text), font, fontSize, szDemensions, hAlign, vAlign)
        self._labelType = LabelType.TTF
    end

    self._text = text
    self._fontName = font
    self:_init()
    return self
end

function cc.Label:CreateWithCharMap(fntFile)
    local self = cc.Label:createWithCharMap(fntFile)
    if self then
        self:_init()
        self._labelType = LabelType.CHARMAP
    else
        self = cc.Label:Create()
    end

    return self
end

-- createWithBMFont(const std::string& bmfontFilePath, const std::string& text,const TextHAlignment& hAlignment /* = TextHAlignment::LEFT */, int maxLineWidth /* = 0 */, const Vec2& imageOffset /* = Vec2::ZERO */)
function cc.Label:CreateWithBMFont(...)
    local self = cc.Label:createWithBMFont(...):_init()
    self._labelType = LabelType.BMFONT
    return self
end

function cc.Label:SetFontSize(size)
    if self._labelType == LabelType.STRING_TEXTURE then
        self:setSystemFontSize(size)
    elseif self._labelType == LabelType.TTF then
        local ttfConfig  = {}
        ttfConfig.fontFilePath = self._fontName
        ttfConfig.fontSize = size
        self:setTTFConfig(ttfConfig)
    end
end

function cc.Label:SetString(...)
    local text = GetTextByLanguageI(...)
    if self._text == text then
        return text
    end

    self._text = text
    if self._labelType == LabelType.TTF then
        self:setString(luaext_fribidi_convert(text))
    else
        self:setString(text)
    end
    return text
end

-- override c++
function cc.Label:getString()
    return self._text
end

cc.Label.GetString = cc.Label.getString

-- override static
function cc.Sprite:Create(plist, path)
    if tolua_is_obj(plist) then
        if tolua_is_instance(plist, cc.SpriteFrame) then
            return cc.Sprite:createWithSpriteFrame(plist)
        else
            return cc.Sprite:create()
        end
    else
        local frame = get_sprite_frame(path, plist)
        if frame then
            return cc.Sprite:createWithSpriteFrame(frame)
        else
            return cc.Sprite:create()
        end
    end
end

-- 如果设置的是 url path 则第三个参数为 placeHolderPath or bAsync
function cc.Sprite:SetPath(plist, path, placeHolderPath)
    if plist == '' and path == '' or path == nil then
        -- 设空
        self._loadingPath = nil
        self:setSpriteFrame(get_sprite_frame(constant_uisystem.default_transparent_img_path))
    elseif string.sub(path, 1, 4) == 'http' then
        self:SetUrlPath(path, placeHolderPath)
    else
        local bAsync = placeHolderPath
        if bAsync and plist == nil then
            self._loadingPath = path
            utils_add_image_async(path, function(tex)
                if self:IsValid() and self._loadingPath == path then
                    self:setSpriteFrame(get_sprite_frame_safe(path, plist))
                end
            end)
        else
            self._loadingPath = nil
            self:setSpriteFrame(get_sprite_frame_safe(path, plist))
        end
    end
end

-- 设置 url icon
local _iconUrlPath = g_fileUtils:getWritablePath() .. 'icon_url/'
if not g_fileUtils:isDirectoryExist(_iconUrlPath) then
    g_fileUtils:createDirectory(_iconUrlPath)
end

function cc.Sprite:SetUrlPath(path, placeHolderPath, resultCallback)
    local filePath = _iconUrlPath .. luaext_hash_str(path)
    if is_valid_str(placeHolderPath) then
        self:SetPath(nil, placeHolderPath)
    end

    local spriteFrame = get_sprite_frame(filePath)
    if spriteFrame then
        self._loadingPath = nil
        self:setSpriteFrame(spriteFrame)
        if resultCallback then
            resultCallback(true)
        end
    else
        if g_fileUtils:isFileExist(filePath) then
            printf('[%s] url image file [%s] not valid', path, filePath)
        end
        self._loadingPath = path

        utils_download_url_file(path, filePath, function(eventType)
            if eventType == cc.EXT_DOWNLOAD_STATUS.STATUS_SUCCEED and self:IsValid() and self._loadingPath == path then
                self:SetPath(nil, filePath)
                if resultCallback then
                    resultCallback(true)
                end
            elseif eventType == cc.EXT_DOWNLOAD_STATUS.ERROR then
                if resultCallback then
                    resultCallback(false)
                end
            end
        end, nil, true)
    end
end

function cc.Sprite:EnableGrayEffect()
    if not cc_utils_is_support_sprite_ext_effect() then
        return
    end

    if self._isGray then
        return
    end
    self._isGray = true
    self:setGLProgramState(cc.GLProgramState:getOrCreateWithGLProgramName(cc.SHADER_UI_GRAY_SCALE))
end

--只用于截屏的时候，不要乱调用
function cc.Sprite:EnableBlurEffect(blurRadius, resolution, sampleNum)
    if not cc_utils_is_support_sprite_ext_effect() then
        return
    end
    if self._isBlur == true then
        return
    end
    self._isBlur = true

    local program = cc_utils_add_program('shader/ccShader_PositionTextureColor_noMVP.vert', 'shader/ccShader_Blur.frag', cc.SHADER_POSITION_TEXTURE_COLOR_NO_MVP_BLUR)
    if not program then
        return
    end
    if not resolution then
        resolution = ccp(self:GetContentSize())
    end
    if not blurRadius then
        blurRadius = 5
    end

    if not sampleNum then
        sampleNum = 10
    end

    local glprogramstate = cc.GLProgramState:getOrCreateWithGLProgramName(cc.SHADER_POSITION_TEXTURE_COLOR_NO_MVP_BLUR)
    local unirformLocation = gl._getUniformLocation(program:getProgram(), 'resolution')
    glprogramstate:setUniformVec2(unirformLocation, resolution)
    unirformLocation = gl._getUniformLocation(program:getProgram(), 'blurRadius')
    glprogramstate:setUniformFloat(unirformLocation, blurRadius)
    unirformLocation = gl._getUniformLocation(program:getProgram(), 'sampleNum')
    glprogramstate:setUniformFloat(unirformLocation, sampleNum)
    self:setGLProgramState(glprogramstate)
end

function cc.Sprite:DisableExtEffect()
    if not cc_utils_is_support_sprite_ext_effect() then
        return
    end

    if not self._isBlur and not self._isGray then
        return
    end

    self._isBlur = false
    self._isGray = false
    self:setGLProgramState(cc.GLProgramState:getOrCreateWithGLProgramName(cc.SHADER_POSITION_TEXTURE_COLOR_NO_MVP))
end


function cc.ProgressTimer:Create(plist, path)
    return cc.ProgressTimer:create(cc.Sprite:Create(plist, path)):_init()
end

function cc.ClippingNode:SetStencil(stencileNode)
    self:setStencil(stencileNode)
    self:setContentSize(stencileNode:getContentSize())
    stencileNode:setAnchorPoint(ccp(0, 0))
end


-- override
function ccui.EditBox:_registerInnerEvent()
    tolua_super(ccui.EditBox)._registerInnerEvent(self)

    self:_regInnerEvent('OnEditBegan')
    self:_regInnerEvent('OnEditEnded')
    self:_regInnerEvent('OnEditChanged')
    self:_regInnerEvent('OnEditReturn')
    self:_handleEditEvent()
end

--取消注册：unregisterScriptEditBoxHandler
function ccui.EditBox:_handleEditEvent()
    local function editBoxTextEventHandle(strEventName, pSender)
        local text = self:getText()
        if strEventName == "began" then
            self.eventHandler:Trigger('OnEditBegan', text)
        elseif strEventName == "ended" then
            self.eventHandler:Trigger('OnEditEnded', text)
        elseif strEventName == "return" then
            self.eventHandler:Trigger('OnEditReturn', text)
        elseif strEventName == "changed" then
            self.eventHandler:Trigger('OnEditChanged', text)
        end
    end
    self:registerScriptEditBoxHandler(editBoxTextEventHandle)
end

function ccui.EditBox:SetText(...)
    local ret = GetTextByLanguageI(...)
    self:setText(ret)
    return ret
end

ccui.EditBox.SetString = ccui.EditBox.SetText

function ccui.EditBox:SetPlaceHolder(...)
    self:setPlaceHolder(GetTextByLanguageI(...))
end


if g_application:getTargetPlatform() ~= cc.PLATFORM_OS_WINDOWS then
    function ccexp.WebView:Create(scale_page, url)
        local obj = ccexp.WebView:create()
        obj:setScalesPageToFit(scale_page)
        if url ~= nil and string.len(url) > 0 then
            obj:loadURL(url)
        end
        return obj
    end
end



---------------------------------------------------------------- extensions
-- basic nodes
tolua_new_class("CCButton", 'cc.Layer')
import('ui.button')

tolua_new_class("CCCheckButton", 'CCButton')
import('ui.check_button')

tolua_new_class('CCAnimateSprite', 'cc.Sprite')
import('ui.animate')

tolua_new_class("CCEditBoxExt", 'cc.ScrollView')
import('ui.editbox')

import('ui.rich_label')

-- container
tolua_new_class('TemplateNode', 'cc.Node')
import('ui.template_node')

tolua_new_class('CCContainer', 'cc.Node')
tolua_new_class("AsyncContainer", 'CCContainer')
import('ui.container')

tolua_new_class('SCrollList', 'cc.ScrollView')
tolua_new_class("AsyncList", 'SCrollList')
import('ui.template_list')

tolua_new_class("SCrollPage", 'SCrollList')
import('ui.scroll_page')

-- ext
tolua_new_class('CCCombobox', 'cc.Layer')
import('ui.combobox')

tolua_new_class('CCTreeView', 'cc.ScrollView')
import('ui.tree_view')

tolua_new_class('CCSlider', 'cc.Layer')
import('ui.slider')

tolua_new_class('CCLoadingBar', 'cc.Node')
import('ui.loadingbar')

if cc.Live2DSprite then
    import('ui.live2dsprite')
end

local CCRectangle = tolua_new_class('CCRectangle', 'cc.DrawNode')

-- override
function CCRectangle:Create(line_weight, line_color)
    return cc.DrawNode:create():CastTo(self):_init(line_weight, line_color)
end

-- override
function CCRectangle:_init(line_weight, line_color)
    self._color = line_color + 0xff000000
    self:setLineWidth(line_weight)
    return self
end

-- override
function CCRectangle:SetContentSize(sw, sh)
    local sz = self:CalcSize(sw, sh)

    self:setContentSize(sz)
    self:clear()
    self:drawRect(ccp(0, 0), ccp(sz.width, sz.height), ccc4fFromHex(self._color))

    return sz
end

function CCRectangle:SetLineColor(color)
    -- self._color = color
end





---------------------------------------------------------------- content size read only
cc_utils_SetContentSizeReadOnly(cc.Label)
cc_utils_SetContentSizeReadOnly(cc.RichLabel)
cc_utils_SetContentSizeReadOnly(cc.ProgressTimer)
cc_utils_SetContentSizeReadOnly(cc.ParticleSystemQuad)
cc_utils_SetContentSizeReadOnly(cc.ClippingNode)
cc_utils_SetContentSizeReadOnly(ccui.EditBox)
cc_utils_SetContentSizeReadOnly(cc.CCAnimateSprite)
cc_utils_SetContentSizeReadOnly(cc.CCContainer)
