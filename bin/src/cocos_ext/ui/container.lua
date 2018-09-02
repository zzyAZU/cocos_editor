--[[====================================
=
=        容纳控件的容器类(容器的大小由容器内子控件的多少决定)
=
========================================]]
local CCContainer = tolua_get_class('CCContainer')

-- static override
function CCContainer:Create()
    return cc.Node:create():CastTo(self):_init()
end

-- override
function CCContainer:_init()
    -- tolua_super(CCContainer)._init(self)
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

    self._templateConf = nil
    self._customizeConf = nil
    self._orderInRight  = false

    return self
end

cc_utils_SetContentSizeReadOnly(CCContainer)

function CCContainer:_updateUnitNum()
    self._nUnit = math.ceil(#self._child_item / self._nNumPerUnit)
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

-- 刷新子控件的位置并调整容器的大小返回调整完毕后的容器大小
function CCContainer:_refreshItemPos()
    if self:GetItemCount() == 0 then
        local size = CCSize(2 * self._nHorzBorder, 2 * self._nVertBorder)
        self:setContentSize(size)
        return size
    end

    -- unit num == 1 特殊处理兼容变长情况
    if self._nNumPerUnit == 1 then
        local W, H = 2 * self._nHorzBorder, 2 * self._nVertBorder
        local oX = self._nHorzBorder
        local oY = -self._nVertBorder

        if self._bHorzDirection then
            W = W + (self._nUnit - 1) * self._nHorzIndent
            -- 水平布局
            local w, h
            for i, v in ipairs(self:GetAllItem()) do
                v:SetPosition(oX, oY)
                w, h = v:GetContentSize()
                oX = oX + w + self._nHorzIndent
                W = W + w
            end
            H = H + h
        else
            H = H + (self._nUnit - 1) * self._nVertIndent
            -- 垂直布局
            local w, h
            for i, v in ipairs(self:GetAllItem()) do
                v:SetPosition(oX, oY)
                w, h = v:GetContentSize()
                oY = oY - h - self._nVertIndent
                H = H + h
            end
            W = W + w
        end
        
        local size = CCSize(W, H)
        self:setContentSize(size)
        self._nodeContainer:setPosition(0, H)
        return size
    end

    -----------------------------------
    local W, H
    local ctrlW, ctrlH = self._ctrlSize.width, self._ctrlSize.height
    local nHorzSpace = ctrlW + self._nHorzIndent
    local nVertSpace = ctrlH + self._nVertIndent
    local oX = self._nHorzBorder
    local oY = -self._nVertBorder
    
    if self._bHorzDirection then
        -- 水平布局
        W = self._nUnit * (ctrlW + self._nHorzIndent) - self._nHorzIndent + 2 * self._nHorzBorder
        H = self._nNumPerUnit * (ctrlH + self._nVertIndent) - self._nVertIndent + 2 * self._nVertBorder
        local row, col = 0, 0
        for i, v in ipairs(self:GetAllItem()) do
            v:SetPosition(oX + col * nHorzSpace, oY - row * nVertSpace)
            row = row + 1
            if row == self._nNumPerUnit then
                row = 0
                col = col + 1
            end
        end
    else
        -- 垂直布局
        W = self._nNumPerUnit * (ctrlW + self._nHorzIndent) - self._nHorzIndent + 2 * self._nHorzBorder
        H = self._nUnit * (ctrlH + self._nVertIndent) - self._nVertIndent + 2 * self._nVertBorder
        local rowWidth = self._nNumPerUnit * nHorzSpace + oX   -- 行宽
        local row, col = 0, 0
        for i, v in ipairs(self:GetAllItem()) do
            -- 设置self._orderInRight 之后 靠右排
            if self._orderInRight then
                v:SetPosition(rowWidth - oX - (col + 1) * nHorzSpace, oY - row * nVertSpace)
            else
                v:SetPosition(oX + col * nHorzSpace, oY - row * nVertSpace)
            end    
            col = col + 1
            if col == self._nNumPerUnit then
                col = 0
                row = row + 1
            end
        end
    end

    local size = CCSize(W, H)
    self:setContentSize(size)
    self._nodeContainer:setPosition(0, H)
    return size
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

    -- assert(self._ctrlSize.width > 0 and self._ctrlSize.height > 0)

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
    if not self._templateConf then return end
    local nCount = self:GetItemCount()
    if nCurCount == nCount then return end

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
        for i = 1, nCount - nCurCount do
            self:DeleteItemIndex(nCount - i + 1, true)
        end
    end

    if not bNotUpdate then
        self:_refreshItemPos()
    end

    return ret
end

function CCContainer:AddItem(conf, index, bNotRefresh)
    if is_string(conf) then
        return self:AddControl(g_uisystem.load_template_create(conf), index, bNotRefresh)
    else
        return self:AddControl(g_uisystem.create_item(conf), index, bNotRefresh)    
    end
end

function CCContainer:AddControl(ctrl, index, bNotRefresh)
    self._nodeContainer:addChild(ctrl)

    ctrl:setAnchorPoint(ccp(0, 1))

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
    if #self._child_item == 0 then return end

    for _, v in ipairs(self._child_item) do
        v:removeFromParent()
    end
    self._child_item = {}
    self._nUnit = 0
    self:_refreshItemPos()

    return true
end

function CCContainer:DeleteItemIndex(index, bNotRefresh)
    local item = self._child_item[index]
    if not item then return end

    item:removeFromParent()
    table.remove(self._child_item, index)

    self:_updateUnitNum()
    if not bNotRefresh then
        self:_refreshItemPos()
    end

    return true
end

function CCContainer:DeleteItem(d_item, bNotRefresh)
    local item = nil
    local index = 0
    for idx, it in ipairs(self._child_item) do
        if it == d_item then
            index = idx
            item = d_item
            break
        end
    end
    if not item then return end

    item:removeFromParent()
    table.remove(self._child_item, index)

    self:_updateUnitNum()
    if not bNotRefresh then
        self:_refreshItemPos()
    end

    return true
end

function CCContainer:GetCtrlSize()
    return self._ctrlSize
end

-- 设置从右边开始索引排序
function CCContainer:SetOrderInRight(isRight)
    self._orderInRight = isRight
    self:_refreshItemPos()
end


local AsyncContainer = tolua_get_class('AsyncContainer')

-- override
function AsyncContainer:_init()
    tolua_super(AsyncContainer)._init(self)
    self._arrUpdatePos = {}

    return self
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

function AsyncContainer:DeleteAllSubItem()
    if #self._child_item == 0 then
        return
    end

    for i, v in ipairs(self._child_item) do
        if tolua_is_obj(v) then
            v:removeFromParent()
        end
    end

    self._child_item = {}
    self._nUnit = 0

    return true
end

-- override
function AsyncContainer:DeleteItemIndex(index, bNotRefresh)
    local ret = self._child_item[index]

    if tolua_is_obj(ret) then
        ret:removeFromParent()
    else
        ret = nil
    end
    
    table.remove(self._child_item, index)

    self:_updateUnitNum()

    if not bNotRefresh then
        self:_refreshItemPos()
    end

    return ret
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
        ctrl:setAnchorPoint(ccp(0, 1))
        ctrl:setPosition(self._arrUpdatePos[index])
        self._child_item[index] = ctrl

        return ctrl
    end
end

function AsyncContainer:IsItemLoaded(index)
    return tolua_is_obj(self._child_item[index])
end

-- override
function AsyncContainer:_refreshItemPos()
    if self:GetItemCount() == 0 then
        local size = CCSize(2 * self._nHorzBorder, 2 * self._nVertBorder)
        self:setContentSize(size)
        return size
    end

    -----------------------------------
    local W, H
    local ctrlW, ctrlH = self._ctrlSize.width, self._ctrlSize.height
    local nHorzSpace = ctrlW + self._nHorzIndent
    local nVertSpace = ctrlH + self._nVertIndent
    local oX = self._nHorzBorder
    local oY = -self._nVertBorder
        
    self._arrUpdatePos = {}

    if self._bHorzDirection then
        -- 水平布局
        W = self._nUnit * (ctrlW + self._nHorzIndent) - self._nHorzIndent + 2 * self._nHorzBorder
        H = self._nNumPerUnit * (ctrlH + self._nVertIndent) - self._nVertIndent + 2 * self._nVertBorder
        local row, col = 0, 0
        for i, v in ipairs(self:GetAllItem()) do
            local pos = ccp(oX + col * nHorzSpace, oY - row * nVertSpace)
            table.insert(self._arrUpdatePos, pos)
            if tolua_is_obj(v) then
                v:setPosition(pos)
            end
            row = row + 1
            if row == self._nNumPerUnit then
                row = 0
                col = col + 1
            end
        end
    else
        -- 垂直布局
        W = self._nNumPerUnit * (ctrlW + self._nHorzIndent) - self._nHorzIndent + 2 * self._nHorzBorder
        H = self._nUnit * (ctrlH + self._nVertIndent) - self._nVertIndent + 2 * self._nVertBorder
        local row, col = 0, 0
        for i, v in ipairs(self:GetAllItem()) do
            local pos = ccp(oX + col * nHorzSpace, oY - row * nVertSpace)
            table.insert(self._arrUpdatePos, pos)
            if tolua_is_obj(v) then
                v:setPosition(pos)
            end
            col = col + 1
            if col == self._nNumPerUnit then
                col = 0
                row = row + 1
            end
        end
    end

    local size = CCSize(W, H)
    self:setContentSize(size)
    self._nodeContainer:setPosition(0, H)
    return size
end