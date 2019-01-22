--[[====================================
=
=           template list 扩展
=
========================================]]
local CCContainer = tolua_get_class('CCContainer')
local AsyncContainer = tolua_get_class('AsyncContainer')


--模板基类
local SCrollList, SCrollList_Super = tolua_get_class('SCrollList')

-- override
function SCrollList:Create()
    return cc.ScrollView:create():CastTo(self):_init(CCContainer)
end

-- override
function SCrollList:_init(ContainerType)
    SCrollList_Super._init(self)
    self:AddChild('_container', ContainerType:Create())
    self._startVisiIndex = nil
    self._endVisiIndex = nil
    self._lastScrollOffset = nil
    self._nNotAutoHideLen = 0

    self._container:setAnchorPoint(ccp(0, 1))
    self:HandleScrollEvent()

    return self
end

-- override
function SCrollList:_registerInnerEvent()
    SCrollList_Super._registerInnerEvent(self)

    self.newHandler.OnScroll = function()
        if self._bScheduleUpVisiRangeNextFrame == nil and self:_canTestVisibility() then
            self:UpdateVisibleRangeNextFrame()
        end
    end
end

-- override
function SCrollList:_canTestVisibility()
    if self:GetItemCount() == 0 then
        return false
    end

    if self._lastScrollOffset == nil then
        return true
    else
        local offset = self:getContentOffset()
        if self:IsHorzDirection() then
            if offset.x > 0 or offset.x < self:minContainerOffset().x then
                if self._bScrollToBoundary then
                    return
                else
                    self._bScrollToBoundary = true
                end
            else
                self._bScrollToBoundary = nil
            end

            local diff = offset.x - self._lastScrollOffset.x
            -- print('x diff', diff)
            if diff > 0 then
                -- container -> 右
                if self:IsLeft2RightOrder() then
                    return diff > self._checkVisibilityUpperScroll
                else
                    return diff > self._checkVisibilitylowerScroll
                end
            else
                -- container -> 左
                if self:IsLeft2RightOrder() then
                    return -diff > self._checkVisibilitylowerScroll
                else
                    return -diff > self._checkVisibilityUpperScroll
                end
            end
        else
            if offset.y > 0 or offset.y < self:minContainerOffset().y then
                if self._bScrollToBoundary then
                    return
                else
                    self._bScrollToBoundary = true
                end
            else
                self._bScrollToBoundary = nil
            end

            local diff = offset.y - self._lastScrollOffset.y
            -- print('y diff', diff)
            if diff > 0 then
                -- container -> 上
                return diff >= self._checkVisibilitylowerScroll
            else
                -- container -> 下
                return -diff >= self._checkVisibilityUpperScroll
            end
        end
    end
end

-- override
function SCrollList:_updateSingleListVisibleRange()
    local varLength = self._container:GetVarLength()
    if varLength == nil then
        return
    end

    local offset = self:getContentOffset()
    local csize = self:getContentSize()
    local w, h = self:GetContentSize()

    local startLen
    local endLen
    local curLen = 0
    local indent
    if self:IsHorzDirection() then
        if self:IsLeft2RightOrder() then
            startLen = -offset.x - self._container:GetHorzBorder()
        else
            startLen = csize.width + offset.x - w - self._container:GetHorzBorder()
        end
        endLen = startLen + w
        indent = self._container:GetHorzIndent()
    else
        startLen = csize.height + offset.y - h - self._container:GetVertBorder()
        endLen = startLen + h
        indent = self._container:GetVertIndent()
    end

    startLen = startLen - self._nNotAutoHideLen
    endLen = endLen + self._nNotAutoHideLen

    local startVisiIndex
    local endVisiIndex
    local upperScroll
    local lowerScroll
    for i, v in ipairs(varLength) do
        curLen = curLen + v + indent
        if startVisiIndex == nil and curLen > startLen then
            startVisiIndex = i
            upperScroll = v - (curLen - startLen)
        end

        if endVisiIndex == nil and curLen >= endLen then
            endVisiIndex = i
            lowerScroll = curLen - endLen
            break
        end
    end

    self._startVisiIndex = startVisiIndex or 1
    self._endVisiIndex = endVisiIndex or self:GetItemCount()
    self._lastScrollOffset = offset
    self._checkVisibilityUpperScroll = (upperScroll or 0) + self._nNotAutoHideLen / 4
    self._checkVisibilitylowerScroll = (lowerScroll or 0) + self._nNotAutoHideLen / 4

    -- print('_updateSingleListVisibleRange', self._startVisiIndex, self._endVisiIndex, self._checkVisibilityUpperScroll, self._checkVisibilitylowerScroll)

    return true
