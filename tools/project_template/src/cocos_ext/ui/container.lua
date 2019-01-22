--[[====================================
=
=        容纳控件的容器类(容器的大小由容器内子控件的多少决定)
=
========================================]]
local CCContainer, CCContainer_Super = tolua_get_class('CCContainer')

-- static override
function CCContainer:Create()
    return cc.Node:create():CastTo(self):_init()
end

-- override
function CCContainer:_init()
    CCContainer_Super._init(self)
    self:AddChild('_nodeContainer', cc.Node:create())

    self._child_item = {}

    self._nHorzBorder = 0
    self._nVertBorder = 0
    self._nHorzIndent = 0
    self._nVertIndent = 0
    self._ctrlSize = nil
    self._nNumPerUnit = 1 -- 一行或一列的单位个数
    self._nUnit = 0       -- 多少行或者多少列
    self._bHorzDirection = true
    self._bLeft2RightOrder = true

    self._varLength = nil  -- 一行或者一列的变长信息

    self._templateConf = nil
    self._customizeConf = nil

    return self
end

cc_utils_SetContentSizeReadOnly(CCContainer)

function CCContainer:_updateUnitNum()
    self._nUnit = math.ceil(#self._child_item / self._nNumPerUnit)
end

function CCContainer:GetUnitNum()
    return self._nUnit
end

-- @布局
function CCContainer:SetHorzDirection(bHorz)
    self._bHorzDirection = bHorz
end

function CCContainer:IsHorzDirection()
    return self._bHorzDirection
end

function CCContainer:SetNumPerUnit(nNum)
    self._nNumPerUnit = nNum
    self:_updateUnitNum()
end

function CCContainer:GetNumPerUnit()
    return self._nNumPerUnit
end

function CCContainer:SetHorzBorder(nBorder)
    self._nHorzBorder = nBorder
end

function CCContainer:GetHorzBorder()
    return self._nHorzBorder
end

function CCContainer:SetVertBorder(nBorder)
    self._nVertBorder = nBorder
end

function CCContainer:GetVertBorder()
    return self._nVertBorder
end

function CCContainer:SetHorzIndent(nIndent)
    self._nHorzIndent = nIndent
end

function CCContainer:GetHorzIndent()
    return self._nHorzIndent
end

function CCContainer:SetVertIndent(nIndent)
    self._nVertIndent = nIndent
end

function CCContainer:GetVertIndent()
    return self._nVertIndent
end

function CCContainer:SetLeft2RightOrder(bLeft2RightOrder)
    self._bLeft2RightOrder = bLeft2RightOrder
end

function CCContainer:IsLeft2RightOrder()
    return self._bLeft2RightOrder
end

function CCContainer:GetVarLength()
    return self._varLength
end

function CCContainer:_refreshSingleItem()
    -- unit num == 1 特殊处理兼容变长情况
    if self._nNumPerUnit == 1 then
        self._varLength = {}
    else
        self._varLength = nil
        return
    end

    local W, H
    local curY = -self._nVertBorder
    local curX = self._bLeft2RightOrder and self._nHorzBorder or -self._nHorzBorder
    local bVarLength = false
    local preLen
    if self._bHorzDirection then
        -- 水平布局
        W = 2 * self._nHorzBorder + (self._nUnit - 1) * self._nHorzIndent
        local maxHeight = 0

        for i, v in ipairs(self:GetAllItem()) do
            v:SetPosition(curX, curY)
            local w, h = v:GetContentSize()
            if self._bLeft2RightOrder then
                curX = curX + w + self._nHorzIndent
            else
                curX = curX - w - self._nHorzIndent
            end
            W = W + w
            if maxHeight < h then
                maxHeight = h
            end
            self._varLength[i] = w
            if not bVarLength then
                if preLen ~= nil and w ~= preLen then
                    bVarLength = true
                end
                preLen = w
            end
        end
        H = 2 * self._nVertBorder + maxHeight
    else
        -- 垂直布局
        H = 2 * self._nVertBorder + (self._nUnit - 1) * self._nVertIndent
        local maxWidth = 0

        for i, v in ipairs(self:GetAllItem()) do
            v:SetPosition(curX, curY)
            local w, h = v:GetContentSize()
            curY = curY - h - self._nVertIndent
            H = H + h
            if maxWidth < w then
                maxWidth = w
            end
            self._varLength[i] = h
            if not bVarLength then
                if preLen ~= nil and h ~= preLen then
                    bVarLength = true
                end
                preLen = h
            end
        end
        W = 2 * self._nHorzBorder + maxWidth
    end

    if not bVarLength then
        self._varLength = nil
    end

    local size = CCSize(W, H)
    self:setContentSize(size)
    if self._bLeft2RightOrder then
        self._nodeContainer:setPosition(0, H)
    else
        self._nodeContainer:setPosition(W, H)
    end
    return size
end

function CCContainer:_refreshMultiItem()
    if self._ctrlSize == nil then
        self._ctrlSize = CCSize(self:GetItem(1):GetContentSize())
    end

    -- 多行多列布局
    local W, H
    local ctrlW, ctrlH = self._ctrlSize.width, self._ctrlSize.height
    local nHorzSpace = ctrlW + self._nHorzIndent
    local nVertSpace = ctrlH + self._nVertIndent

    if self._bHorzDirection then
        -- 水平布局
        W = self._nUnit * (ctrlW + self._nHorzIndent) - self._nHorzIndent + 2 * self._nHorzBorder
        H = self._nNumPerUnit * (ctrlH + self._nVertIndent) - self._nVertIndent + 2 * self._nVertBorder
        local row = 0
        local startY = -self._nVertBorder
        local curX =  self._bLeft2RightOrder and self._nHorzBorder or -self._nHorzBorder
        local curY = startY

        for i, v in ipairs(self:GetAllItem()) do
            v:SetPosition(curX, curY)
            row = row + 1
            if row == self._nNumPerUnit then
                row = 0
                curY = startY
                curX = curX + (self._bLeft2RightOrder and nHorzSpace or -nHorzSpace)
            else
                curY = curY - nVertSpace
            end
        end
    else
        -- 垂直布局
        W = self._nNumPerUnit * (ctrlW + self._nHorzIndent) - self._nHorzIndent + 2 * self._nHorzBorder
        H = self._nUnit * (ctrlH + self._nVertIndent) - self._nVertIndent + 2 * self._nVertBorder
        local col = 0

        local startX = self._bLeft2RightOrder and self._nHorzBorder or -self._nHorzBorder
        local curX = startX
        local curY = -self._nVertBorder

        for i, v in ipairs(self:GetAllItem()) do
            v:SetPosition(curX, curY)
            col = col + 1
            if col == self._nNumPerUnit then
                col = 0
                curX = startX
                curY = curY - nVertSpace
            else
                curX = curX + (self._bLeft2RightOrder and nHorzSpace or -nHorzSpace)
            end
        end
    end

    local size = CCSize(W, H)
    self:setContentSize(size)
    if self._bLeft2RightOrder then
        self._nodeContainer:setPosition(0, H)
    else
        self._nodeContainer:setPosition(W, H)
    end
    return size
end

-- 刷新子控件的位置并调整容器的大小返回调整完毕后的容器大小
function CCContainer:_refreshItemPos()
    if self:GetItemCount() == 0 then
        local size = CCSize(2 * self._nHorzBorder, 2 * self._nVertBorder)
        self:setContentSize(size)
        return size
    end

    return self:_refreshSingleItem() or self:_refreshMultiItem()
end

-- @模板
function CCContainer:SetTemplate(templateName, templateInfo, customizeConf)
    self:SetTemplateConf(g_uisystem.load_template(templateName, templateInfo), customizeConf)
end

function CCContainer:SetTemplateConf(conf, customizeConf)
    g_uisystem.get_control_config(conf['type_name']):GenConfig(conf)
    self._templateConf = conf

    local size = conf['size']
    self._ctrlSize = self:CalcSize(size['width'], size['height'])

    self._customizeConf = customizeConf
end

function CCContainer:GetTemplateConf()
    return self._templateConf
end

function CCContainer:GetCustomizeConf()
    return self._customizeConf
end

function CCContainer:GetItem(index)
    return self._child_item[index]
end

function CCContainer:GetItemCount()
    return #self._child_item
end

function CCContainer:GetAllItem()
    return self._child_item
end

function CCContainer:SetInitCount(nCurCount, bNotUpdate)
    local nCount = self:GetItemCount()
    if nCurCount == nCount then
        return
    end

    if nCurCount == 0 then
        self:DeleteAllSubItem()
        return
    end

    local ret = nil
    if nCurCount > nCount then
        ret = {}
        if self._customizeConf and #self._customizeConf > nCount then
            for i = 1, nCurCount - nCount do
                local info = self._customizeConf[i + nCount]
                if info then
                    local template = g_uisystem.load_template(info['template'], info['template_info'])
                    table.insert(ret, self:AddItem(template, nil, true))
                else
                    table.insert(ret, self:AddItem(self._templateConf, nil, true))
                end
            end
        else
            for i = 1, nCurCount - nCount do
                table.insert(ret, self:AddItem(self._templateConf, nil, true))
            end
        end
    else
        for i = nCount, nCurCount + 1, -1 do
           self:DeleteItemIndex(i, true)
        end
    end

    if not bNotUpdate then
        self:_refreshItemPos()
    end

    return ret
end

-- override
function CCContainer:AddItem(conf, index, bNotRefresh)
    if is_string(conf) then
        return self:AddControl(g_uisystem.load_template_create(conf), index, bNotRefresh)
    else
        return self:AddControl(g_uisystem.create_item(conf), index, bNotRefresh)    
    end
end

function CCContainer:AddControl(ctrl, index, bNotRefresh)
    self._nodeContainer:addChild(ctrl)

    if self._bLeft2RightOrder then
        ctrl:setAnchorPoint(ccp(0, 1))
    else
        ctrl:setAnchorPoint(ccp(1, 1))
    end

    if index then
        table.insert(self._child_item, index, ctrl)
    else
        table.insert(self._child_item, ctrl)
    end

    self:_updateUnitNum()
    if not bNotRefresh then
        self:_refreshItemPos()
    end

    return ctrl
end

function CCContainer:AddTemplateItem(index, bNotRefresh)
    return self:AddItem(self._templateConf, index, bNotRefresh)
end

function CCContainer:DeleteAllSubItem()
    if #self._child_item == 0 then
        return
    end
    self._nodeContainer:removeAllChildren()
    self._child_item = {}
    self._nUnit = 0
    self:_refreshItemPos()

    return true
end

function CCContainer:DeleteItemIndex(index, bNotRefresh)
    local item = table.remove(self._child_item, index)
    if not item then
        return
    end

    if tolua_is_obj(item) then
        item:removeFromParent()
    end

    self:_updateUnitNum()
    if not bNotRefresh then
        self:_refreshItemPos()
    end

    return true
end

function CCContainer:DeleteItem(delItem, bNotRefresh)
    if not table.arr_remove_v(self._child_item, delItem) then
        return
    end

    if tolua_is_obj(delItem) then
        delItem:removeFromParent()
    end

    self:_updateUnitNum()
    if not bNotRefresh then
        self:_refreshItemPos()
    end

    return true
end

function CCContainer:GetCtrlSize()
    return self._ctrlSize
end


local AsyncContainer, AsyncContainer_Super = tolua_get_class('AsyncContainer')

-- override
function AsyncContainer:_init()
    tolua_super(AsyncContainer)._init(self)
    self._arrUpdatePos = {}

    return self
end

-- override
function AsyncContainer:_registerInnerEvent()
    AsyncContainer_Super._registerInnerEvent(self)
    self:_regInnerEvent('OnCreateItem')
end

-- override
-- conf 可以为模板字符串
function AsyncContainer:AddItem(conf, index, bNotRefresh)
    if index then
        table.insert(self._child_item, index, conf)
    else
        table.insert(self._child_item, conf)
    end

    self:_updateUnitNum()

    if not bNotRefresh then
        self:_refreshItemPos()
    end

    return conf
end

-- DoLoad 之前必须 _refreshItemPos
function AsyncContainer:DoLoadItem(index)
    local conf = self._child_item[index]
    if is_string(conf) then
        conf = g_uisystem.load_template(conf)
        assert(conf)
    end

    if is_table(conf) then
        local ctrl = g_uisystem.create_item(conf)
        self._nodeContainer:addChild(ctrl)

        -- 依据锚点 0, 1 来排布
        if self._bLeft2RightOrder then
            ctrl:setAnchorPoint(ccp(0, 1))
        else
            ctrl:setAnchorPoint(ccp(1, 1))
        end
        ctrl:setPosition(self._arrUpdatePos[index])
        self._child_item[index] = ctrl

        self.eventHandler:Trigger('OnCreateItem', index, ctrl)

        return ctrl
    end
end

function AsyncContainer:IsItemLoaded(index)
    return is_userdata(self._child_item[index])
end

-- override
function AsyncContainer:_refreshSingleItem()
    if self._nNumPerUnit == 1 then
        self._varLength = {}
    else
        self._varLength = nil
        return
    end

    self._arrUpdatePos = {}

    if self._ctrlSize == nil then
        self._ctrlSize = CCSize(self:GetItem(1):GetContentSize())
    end
    local ctrlW, ctrlH = self._ctrlSize.width, self._ctrlSize.height

    local W, H
    local curY = -self._nVertBorder
    local curX = self._bLeft2RightOrder and self._nHorzBorder or -self._nHorzBorder
    local bVarLength = false
    local preLen
    if self._bHorzDirection then
        -- 水平布局
        W = 2 * self._nHorzBorder + (self._nUnit - 1) * self._nHorzIndent
        local maxHeight = 0

        for i, v in ipairs(self:GetAllItem()) do
            local w, h
            if tolua_is_obj(v) then
                v:SetPosition(curX, curY)
                w, h = v:GetContentSize()
            else
                w, h = ctrlW, ctrlH
            end

            table.insert(self._arrUpdatePos, ccp(curX, curY))

            if self._bLeft2RightOrder then
                curX = curX + w + self._nHorzIndent
            else
                curX = curX - w - self._nHorzIndent
            end
            W = W + w
            if maxHeight < h then
                maxHeight = h
            end
            self._varLength[i] = w
            if not bVarLength then
                if preLen ~= nil and w ~= preLen then
                    bVarLength = true
                end
                preLen = w
            end
        end
        H = 2 * self._nVertBorder + maxHeight
    else
        -- 垂直布局
        H = 2 * self._nVertBorder + (self._nUnit - 1) * self._nVertIndent
        local maxWidth = 0

        for i, v in ipairs(self:GetAllItem()) do
            local w, h
            if tolua_is_obj(v) then
                v:SetPosition(curX, curY)
                w, h = v:GetContentSize()
            else
                w, h = ctrlW, ctrlH
            end

            table.insert(self._arrUpdatePos, ccp(curX, curY))

            curY = curY - h - self._nVertIndent
            H = H + h
            if maxWidth < w then
                maxWidth = w
            end
            self._varLength[i] = h
            if not bVarLength then
                if preLen ~= nil and h ~= preLen then
                    bVarLength = true
                end
                preLen = h
            end
        end
        W = 2 * self._nHorzBorder + maxWidth
    end

    if not bVarLength then
        self._varLength = nil
    end

    local size = CCSize(W, H)
    self:setContentSize(size)
    if self._bLeft2RightOrder then
        self._nodeContainer:setPosition(0, H)
    else
        self._nodeContainer:setPosition(W, H)
    end
    return size
end

-- override
function AsyncContainer:_refreshMultiItem()
    if self._ctrlSize == nil then
        self._ctrlSize = CCSize(self:GetItem(1):GetContentSize())
    end

    -- 多行多列布局
    local W, H
    local ctrlW, ctrlH = self._ctrlSize.width, self._ctrlSize.height
    local nHorzSpace = ctrlW + self._nHorzIndent
    local nVertSpace = ctrlH + self._nVertIndent

    self._arrUpdatePos = {}

    if self._bHorzDirection then
        -- 水平布局
        W = self._nUnit * (ctrlW + self._nHorzIndent) - self._nHorzIndent + 2 * self._nHorzBorder
        H = self._nNumPerUnit * (ctrlH + self._nVertIndent) - self._nVertIndent + 2 * self._nVertBorder
        local row = 0
        local startY = -self._nVertBorder
        local curX =  self._bLeft2RightOrder and self._nHorzBorder or -self._nHorzBorder
        local curY = startY

        for i, v in ipairs(self:GetAllItem()) do
            local pos = ccp(curX, curY)
            table.insert(self._arrUpdatePos, pos)
            if tolua_is_obj(v) then
                v:setPosition(pos)
            end
            row = row + 1
            if row == self._nNumPerUnit then
                row = 0
                curY = startY
                curX = curX + (self._bLeft2RightOrder and nHorzSpace or -nHorzSpace)
            else
                curY = curY - nVertSpace
            end
        end
    else
        -- 垂直布局
        W = self._nNumPerUnit * (ctrlW + self._nHorzIndent) - self._nHorzIndent + 2 * self._nHorzBorder
        H = self._nUnit * (ctrlH + self._nVertIndent) - self._nVertIndent + 2 * self._nVertBorder
        local col = 0

        local startX = self._bLeft2RightOrder and self._nHorzBorder or -self._nHorzBorder
        local curX = startX
        local curY = -self._nVertBorder

        for i, v in ipairs(self:GetAllItem()) do
            local pos = ccp(curX, curY)
            table.insert(self._arrUpdatePos, pos)
            if tolua_is_obj(v) then
                v:setPosition(pos)
            end
            col = col + 1
            if col == self._nNumPerUnit then
                col = 0
                curX = startX
                curY = curY - nVertSpace
            else
                curX = curX + (self._bLeft2RightOrder and nHorzSpace or -nHorzSpace)
            end
        end
    end

    local size = CCSize(W, H)
    self:setContentSize(size)
    if self._bLeft2RightOrder then
        self._nodeContainer:setPosition(0, H)
    else
        self._nodeContainer:setPosition(W, H)
    end
    return size
end

-- 单行列表动态加载后需要处理布局偏移
function AsyncContainer:OnItemProcessed(loadedList)
    if #loadedList == 0 then
        return
    end

    if self._varLength == nil then
        local bSame = true
        local unitName = self:IsHorzDirection() and 'width' or 'height'
        local unitLen = self._ctrlSize[unitName]

        for _, v in ipairs(loadedList) do
            local _, vv = unpack(v)
            if unitLen ~= vv:getContentSize()[unitName] then
                bSame = false
                break
            end
        end

        if bSame then
            return
        else
            self._varLength = {}
            for i = 1, self:GetItemCount() do
                table.insert(self._varLength, unitLen)
            end
        end
    end

    local offset = 0
    local bChanged = false
    for _, v in ipairs(loadedList) do
        local i, vv = unpack(v)
        local oldLen = self._varLength[i]
        local w, h = vv:GetContentSize()
        local newLen = self:IsHorzDirection() and w or h
        if newLen ~= oldLen then
            bChanged = true
            offset = offset + newLen - oldLen
            self._varLength[i] = newLen
        end
    end

    if not bChanged then
        return
    end

    local istart = loadedList[1][1]
    local size = self:getContentSize()
    local curLen, indent
    if self:IsHorzDirection() then
        curLen = self:GetHorzBorder()
        indent = self:GetHorzIndent()
        size.width = size.width + offset
    else
        curLen = self:GetVertBorder()
        indent = self:GetVertIndent()
        size.height = size.height + offset
    end

    for i = 1, istart - 1 do
        curLen = curLen + self._varLength[i] + indent
    end

    for i = istart, self:GetItemCount() do
        local item = self:GetItem(i)
        if tolua_is_obj(item) then
            local posx, posy = item:GetPosition()
            if self:IsHorzDirection() then
                if self._bLeft2RightOrder then
                    item:SetPosition(curLen, posy)
                else
                    item:SetPosition(-curLen, posy)
                end
            else
                item:SetPosition(posx, -curLen)
            end
            curLen = curLen + self._varLength[i] + indent
        else
            break
        end
    end

    self:setContentSize(size)
    if self._bLeft2RightOrder then
        self._nodeContainer:setPosition(0, size.height)
    else
        self._nodeContainer:setPosition(size.width, size.height)
    end

    return offset
end

function AsyncContainer:_doAsyncLoad()
    for i, v in ipairs(self._child_item) do
        if not self:IsItemLoaded(i) then
            local ok = g_async_task_mgr.do_execute(function()
                self:DoLoadItem(i)
            end)
            if not ok then
                self:AsyncLoad()
                break
            end
        end
    end
end

function AsyncContainer:AsyncLoad()
    if self._bScheduleLoading == true then
        return
    end

    self._bScheduleLoading = true
    self:DelayCall(0.01, function()
        self._bScheduleLoading = nil
        self:_doAsyncLoad()
    end)
end
