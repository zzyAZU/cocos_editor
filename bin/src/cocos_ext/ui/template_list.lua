--[[====================================
=
=           template list 扩展
=
========================================]]
local CCContainer = tolua_get_class('CCContainer')
local AsyncContainer = tolua_get_class('AsyncContainer')


--模板基类
local SCrollList = tolua_get_class('SCrollList')

-- override
function SCrollList:Create()
    return cc.ScrollView:create():CastTo(self):_init(CCContainer)
end

-- override
function SCrollList:_init(ContainerType)
    tolua_super(SCrollList)._init(self)
    self._orderInRight = false  -- 是否从右边开始索引
    self:AddChild('_container', ContainerType:Create())

    self._container:setAnchorPoint(ccp(0, 1))

    return self
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

-- 设置从右边开始索引排序
function SCrollList:SetOrderInRight(isRight)
    self._orderInRight = isRight
    self._container:SetOrderInRight(isRight)
end


local AsyncList = tolua_get_class('AsyncList')

-- override
function AsyncList:_init()
    tolua_super(AsyncList)._init(self, AsyncContainer)

    self._bStartLoad = false
    self._startVisiIndex = nil
    self._endVisiIndex = nil

    self._lastScrollOffset = nil

    self:HandleScrollEvent()

    return self
end

-- override
function AsyncList:_registerInnerEvent()
    tolua_super(AsyncList)._registerInnerEvent(self)

    self:_regInnerEvent('OnCreateItem')

    self.newHandler.OnScroll = function()
        self:TestAsyncLoad()
    end
end

-- override
function AsyncList:SetInitCount(nCurCount, bNotRefresh)
    self._container:SetInitCount(nCurCount, bNotRefresh)
    if not bNotRefresh then
        self:_refreshItemPos()
    end
    self:TestAsyncLoad(true)
end

-- override
function AsyncList:AddItem(conf, index, bNotRefresh)
    local ret = self._container:AddItem(conf, index, bNotRefresh)
    if not bNotRefresh then
        self:_refreshItemPos()
    end
    self:TestAsyncLoad(true)
    return ret
end

function AsyncList:TestAsyncLoad(bForceUpdate)
    if bForceUpdate or self:_canAyncLoad() then
        -- 更新子控件可见性的起始与结束的索引
        self:_updateVisibleRange()
        self:DelayCall(0, function()
            self:_asyncLoad()
        end)
    end
end

-- 判断能否执行异步加载的命令（一般滚动的时候只有滚动的长度超过一定的范围才会触发继续异步加载）
function AsyncList:_canAyncLoad()
    if self:GetItemCount() == 0 then
        return false
    end

    if self._lastScrollOffset == nil then
        self._lastScrollOffset = self:getContentOffset()
        return true
    else
        local offset = self:getContentOffset()
        if self:IsHorzDirection() then
            if math.abs(offset.x - self._lastScrollOffset.x) > self._container:GetCtrlSize().width then
                self._lastScrollOffset = offset
                return true
            else
                return false
            end
        else
            if math.abs(offset.y - self._lastScrollOffset.y) > self._container:GetCtrlSize().height then
                self._lastScrollOffset = offset
                return true
            else
                return false
            end
        end
    end
end

-- 获取可见item的索引范围
function AsyncList:_updateVisibleRange()
    local sz = self._container:GetCtrlSize()
    local ctrlW, ctrlH = sz.width, sz.height
    local contentSize = self:getContentSize()
    local viewSize = self:getViewSize()
    local offset = self:getContentOffset()

    local nUnitStart, nUnitEnd
    if self:IsHorzDirection() then
        local calcWidth = -offset.x - self._container:GetHorzBorder()
        local nWidth = ctrlW + self._container:GetHorzIndent()

        nUnitStart = math.floor(calcWidth / nWidth)
        nUnitEnd = math.floor((calcWidth + viewSize.width) / nWidth)
    else
        local calcHeight = contentSize.height + offset.y - self._container:GetVertBorder()
        local nHeight = ctrlH + self._container:GetVertIndent()

        nUnitStart = math.floor((calcHeight - viewSize.height) / nHeight)
        nUnitEnd = math.floor(calcHeight / nHeight)
    end

    local numPerUnit = self._container:GetNumPerUnit()
    nUnitStart = (nUnitStart - 1) * numPerUnit
    nUnitEnd = (nUnitEnd + 2) * numPerUnit

    local maxIndex = self:GetItemCount()

    self._startVisiIndex = math.min(math.max(nUnitStart, 1), maxIndex)
    self._endVisiIndex = math.min(math.max(nUnitEnd, 1), maxIndex)

    -- print('@@@@', self._startVisiIndex, self._endVisiIndex)
end

-- 执行控件的异步加载
function AsyncList:_asyncLoad()
    if self._bStartLoad then
        return
    end

    if self:GetItemCount() == 0 then
        return
    end

    self._bStartLoad = true
    for i = self._startVisiIndex, self._endVisiIndex do
        if not self._container:IsItemLoaded(i) then
            local ok = g_async_task_mgr.do_execute(function()
                local item = self._container:DoLoadItem(i)
                self:_set_up_ctrl(item)
                self.eventHandler:Trigger('OnCreateItem', i, item)
            end)

            if not ok then
                -- 当前帧已经不能继续加载了
                self:DelayCall(0.001, function()
                    self._bStartLoad = false
                    self:_asyncLoad()
                end)
                return
            end
        end
    end

    self._bStartLoad = false
end