end

-- override
function SCrollList:_updateMultiListVisibleRange()
    local sz = self._container:GetCtrlSize()
    local ctrlW, ctrlH = sz.width, sz.height
    local offset = self:getContentOffset()
    local csize = self:getContentSize()
    local w, h = self:GetContentSize()

    local startLen
    local endLen
    local unitLen
    local upperScroll
    local lowerScroll
    local startVisiIndex
    local endVisiIndex
    if self:IsHorzDirection() then
        unitLen = ctrlW + self._container:GetHorzIndent()
        if self:IsLeft2RightOrder() then
            startLen = -offset.x - self._container:GetHorzBorder()
        else
            startLen = csize.width + offset.x - w - self._container:GetHorzBorder()
        end
        endLen = startLen + w
    else
        unitLen = ctrlH + self._container:GetVertIndent()
        startLen = csize.height + offset.y - h - self._container:GetVertBorder()
        endLen = startLen + h
    end

    startLen = startLen - self._nNotAutoHideLen
    endLen = endLen + self._nNotAutoHideLen

    upperScroll = startLen % unitLen
    startVisiIndex = math.ceil(startLen / unitLen)
    lowerScroll = unitLen - endLen % unitLen
    endVisiIndex = math.ceil(endLen / unitLen)

    local numPerunit = self._container:GetNumPerUnit()
    if numPerunit > 1 then
        startVisiIndex = numPerunit * (startVisiIndex - 1) + 1
        endVisiIndex = numPerunit * endVisiIndex
    end

    local nMax = self:GetItemCount()
    self._startVisiIndex = math.min(math.max(startVisiIndex, 1), nMax)
    self._endVisiIndex = math.min(math.max(endVisiIndex, 1), nMax)
    self._lastScrollOffset = offset
    self._checkVisibilityUpperScroll = upperScroll + self._nNotAutoHideLen / 4
    self._checkVisibilitylowerScroll = lowerScroll + self._nNotAutoHideLen / 4

    -- print('_updateMultiListVisibleRange', self._startVisiIndex, self._endVisiIndex, self._checkVisibilityUpperScroll, self._checkVisibilitylowerScroll)
end

-- override
function SCrollList:_updateVisibleRange()
    if self:GetItemCount() > 0 then
        return self:_updateSingleListVisibleRange() or self:_updateMultiListVisibleRange()
    end
end

function SCrollList:UpdateVisibleRangeNextFrame()
    if self._bScheduleUpVisiRangeNextFrame then
        return
    end
    self._bScheduleUpVisiRangeNextFrame = true
    self:DelayCall(0, function()
        self._bScheduleUpVisiRangeNextFrame = nil
        self:_updateVisibleRange()
    end)
end

-- override
function SCrollList:SetContentSize(sw, sh)
    local sz = self:CalcSize(sw, sh)

    local W, H = self._container:GetContentSize()
    if self._container:IsHorzDirection() then
        sz.height = H
    else
        sz.width = W
    end
    self:setViewSize(sz)

    return self:_refreshItemPos()
end

function SCrollList:_refreshItemPos()
    local W, H = self:GetContentSize()
    local CW, CH = self._container:GetContentSize()
    if self._container:IsHorzDirection() then
        if H ~= CH then
            H = CH
        end
    else
        if W ~= CW then
            W = CW
        end
    end

    local ret = CCSize(W, H)
    self:setViewSize(ret)
    self:setContentSize(CCSize(math.max(CW, W), math.max(CH, H)))
    self._container:SetPosition(0, 'i0')
    self:UpdateVisibleRangeNextFrame()
    return ret
end

function SCrollList:_refreshContainer()
    self._container:_refreshItemPos()
    self:_refreshItemPos()
