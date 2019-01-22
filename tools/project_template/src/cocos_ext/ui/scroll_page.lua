local SCrollPage, Super = tolua_get_class('SCrollPage')
local CCContainer = tolua_get_class('CCContainer')

-- override
function SCrollPage:_init()
    Super._init(self, CCContainer)
    print('SCrollPage:_init()')

    self._nCurViewPage = -1  -- 当前显示页面索引
    self._scrollNode = self:getContainer()
    self:setTouchEnabled(false)

    return self
end

-- override
function SCrollPage:_registerInnerEvent()
    Super._registerInnerEvent(self)

    self:_regInnerEvent('OnViewPage')

    local startPos
    local prePos
    local beginTick
    local xMinOffset
    local OnBegin = function(touch)
        local pos = touch:getLocation()

        if self._nCurViewPage == -1 or not self:IsVisible() or not self:IsPointIn(pos) then
            return false
        end
        
        self._scrollNode:stopAllActions()
        startPos = pos
        prePos = self._scrollNode:convertToNodeSpace(pos)
        beginTick = utils_get_tick()
        xMinOffset = -self:getContentSize().width + self:getViewSize().width
        return true
    end

    local OnDrag = function(touch)
        local pos = touch:getLocation()
        pos = self._scrollNode:convertToNodeSpace(pos)

        local x, y = self._scrollNode:getPosition()
        x = x + pos.x - prePos.x
        if x > 0 then
            x = 0
        elseif x < xMinOffset then
            x = xMinOffset
        end

        self:setContentOffset(ccp(x, y))
    end

    local OnEnd = function(touch)
        local pos = touch:getLocation()
        self:_doFocusView(utils_get_tick() - beginTick, pos.x - startPos.x)
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(OnBegin, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(OnDrag, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(OnEnd, cc.Handler.EVENT_TOUCH_ENDED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)
end

function SCrollPage:_doFocusView(scrollTime, scrollLen)
    -- 支持手动移多页
    -- 计算移动的到的index索引
    local focusedIndex = self:_calcCurFocusePos()
    if focusedIndex ~= self._nCurViewPage then
        self:SetViewPage(focusedIndex, true, true)
    else
        -- 根据滑动速度判断是否翻页
        local speed = scrollLen / math.max(scrollTime, 0.00001) * ccext_get_scale('1w')

        -- 距离除以时间，如果超过view_size的1/4，就认为翻页了
        -- 翻页因子，视图尺寸的1/4
        local page_turn_factor = self:getViewSize().width / 2

        -- print('speed', scrollLen, speed, page_turn_factor)

        -- 如果速度达到了翻下一页的因子
        if speed < -page_turn_factor then
            self:SetViewPage(focusedIndex + 1, true, true)
        elseif speed > page_turn_factor then
            self:SetViewPage(focusedIndex - 1, true, true)
        else
            self:SetViewPage(focusedIndex, true, true)
        end
    end
end

function SCrollPage:GetCurPageIndex()
    return self._nCurViewPage
end

-- 根据当前偏移量计算
function SCrollPage:_calcCurFocusePos()
    assert(self:GetItemCount() > 0)

    local centerPos = self:getViewSize().width / 2 - self:getContentOffset().x
    local allItem = self:GetAllItem()
    local focusedIndex = 1
    local item = allItem[focusedIndex]
    local _, halfw = item:GetContentSize()
    halfw = halfw / 2
    local focusedX = item:getPosition()
    for idx = 2, self:GetItemCount() do
        local len1 = math.abs(focusedX + halfw - centerPos) 
        local len2 = math.abs(allItem[idx]:getPosition() + halfw - centerPos)
        if len1 > len2 then
            focusedIndex = idx
            focusedX = allItem[focusedIndex]:getPosition()
        end
    end

    -- print('focusedIndex', focusedIndex)
    return focusedIndex
end

-- 设置当前的页面
function SCrollPage:SetViewPage(index, is_animate, bTriggerEvent)
    local count = self:GetItemCount()
    if count == 0 then
        return
    end

    if index < 1 then
        index = 1
    elseif index > count then
        index = count
    end

    -- 设置容器偏移
    self:LocatePosByItem(index, is_animate and 0.15 or 0)

    if self._nCurViewPage ~= index then
        self._nCurViewPage = index
        if bTriggerEvent then
            self.eventHandler:Trigger('OnViewPage', index)
        end
    end
end

-- 关联页码显示控件
function SCrollPage:BindPagePointer(pagePointer)
    self.newHandler.OnViewPage = function(index)
        pagePointer.SetTotalPage(self:GetItemCount())
        pagePointer.SetCurrentPage(index)
    end
end