--[[====================================
=
=           cocos 扩展
=
========================================]]

function g_fileUtils:CreateDirectoryIfNotExist(dir)
    if self:isDirectoryExist(dir) then
        return true
    else
        self:createDirectory(dir)
        return self:isDirectoryExist(dir)
    end
end

function g_fileUtils:ListFiles(dir)
    dir = string.gsub(dir, '\\', '/')
    if string.sub(dir, -1) ~= '/' then
        dir = dir .. '/'
    end

    local ret = {}
    local startIndex = #dir + 1
    for _, path in ipairs(self:listFiles(dir)) do
        local isDir = string.sub(path, -1) == '/'
        local name = string.sub(path, startIndex, isDir and -2 or -1)
        if name ~= '.' and name ~= '..' then
            table.insert(ret, {
                path = path,
                name = name,
                is_dir = isDir,
                is_file = not isDir,
            })
        end
    end

    return ret
end

function g_fileUtils:CopyFile(srcFilePath, destFilePath)
    local f = io.open(srcFilePath, 'rb')
    if f == nil then
        return
    end

    local content = f:read('*a')
    f:close()

    f = io.open(destFilePath, 'wb')
    if f == nil then
        return
    end

    f:write(content)
    f:close()

    return true
end

function g_fileUtils:SyncDir(srcDir, destDir, callback)
    if srcDir:sub(-1, -1) ~= '/' then
        srcDir = srcDir..'/'
    end

    if destDir:sub(-1, -1) ~= '/' then
        destDir = destDir..'/'
    end

    if not self:isDirectoryExist(srcDir) then
        return
    end

    if not self:CreateDirectoryIfNotExist(destDir) then
        return
    end

    for _, info in ipairs(self:ListFiles(srcDir)) do
        local fPath = srcDir..info.name
        local fDestPath = destDir..info.name
        if info.is_file then
            if not self:CopyFile(fPath, fDestPath) then
                return
            end

            if callback then
                callback(fPath, fDestPath)
            end
        elseif info.is_dir then
            if not self:SyncDir(fPath, fDestPath) then
                return
            end
        end
    end

    return true
end


local config_double_click_default_interval = 0.25
local config_double_click_schedule_flag = 10000

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
    self:_regInnerEvent('OnDropFile')
    g_ui_event_mgr.add_mouse_event(self)
end

-- pos & size
cc.Node.CalcSize = ccext_node_calc_size
cc.Node.CalcPos = ccext_node_calc_pos
cc.Node.SetContentSize = ccext_node_set_content_size  -- override
cc.Node.SetPosition = ccext_node_set_position
cc.Node.GetPosition = cc.Node.getPosition

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
    local morew = 0
    local moreh = 0
    if self._moreTouchContentScale ~= nil then
        morew = w * self._moreTouchContentScale.x
        moreh = h * self._moreTouchContentScale.y
    end
    return w + morew >= p.x and p.x >= 0 - morew and h + moreh >= p.y and p.y >= 0 - moreh
end

function cc.Node:SetMoreTouchScale(p)
    if type(p) == 'number' then
        p = ccp(p,p)
    end
    self._moreTouchContentScale = p
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

function cc.Node:ConvertToNodeSpace(sx, sy)
    local winSize = g_director:getWinSize()
    local x = ccext_calc_pos(sx, winSize.width, 1)
    local y = ccext_calc_pos(sy, winSize.height, 1)
    return self:convertToNodeSpace(ccp(x, y))
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
    elseif self:CanCastTo(cc.ScrollView) then
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

-- override c++
function cc.ScrollView:isInertiaEnable()
    return  self._inertiaListener ~= nil
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