end

function SCrollList:SetHorzDirection(bHorz)
    if bHorz then
        self:setDirection(cc.SCROLLVIEW_DIRECTION_HORIZONTAL)
    else
        self:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    end
    self._container:SetHorzDirection(bHorz)
    self:_refreshItemPos()

    self:EnableMouseWheelAndScroll(bHorz)
end

function SCrollList:IsHorzDirection()
    return self._container:IsHorzDirection()
end

function SCrollList:SetNumPerUnit(nNum)
    self._container:SetNumPerUnit(nNum)
    self:_refreshItemPos()
end

function SCrollList:GetUnitNum()
    return self._container:GetUnitNum()
end

function SCrollList:SetHorzBorder(nBorder)
    self._container:SetHorzBorder(nBorder)
    self:_refreshItemPos()
end

function SCrollList:SetVertBorder(nBorder)
    self._container:SetVertBorder(nBorder)
    self:_refreshItemPos()
end

function SCrollList:SetHorzIndent(nIndent)
    self._container:SetHorzIndent(nIndent)
    self:_refreshItemPos()
end

function SCrollList:SetVertIndent(nIndent)
    self._container:SetVertIndent(nIndent)
    self:_refreshItemPos()
end

function SCrollList:SetLeft2RightOrder(bLeft2RightOrder)
    self._container:SetLeft2RightOrder(bLeft2RightOrder)
end

function SCrollList:GetItem(index)
    return self._container:GetItem(index)
end

function SCrollList:GetItemCount()
    return self._container:GetItemCount()
end

function SCrollList:GetAllItem()
    return self._container:GetAllItem()
end

function SCrollList:SetTemplate(templateName, templateInfo, customizeConf)
    self._container:SetTemplate(templateName, templateInfo, customizeConf)
end

function SCrollList:SetInitCount(nCurCount, bNotRefresh)
    local add = self._container:SetInitCount(nCurCount, bNotRefresh)
    if add then
        for i, ctrl in ipairs(add) do
            self:_set_up_ctrl(ctrl)
        end
    end
    if not bNotRefresh then
        self:_refreshItemPos()
    end
end

function SCrollList:AddItem(conf, index, bNotRefresh)
    local ret = self._container:AddItem(conf, index, bNotRefresh)
    self:_set_up_ctrl(ret)
    if not bNotRefresh then
        self:_refreshItemPos()
    end
    return ret
end

function SCrollList:AddControl(ctrl, index, bNotRefresh)
    local ret = self._container:AddControl(ctrl, index, bNotRefresh)
    self:_set_up_ctrl(ret)
    if not bNotRefresh then
        self:_refreshItemPos()
    end
    return ret
end

function SCrollList:AddTemplateItem(index, bNotRefresh)
    local ret = self._container:AddTemplateItem(index, bNotRefresh)
    self:_set_up_ctrl(ret)
    if not bNotRefresh then
        self:_refreshItemPos()
    end
    return ret
end

function SCrollList:DeleteAllSubItem()
    self._container:DeleteAllSubItem()
    self:_refreshItemPos()
end

function SCrollList:DeleteItemIndex(index, bNotRefresh)
    self._container:DeleteItemIndex(index, bNotRefresh)
    if not bNotRefresh then
        self:_refreshItemPos()
    end
end

function SCrollList:DeleteItem(item, bNotRefresh)
    self._container:DeleteItem(item, bNotRefresh)
    if not bNotRefresh then
        self:_refreshItemPos()
    end
end

function SCrollList:LocatePosByItem(index, duration)
    local item = self:GetItem(index)
    if not item then
        return
    end
    self:CenterWithNode(item, duration)
end

function SCrollList:GetHorzBorder()
    return self._container:GetHorzBorder()
end

function SCrollList:GetVertBorder()
    return self._container:GetHorzBorder()
end

function SCrollList:GetHorzIndent()
    return self._container:GetHorzIndent()
end

function SCrollList:GetVertIndent()
    return self._container:GetVertIndent()
end

function SCrollList:GetCtrlSize()
    return self._container:GetCtrlSize()
end

function SCrollList:GetNumPerUnit()
    return self._container:GetNumPerUnit()
end

function SCrollList:IsLeft2RightOrder()
    return self._container:IsLeft2RightOrder()
end

function SCrollList:SetNotAutoHideLen(len)
    self._nNotAutoHideLen = len
end

local AsyncList, AsyncList_Super = tolua_get_class('AsyncList')

-- override
function AsyncList:_init()
    AsyncList_Super._init(self, AsyncContainer)
    self._bReverseLoadOrder = false
    return self
end

-- override
function AsyncList:_registerInnerEvent()
    AsyncList_Super._registerInnerEvent(self)
    self:_regInnerEvent('OnCreateItem')
end

-- override
function AsyncList:SetInitCount(nCurCount, bNotRefresh)
    self._container:SetInitCount(nCurCount, bNotRefresh)
    if not bNotRefresh then
        self:_refreshItemPos()
    end
end

-- override
function AsyncList:AddItem(conf, index, bNotRefresh, callback)
    local ret = self._container:AddItem(conf, index, bNotRefresh, callback)
    if not bNotRefresh then
        self:_refreshItemPos()
    end
    return ret
end

function AsyncList:SetReverseLoadOrder(bReverse)
    self._bReverseLoadOrder = bReverse
end

function AsyncList:IsSingleItemReverseLoadOrder()
    return self._bReverseLoadOrder
end

-- override
function AsyncList:_updateVisibleRange()
    if self:GetItemCount() == 0 then
        return
    end

    if self._startVisiIndex and self._endVisiIndex then
        for i = self._startVisiIndex, self._endVisiIndex do
            local ctrl = self._container:GetItem(i)
            if tolua_is_obj(ctrl) then
                ctrl:setVisible(false)
            end
        end
    end

    if not self:_updateSingleListVisibleRange() then
        self:_updateMultiListVisibleRange()
    end

    if self._startVisiIndex and self._endVisiIndex then
        for i = self._startVisiIndex, self._endVisiIndex do
            local ctrl = self._container:GetItem(i)
            if tolua_is_obj(ctrl) then
                ctrl:setVisible(true)
            end
        end
    end

    self:_doAsyncLoad()
end

function AsyncList:_doAsyncLoad()
    local itemCount = self:GetItemCount()
    if itemCount == 0 then
        return
    end

    if self._bScheduleLoading == true then
        return
    end

    -- 在 schedule 过程中如果出现减少元素的情况可能会出现以下情况
    if self._endVisiIndex > itemCount then
        self._endVisiIndex = itemCount
    end

    local istart, iend, istep
    if self._bReverseLoadOrder then
        istart = self._endVisiIndex
        iend = self._startVisiIndex
        istep = -1
    else
        istart = self._startVisiIndex
        iend = self._endVisiIndex
        istep = 1
    end

    local loadedList = {}
    local bSingleList = self:GetNumPerUnit() == 1
    for i = istart, iend, istep do
        if not self._container:IsItemLoaded(i) then
            local ok = g_async_task_mgr.do_execute(function()
                local item = self._container:DoLoadItem(i)
                self:_set_up_ctrl(item)
                self.eventHandler:Trigger('OnCreateItem', i, item)

                if bSingleList then
                    if self._bReverseLoadOrder then
                        table.insert(loadedList, 1, {i, item})
                    else
                        table.insert(loadedList, {i, item})
                    end
                end
            end)

            if not ok then
                self._bScheduleLoading = true
                self:DelayCall(0.01, function()
                    self._bScheduleLoading = nil
                    self:_doAsyncLoad()
                end)
                break
            end
        end
    end

    local diffLen = self._container:OnItemProcessed(loadedList)
    if diffLen and diffLen > 0 then
        self:_refreshItemPos()
        local offset = self:getContentOffset()
        if self:IsHorzDirection() then
            if not self._bReverseLoadOrder then
                offset.x = offset.x - diffLen
            end
        else
            if not self._bReverseLoadOrder then
                offset.y = offset.y - diffLen
            end
        end
        self:setContentOffset(offset)
    end
end

-- backwards
AsyncList.TestAsyncLoad = AsyncList.UpdateVisibleRangeNextFrame