--[[

    给scrollView绑定滚动条的接口, 参数为滚动条节点

    滚动条节点的结构如下的结构如下（必需节点）：
        * [scrollNode]CCNode (根节点，就是函数的第一个参数)
         * [_scroll_bg_] CCScale9Sprite (滚动条背景图)
         * [_scroll_sp_] CCScale9Sprite (滚动条前景图)
         * [_scroll_layer_] CCLayer (滚动条触摸层，需要给节点开启触摸，并设置成吞噬触摸。如果不希望能够触摸滚动就直接给节点取消触摸即可)

    特性：
        1.给scrollView绑定滚动条节点，当滑动scrollView时滚动条同步滚动，滑动滚动条的时候scrollView同步滚动。
        2.滚动条能滚动的高度，_scroll_sp_的大小，触摸层_scroll_layer_的大小都是以_scroll_bg_的大小为基础，默认都是以scrollNode为基础中间对齐
        3.当不希望滚动条有触摸滑动功能的时候可以把_scroll_layer_设置成隐藏的
        4.目前只支持水平和垂直方向的scrollView，当希望控制滚动条的位置和方向的时候只需要设置scrollNode的rotation和scale来控制
        5.scrollNode里面的那些子节点的anchor必须是(0.5, 0.5)
        
]]
function cc.ScrollView:BindScrollBar(scrollNode)
    --
    if not scrollNode._scroll_bg_ or not scrollNode._scroll_sp_ or not scrollNode._scroll_layer_ then
        print("the scrollNode should contains these items:_scroll_bg_, _scroll_sp_, _scroll_layer_")
        return
    end
    -- 判断scrollView的方向，只处理horizontal和vertical
    if self:getDirection() ~= cc.SCROLLVIEW_DIRECTION_HORIZONTAL and self:getDirection() ~= cc.SCROLLVIEW_DIRECTION_VERTICAL then
        print("only horizontal or vertical direction is supprorted")
        return
    end
    -- 初始化参数
    local isHideWhenStop = false
    local isHideWhenShort = true
    local isAdjustLayerWidth = true
    local hideWaitTime = 2
    local hideRunTime = 1
    --
    local scrollNodeBgSize = scrollNode._scroll_bg_:getContentSize()
    local scrollNodeSpSize = scrollNode._scroll_sp_:getContentSize()
    local scrollViewContentSize = self:getContentSize()
    local scrollViewViewSize = self:getViewSize()
    local minOffset = self:minContainerOffset()
    -- 设置滚动条前景图的大小
    local scrollNodeSpHeight
    if self:getDirection() == cc.SCROLLVIEW_DIRECTION_HORIZONTAL then
        scrollNodeSpHeight = scrollViewViewSize.width / scrollViewContentSize.width * scrollNodeBgSize.height
    elseif self:getDirection() == cc.SCROLLVIEW_DIRECTION_VERTICAL then
        scrollNodeSpHeight = scrollViewViewSize.height / scrollViewContentSize.height * scrollNodeBgSize.height
    else
        return
    end
    scrollNodeSpHeight = scrollNodeSpHeight < scrollNodeBgSize.height and scrollNodeSpHeight or scrollNodeBgSize.height
    scrollNode._scroll_sp_:SetContentSize(scrollNodeSpSize.width, scrollNodeSpHeight)
    -- 调整节点位置
    scrollNode._scroll_bg_:SetPosition("50%", "50%")
    scrollNode._scroll_sp_:SetPosition("50%", "50%")
    scrollNode._scroll_layer_:SetPosition("50%", "50%")
    -- 调整触摸layer的宽度
    if isAdjustLayerWidth then
        scrollNode._scroll_layer_:setContentSize(scrollNodeBgSize)
    else
        local oldLayerW, _ = scrollNode._scroll_layer_:GetContentSize()
        scrollNode._scroll_layer_:SetContentSize(oldLayerW, scrollNodeBgSize.height)
    end
    -- 处理scrollView滑动事件，设置滚动条前景图的位置
    if (scrollViewContentSize.height <= scrollViewViewSize.height and self:getDirection() == cc.SCROLLVIEW_DIRECTION_VERTICAL)
    or (scrollViewContentSize.width <= scrollViewViewSize.width and self:getDirection() == cc.SCROLLVIEW_DIRECTION_HORIZONTAL) then
        -- scrollView里面滚动的内容高度小于scrollView的高度
        if isHideWhenShort and scrollNode:isVisible() then
            scrollNode:setVisible(false)
        end
    else
        -- scrollView里面滚动的内容高度大于scrollView的高度
        local onScrollCallback = function()
            if not self:IsValid() or not scrollNode:IsValid() then
                __G__TRACKBACK__("node is invalid when scrolling, self:%s, scrollNode:%s", self:IsValid(), scrollNode:IsValid())
                return
            end
            -- 静止状态下隐藏
            if isHideWhenStop then
                --
                scrollNode._scroll_sp_:stopAllActions()
                scrollNode._scroll_sp_:setOpacity(255)
                local delayTime1 = cc.DelayTime:create(hideWaitTime)
                local fadeOut1 = cc.FadeOut:create(hideRunTime)
                local sequence1 = cc.Sequence:create(delayTime1, fadeOut1)
                scrollNode._scroll_sp_:runAction(sequence1)
                -- 
                scrollNode._scroll_bg_:stopAllActions()
                scrollNode._scroll_bg_:setOpacity(255)
                local delayTime2 = cc.DelayTime:create(hideWaitTime)
                local fadeOut2 = cc.FadeOut:create(hideRunTime)
                local sequence2 = cc.Sequence:create(delayTime2, fadeOut2)
                scrollNode._scroll_bg_:runAction(sequence2)
            end
            --
            local ratio = nil
            if self:getDirection() == cc.SCROLLVIEW_DIRECTION_VERTICAL then
                if scrollViewContentSize.height <= scrollViewViewSize.height then
                    return
                end
                local curOffset = self:getContentOffset()
                if curOffset.y < minOffset.y then
                    curOffset.y = minOffset.y
                elseif curOffset.y > 0 then
                    curOffset.y = 0
                end
                ratio = math.abs(curOffset.y) / math.abs(minOffset.y)
            elseif self:getDirection() == cc.SCROLLVIEW_DIRECTION_HORIZONTAL then
                if scrollViewContentSize.width <= scrollViewViewSize.width then
                    return
                end
                local curOffset = self:getContentOffset()
                if curOffset.x < minOffset.x then
                    curOffset.x = minOffset.x
                elseif curOffset.x > 0 then
                    curOffset.x = 0
                end
                ratio = math.abs(curOffset.x) / math.abs(minOffset.x)
            end
            if ratio then
                local scrollBgX, scrollBgY = scrollNode._scroll_bg_:GetPosition()
                local scrollSpX, scrollSpY = scrollNode._scroll_sp_:GetPosition()
                local originY = (scrollBgY - scrollNodeBgSize.height / 2 + scrollNodeSpHeight / 2)
                local newYPosition = originY + (scrollNodeBgSize.height - scrollNodeSpHeight) * ratio
                scrollNode._scroll_sp_:SetPosition(scrollSpX, originY)
                scrollNode._scroll_sp_:SetPosition("50%", newYPosition)
            end
        end
        onScrollCallback()
        self.newHandler.OnScroll = onScrollCallback
        self:HandleScrollEvent()
    end
    -- 处理触摸事件
    local oldOffset = self:getContentOffset()
    local scrollPointOffset = 0
    scrollNode._scroll_layer_.OnBegin = function(pos)
        if not self:IsValid() or not scrollNode:IsValid() then
            __G__TRACKBACK__("node is invalid when clicking, self:%s, scrollNode:%s", self:IsValid(), scrollNode:IsValid())
            return
        end
        local posY = scrollNode:convertToNodeSpace(pos).y
        local _, scrollSpY = scrollNode._scroll_sp_:GetPosition()
        scrollPointOffset = posY - scrollSpY
        if math.abs(scrollPointOffset) < scrollNodeSpHeight / 2 then
            return true
        end
    end
    scrollNode._scroll_layer_.OnDrag = function(pos)
        if not self:IsValid() or not scrollNode:IsValid() then
            __G__TRACKBACK__("node is invalid when dragging, self:%s, scrollNode:%s", self:IsValid(), scrollNode:IsValid())
            return
        end
        local posY = scrollNode._scroll_layer_:convertToNodeSpace(pos).y
        posY = posY - scrollPointOffset
        if posY < scrollNodeSpHeight / 2 then
            posY = scrollNodeSpHeight / 2
        elseif posY > scrollNodeBgSize.height - scrollNodeSpHeight / 2 then
            posY = scrollNodeBgSize.height - scrollNodeSpHeight / 2
        end
        local rate = (posY - scrollNodeSpHeight / 2) / (scrollNodeBgSize.height - scrollNodeSpHeight)
        self:setContentOffset(ccp(oldOffset.x, minOffset.y * rate))
    end
end

local BOUNCE_BACK_FACTOR  = 0.35
local SCROLL_DEACCEL_RATE = 0.95
local SCROLL_DEACCEL_RATE2= 0.9
local SCROLL_DEACCEL_DIST = 1
local BOUNCE_DURATION     = 0.15
local INSET_RATIO         = 0.1
local MOVE_INCH           = 7/160
local DELAY_ACC           = 0.01
local ANDROID_R           = 1
local BOUNCE_TIME         = 5
local CHANG_RATE_TIME     = 15

if cc.ScrollView.old_set_touch_enabled == nil then
    cc.ScrollView.old_set_touch_enabled = cc.ScrollView.setTouchEnabled
end

-- override
function cc.ScrollView:_init()
    tolua_super(cc.ScrollView)._init(self)
    cc.ScrollView.old_set_touch_enabled(self,false)
    self:setTouchEnabled(true)
    return self
end

function cc.ScrollView:isTouchEnabled()
    return self._touchListener ~= nil
end

function cc.ScrollView:setTouchEnabled(bEnable)
    if bEnable and self._touchListener == nil then
        local container
        local offset
        local minOffset
        local maxOffset
        local touchLastMoveTime = utils_get_tick()

        self._touches = {}
        self._dragging = false

        local prePos
        local nMovedDist
        local _touchMoved

        local function OnTouchBegan(touch)
            local pos = touch:getLocation()
            if self:IsVisible() and self:IsPointIn(pos) then

                container = self:getContainer()
                offset = self:getContentOffset()
                minOffset = self:minContainerOffset()
                maxOffset = self:maxContainerOffset()

                if #self._touches >= 1 then
                    return false
                end

                table.insert(self._touches, touch)
                prePos = pos
                nMovedDist = ccp(0, 0)
                _touchMoved = false
                self._dragging = true
                self._scrollDistance = ccp(0, 0)
                touchLastMoveTime = utils_get_tick()
                return true
            else
                return false
            end
        end

        local function OnTouchMove(touch)
            local pos = touch:getLocation()
            nMovedDist = cc.pSub(pos, prePos)
            local dis = 0
            if self:getDirection() == cc.SCROLLVIEW_DIRECTION_VERTICAL then
                dis = nMovedDist.y
                local curPos = container:getPositionY()
                if not (minOffset.y <= curPos and curPos <= maxOffset.y) then
                    nMovedDist.y = nMovedDist.y * BOUNCE_BACK_FACTOR
                end
                nMovedDist = ccp(0, nMovedDist.y)
            elseif self:getDirection() == cc.SCROLLVIEW_DIRECTION_HORIZONTAL then
                dis = nMovedDist.x
                local curPos = container:getPositionX()
                if not (minOffset.x <= curPos and curPos <= maxOffset.x) then
                    nMovedDist.x = nMovedDist.x * BOUNCE_BACK_FACTOR
                end
                nMovedDist = ccp(nMovedDist.x, 0)
            else
                dis = math.sqrt(nMovedDist.x * nMovedDist.x + nMovedDist.y * nMovedDist.y)

                local curPos = container:getPositionX()
                if not (minOffset.x <= curPos and curPos <= maxOffset.x) then
                    nMovedDist.x = nMovedDist.x * BOUNCE_BACK_FACTOR
                end

                curPos = container:getPositionY()
                if not (minOffset.y <= curPos and curPos <= maxOffset.y) then
                    nMovedDist.y = nMovedDist.y * BOUNCE_BACK_FACTOR
                end
            end

            if not _touchMoved then
                factor = 1
                if g_director.getOpenGLView then
                    local glView = g_director:getOpenGLView()
                    if glView.getContentScaleFactor then
                        factor = glView:getContentScaleFactor()
                    end
                end 
                local dpi = 100
                if cc.Device then
                    dpi = cc.Device:getDPI()
                end
                if math.abs(dis * factor / dpi) < MOVE_INCH then
                    return
                end
            end

            if not _touchMoved then
                nMovedDist = ccp(0,0)
            end

            _touchMoved = true
            prePos = pos
            if self._dragging then
                self:setContentOffset(cc.pAdd(ccp(container:getPosition()), self._scrollDistance))
                if (utils_get_tick() - touchLastMoveTime) < 0.03 and (self._scrollDistance.x + self._scrollDistance.y) ~= 0 then
                    self._scrollDistance.x = (nMovedDist.x + self._scrollDistance.x)/2
                    self._scrollDistance.y = (nMovedDist.y + self._scrollDistance.y)/2
                else
                    self._scrollDistance = nMovedDist
                end
            end

            touchLastMoveTime = utils_get_tick()
        end

        local function OnTouchEnd(touch)
            local pos = touch:getLocation()
            self._touches = {}
            self._dragging = false
            self._touchMoved = true
            local w, h = self:GetContentSize()
            local maxInset = ccp(maxOffset.x + w * INSET_RATIO, maxOffset.y + h * INSET_RATIO)
            local minInset = ccp(minOffset.x - w * INSET_RATIO, minOffset.y - h * INSET_RATIO)

            local curPlatform = g_application:getTargetPlatform()
            local intervalTime = utils_get_tick() - touchLastMoveTime
            touchLastMoveTime = utils_get_tick()
            if curPlatform == cc.PLATFORM_OS_ANDROID then
                self._scrollDistance = ccp(self._scrollDistance.x * ANDROID_R, self._scrollDistance.y * ANDROID_R)
                if intervalTime >= 0.01 then
                    local rate = 0.01/intervalTime / 2
                    self._scrollDistance = ccp(self._scrollDistance.x * rate, self._scrollDistance.y * rate)
                end
            end
            local delayCount,outsideCount = 0,0

            self:DelayCall(DELAY_ACC,function()
                if self._dragging  then
                    return
                end
                delayCount = delayCount + 1
                container:setPosition(cc.pAdd(ccp(container:getPosition()), self._scrollDistance))
                local newX,newY = container:getPositionX(),container:getPositionY()
                local rate = SCROLL_DEACCEL_RATE
                if delayCount > CHANG_RATE_TIME then
                    rate = SCROLL_DEACCEL_RATE2
                end
                self._scrollDistance = ccp(self._scrollDistance.x * rate, self._scrollDistance.y * rate)

                self:setContentOffset(ccp(newX,newY))

                if ((self:getDirection() == cc.SCROLLVIEW_DIRECTION_BOTH or self:getDirection() == cc.SCROLLVIEW_DIRECTION_VERTICAL) and (newY >= maxOffset.y or newY < minOffset.y)) or
                    ((self:getDirection() == cc.SCROLLVIEW_DIRECTION_BOTH or self:getDirection() == cc.SCROLLVIEW_DIRECTION_HORIZONTAL) and (newX >= maxOffset.x or newX < minOffset.x)) then
                    outsideCount = outsideCount + 1
                end

                if outsideCount > BOUNCE_TIME or --超过边界，并且滑动0.3秒
                    (math.abs(self._scrollDistance.x) <= SCROLL_DEACCEL_DIST and math.abs(self._scrollDistance.y) <= SCROLL_DEACCEL_DIST) or
                    ((self:getDirection() == cc.SCROLLVIEW_DIRECTION_BOTH or self:getDirection() == cc.SCROLLVIEW_DIRECTION_VERTICAL) and (newY >= maxInset.y or newY < minInset.y)) or
                    ((self:getDirection() == cc.SCROLLVIEW_DIRECTION_BOTH or self:getDirection() == cc.SCROLLVIEW_DIRECTION_HORIZONTAL) and (newX >= maxInset.x or newX < minInset.x)) then
                    
                    local oldPoint = cc.p(container:getPosition())
                    local newXX,newYY = oldPoint.x,oldPoint.y

                    if self:getDirection() == cc.SCROLLVIEW_DIRECTION_BOTH or self:getDirection() == cc.SCROLLVIEW_DIRECTION_HORIZONTAL then
                        newXX = math.max(newXX, minOffset.x)
                        newXX = math.min(newXX, maxOffset.x)
                    end
                    if self:getDirection() == cc.SCROLLVIEW_DIRECTION_BOTH or self:getDirection() == cc.SCROLLVIEW_DIRECTION_VERTICAL then
                        newYY = math.min(newYY, maxOffset.y)
                        newYY = math.max(newYY, minOffset.y)
                    end
                    self:setContentOffset(ccp(newXX,newYY),true)
                    return
                end
                return DELAY_ACC
            end)
        end

        local function OnTouchCancel(touch)
            OnTouchEnd(touch)
        end

        local touchOneByOneListener = cc.EventListenerTouchOneByOne:create()
        touchOneByOneListener:registerScriptHandler(function(touch)
            return OnTouchBegan(touch)
        end, cc.Handler.EVENT_TOUCH_BEGAN)
        touchOneByOneListener:registerScriptHandler(function(touch)
            OnTouchMove(touch)
        end, cc.Handler.EVENT_TOUCH_MOVED)
        touchOneByOneListener:registerScriptHandler(function(touch)
            OnTouchEnd(touch)
        end, cc.Handler.EVENT_TOUCH_ENDED)
        touchOneByOneListener:registerScriptHandler(function(touch)
            OnTouchCancel(touch)
        end, cc.Handler.EVENT_TOUCH_CANCELLED)

        touchOneByOneListener:setSwallowTouches(true)
        self:getEventDispatcher():addEventListenerWithSceneGraphPriority(touchOneByOneListener, self)
        self._touchListener = touchOneByOneListener
    elseif not bEnable and self._touchListener then
        self:getEventDispatcher():removeEventListener(self._touchListener)
        self._touchListener = nil
        self.touches = nil
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

if sp and sp.SkeletonAnimation then
    function sp.SkeletonAnimation:Create(jsonPath, action, isPlay, isLoop)
        if jsonPath == '' or not g_fileUtils:isFileExist(jsonPath) then
            return cc.Node:Create()
        end
        local path, _ = string.match(jsonPath, '(.*).json')
        local atlasPath = string.format('%s.atlas', path)
        local skeletonNode = sp.SkeletonAnimation:create(jsonPath, atlasPath)
        if is_valid_str(action) and isPlay then
            skeletonNode:setAnimation(0, action, isLoop)
        end
        return skeletonNode
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
