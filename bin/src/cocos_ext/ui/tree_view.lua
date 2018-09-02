--[[
    树形控件
]]
local constant_uisystem = g_constant_conf.constant_uisystem

local CCTreeView, Super = tolua_get_class('CCTreeView')

-- override
function CCTreeView:Create()
    return Super:create():CastTo(self):_init()
end

function CCTreeView:_init()
    Super._init(self)

    self:setBounceable(false)
    self:setClippingToBounds(true)
    self:EnableMouseWheelAndScroll(false)

    local container = cc.Node:create()
    self:setContainer(container)

    local node = cc.Node:create()
    container:AddChild(nil, node)

    --member data
    self._kHorzIndent = constant_uisystem.default_treeview_horz_indent
    self._kVertIndent = constant_uisystem.default_treeview_vert_indent
    self._node = node  -- 根节点

    --选中的控件信息 selList : 选中的item数组 selExist : key item, value true
    self._selInfo = {selList = {}, selExist = {}}

    --item data
    self._node._parentInfo = nil  -- 父节点信息 {parentItem, index}
    self._node._child_item = {}  -- 子节点列表
    self._node._bFold = false  -- item 是否折叠

    self._templateName = nil

    self._dragSptCreateFun = nil

    return self
end

function CCTreeView:GetParentItem(item)
    return item._parentInfo[1]
end

function CCTreeView:IsRootItem(item)
    return item._parentInfo[1] == self._node
end

function CCTreeView:GetItemChildList(item)
    return item._child_item
end

function CCTreeView:GetItemChildCount(item)
    return #item._child_item
end

function CCTreeView:IsEmpty()
    return #self._node._child_item == 0
end

function CCTreeView:GetRootItem()
    return self._node
end

function CCTreeView:GetRootItemChildList()
    return self._node._child_item
end

function CCTreeView:IsAncestor(item, destItem)
    while destItem ~= self._node do
        if item == destItem then
            return true
        else
            destItem = destItem._parentInfo[1]
        end
    end
    return false
end

function CCTreeView:SetElemTemplateName(templateName)
    self._templateName = templateName
end

function CCTreeView:AddItem(conf, parent_item, index, not_refresh)
    return self:AddControl(g_uisystem.create_item(conf), parent_item, index, not_refresh)
end

function CCTreeView:AddTemplateItem(parent_item, index, not_refresh)
    return self:AddItem(g_uisystem.load_template(self._templateName), parent_item, index, not_refresh)
end

function CCTreeView:AddControl(item, parent_item, index, not_refresh)
    parent_item = parent_item or self._node

    item:setAnchorPoint(ccp(0, 1))
    item:SetClipObjectRecursion(self)

    parent_item:addChild(item)
    
    if index then
        table.insert(parent_item._child_item, index, item)
        -- reset child index
        for i = index + 1, #parent_item._child_item do
            parent_item._child_item[i]._parentInfo[2] = i
        end
    else
        table.insert(parent_item._child_item, item)
        index = #parent_item._child_item
    end

    item._parentInfo = {parent_item, index}
    item._child_item = {}

    if parent_item ~= self._node then
        self:_update_fold_btn(parent_item)
    end
    
    self:_update_fold_btn(item)

    if not not_refresh then
        self:refresh_item_pos()
    end

    local btn = item['_dragDropBtn_']
    if self._bEnableDragAndDrop and btn then
        local startPt
        local spt

        btn.newHandler.OnBegin = function(pt)
            if self._bEnableDragAndDrop then
                spt = nil
                startPt = pt
                return true
            end
        end

        btn.newHandler.OnDrag = function(pt)
            if spt == nil then
                if math.abs(startPt.x - pt.x) + math.abs(startPt.y - pt.y) >= constant_uisystem.default_treeview_min_drag_len then
                    spt = self._dragSptCreateFun(item)
                    if spt then
                        g_director:getRunningScene():addChild(spt, 10)
                        spt:setAnchorPoint(ccp(0.5, 0.5))
                        spt:setPosition(pt)
                        spt:setScale(item:GetTotalScale())
                    end
                end
            else
                spt:setPosition(pt)
            end
        end

        btn.newHandler.OnEnd = function(pt)
            if spt ~= nil then
                local destItem = self:ItemForTouch(pt)
                self.eventHandler:DelayTrigger('OnDragAndDrop', pt, item, destItem)
                spt:removeFromParent(true)
                spt = nil
            end
        end
    end

    local _touchBg_ = item['_touchBg_']
    if _touchBg_ and btn then
        btn:HandleMouseEvent()
        btn.OnMouseMove = function(bInside, pos, bFirst)
            if bFirst then
                _touchBg_:setVisible(bInside)
            end
        end
    end
    
    return item
end

function CCTreeView:GetItem(parent_item, index)
    parent_item = parent_item or self._node
    return parent_item._child_item[index]
end

function CCTreeView:_updateSelInfo()
    local selList = {}
    for _, v in ipairs(self._selInfo.selList) do
        if tolua_is_obj(v) and v:getParent() then
            table.insert(selList, v)
        else
            self._selInfo.selExist[v] = nil
        end
    end
    self._selInfo.selList = selList
end

--[[删除当前节点的所有子节点]]
function CCTreeView:DeleteAllSubItem(parent_item, not_refresh)
    parent_item = parent_item or self._node

    for _, item in ipairs(parent_item._child_item) do
        item:removeFromParent(true)
    end

    parent_item._child_item = {}

    self:_updateSelInfo()

    if not not_refresh then
        self:_updateSelFrames()
        self:refresh_item_pos()
    end
end

--[[删除指定的item]]
function CCTreeView:DeleteItem(item, not_refresh)
    if not tolua_is_obj(item) then
        return
    end

    local parent_item = item._parentInfo[1]
    assert(parent_item)

    --移除父节点的引用
    assert(table.remove(parent_item._child_item, item._parentInfo[2]) == item)

    --重置删除节点后面节点的所在索引
    local childItem = parent_item._child_item
    for i = item._parentInfo[2], #childItem do
        childItem[i]._parentInfo[2] = i
    end
    
    item:removeFromParent(true)
    self:_updateSelInfo()

    if parent_item ~= self._node then
        self:_update_fold_btn(parent_item)
    end
    
    if not not_refresh then
        self:_updateSelFrames()
        self:refresh_item_pos()
    end
end

function CCTreeView:DeleteItemByIndex(parent_item, index, bNotRefresh)
    local item = self:GetItem(parent_item, index)
    if item then
        return self:DeleteItem(item, bNotRefresh)
    end
end

--[[drag and drop]]
function CCTreeView:EnableDragAndDrop(createFun)
    if not self._bEnableDragAndDrop then
        self:_regInnerEvent('OnDragAndDrop')
    end
    self._bEnableDragAndDrop = true
    self._dragSptCreateFun = createFun
end

-- handle selList[1]
function CCTreeView:SelectItem(item, bSelect, bNotUpdateSelect)
    local selList = self._selInfo.selList
    if #selList > 1 then
        table.clear(selList)
    end

    if tolua_is_obj(item) then
        if bSelect then
            if selList[1] == item then
                return
            else
                selList[1] = item
            end
        else
            if selList[1] == item then
                selList[1] = nil
            else
                return
            end
        end
    else
        table.clear(selList)
    end

    if not bNotUpdateSelect then
        self:_updateSelFrames()
    end
end

function CCTreeView:MultiSelectItem(item, bSelect, bNotUpdateSelect)
    assert(tolua_is_obj(item))

    local selList = self._selInfo.selList
    if bSelect then
        if table.find_v(selList, item) then
            return
        else
            table.insert(selList, item)
        end
    else
        if not table.arr_remove_v(selList, item) then
            return
        end
    end

    if not bNotUpdateSelect then
        self:_updateSelFrames()
    end
end

--[[设置多个item的选中状态]]
function CCTreeView:SelectItems(items, bSelect, bNotUpdateSelect)
    for i, v in ipairs(items) do
        self:MultiSelectItem(v, bSelect, true)
    end

    if not bNotUpdateSelect then
        self:_updateSelFrames()
    end
end

--[[直接设置所选中的所有的]]
function CCTreeView:SetSelectedItems(items, bNotUpdateSelect)
    self._selInfo.selList = items
    if not bNotUpdateSelect then
        self:_updateSelFrames()
    end
end

function CCTreeView:GetSelectedItem()
    return self._selInfo.selList[1]
end

function CCTreeView:GetSelectedItems()
    return self._selInfo.selList
end

--指定item是否被选中
function CCTreeView:IsItemSelected(item)
    return self._selInfo.selExist[item] ~= nil
end

-- update sel info
function CCTreeView:_updateSelFrames()
    local selExist = table.to_value_set(self._selInfo.selList)

    self._selInfo.selExist = selExist

    self:ForEachItem(function(item)
        local _selFrame_ = item['_selFrame_']
        if _selFrame_ then
            if selExist[item] then
                _selFrame_:setVisible(true)
                _selFrame_:SetContentSize('100%', '100%')
            else
                _selFrame_:setVisible(false)
            end
        end
    end)
end

--[[折叠指定item]]
function CCTreeView:ExpandItem(item, bExpand, bNotRefresh)
    local bFold = not bExpand
    if item._bFold == bFold then
        return
    end

    if item._bLock and bExpand then
        return
    end

    item._bFold = bFold

    self:_update_fold_btn(item)

    if not bNotRefresh then
        local offset = self:getContentOffset()
        local old_container_size = self:getContentSize()
        self:refresh_item_pos()
        local container_size = self:getContentSize()
        self:setContentOffset(ccp(offset.x, offset.y + (old_container_size.height - container_size.height)))
    end
end

-- lock 中的 item 无法折叠
function CCTreeView:LockItem(item, bLock)
    item._bLock = bLock

    local _btnArrowRight_ = item['_btnArrowRight_']
    if _btnArrowRight_ then
        _btnArrowRight_:SetEnable(not bLock)
    end

    if bLock then
        self:ExpandItem(item, false)
    end
end

--[[某个item是否已展开]]
function CCTreeView:IsItemExpanded(item)
    return not item._bFold
end

--[[
    更新parent_item的所有子项的显示
    返回parent_item以及所有子控件显示的矩形宽高
]]
function CCTreeView:_refresh_item_pos(parent_item, indent, accuIndent)
    local parentSize= parent_item:getContentSize()
    local width     = indent + parentSize.width + accuIndent
    local height     = self._kVertIndent + parentSize.height

    if not parent_item._bFold then

        local posY = -self._kVertIndent

        for _, item in ipairs(parent_item._child_item) do

            item:setPosition(indent, posY)

            local w, h = self:_refresh_item_pos(item, indent, accuIndent + indent)

            posY     = posY - h
            height     = height + h
            width     = math.max(width, w)
        end
    end

    return width, height
end

--[[
    更新listview的内部子控件的显示状态
    notScrollTotop : 更新之后 scrollview 的 contentoffset 是否滚到最上
]]
function CCTreeView:refresh_item_pos()
    local w, h = self:_refresh_item_pos(self._node, self._kHorzIndent, 0)
    local view_size = self:getViewSize()
    w = math.max(w, view_size.width)
    h = math.max(h, view_size.height)
    self:setContentSize(CCSize(w, h))
    self._node:SetPosition(0, "100%")
end

--[[更新有子项的item的折叠按钮显示状态(内部调用)ok]]
function CCTreeView:_update_fold_btn(parent_item)
    local btnArrowRight = parent_item['_btnArrowRight_']
    if tolua_is_obj(btnArrowRight) then
        btnArrowRight:setVisible(#parent_item._child_item > 0)

        if parent_item._bFold then
            btnArrowRight:setRotation(0)
        else
            btnArrowRight:setRotation(90)
        end

        btnArrowRight.OnClick = function()
            self:ExpandItem(parent_item, parent_item._bFold)
        end
    end

    --设置子节点的可见性
    local bVisible = not parent_item._bFold
    for _, item in ipairs(parent_item._child_item) do
        item:setVisible(bVisible)
    end

    if parent_item.on_fold_btn_update then
        parent_item.on_fold_btn_update()
    end
end






------------------- utilyties -------------------

--[[bNotRefresh : 不刷新items 的位置]]
function CCTreeView:ExpandAll(bExpand, bNotRefresh)
    local function RecursivelyExband(item)
        self:ExpandItem(item, bExpand, true)
        for _, v in ipairs(item._child_item) do RecursivelyExband(v) end
    end
    
    for _, v in ipairs(self._node._child_item) do RecursivelyExband(v) end

    if not bNotRefresh then self:refresh_item_pos() end
end

--[[是否折叠]]
function CCTreeView:IsItemFolded(item)
    local parent = item._parentInfo[1]
    while parent and parent ~= self._node do
        if not self:IsItemExpanded(parent) then
            return true
        end
        parent = parent._parentInfo[1]
    end

    return false
end

--[[
    使item的父节点都是是展开的确保item可见,
    return true if some item have been expanded
]]
function CCTreeView:UnfoldSelectedItem(item)
    if not item then return end
    local bExpand = false
    local parent = item._parentInfo[1]
    while parent and parent ~= self._node do
        if not self:IsItemExpanded(parent) then
            bExpand = true
            self:ExpandItem(parent, true, true)
        end
        parent = parent._parentInfo[1]
    end
    
    --将unfold出的item居中显示
    if bExpand then
        self:refresh_item_pos()
        self:CenterWithNode(item)
    end
    return bExpand
end

--[[获取指定点中的 item]]
function CCTreeView:ItemForTouch(pos)
    local function getitem(item)
        for _, v in ipairs(item._child_item) do
            local item = getitem(v)
            if item then return item end
        end
        if item:IsVisible() and item:IsPointIn(pos) then
            return item
        end
    end

    return getitem(self._node)
end

--[[获取指定item基于根节点的索引列表]]
function CCTreeView:GetItemIndex(item)
    local ret = {}
    while item._parentInfo do
        local parentInfo = item._parentInfo
        table.insert(ret, 1, parentInfo[2])
        item = parentInfo[1]
    end
    assert(self._node == item)
    return ret
end

--[[根据索引列表获取指定item]]
function CCTreeView:GetItemByIndexList(indexList)
    local item = self._node
    for _, index in ipairs(indexList) do
        item = item._child_item[index]
        if item == nil then
            return
        end
    end
    return item
end


--[[遍历CCListView的所有节点]]
function CCTreeView:ForEachItem(func)
    local function visit_item(item)
        if func(item) then return item end

        for _, subItem in ipairs(item._child_item) do
            local ret = visit_item(subItem)
            if ret then return ret end
        end
    end
    
    for _, subItem in ipairs(self._node._child_item) do
        local ret = visit_item(subItem)
        if ret then return ret end
    end
end

function CCTreeView:SelectItemIf(func, bSelect, bNotUpdateSelect)
    local selItem = self:ForEachItem(func)
    self:SelectItem(selItem, bSelect, bNotUpdateSelect)
    return selItem
end

function CCTreeView:SelectItemsIf(func, bSelect, bNotUpdateSelect)
    local selItems = {}
    self:ForEachItem(function(item)
        if func(item) then
            table.insert(selItems, item)
        end
    end)
    self:SelectItems(selItems, bSelect, bNotUpdateSelect)
    return selItems
end

function CCTreeView.GetParentItemIndex(item)
    local parentInfo = item._parentInfo
    if parentInfo ~= nil then
        return parentInfo[2]
    end
end

function CCTreeView:GetSelectedIndexList()
    local list = {}
    local indexList = {}
    local function _search(item)
        if self:IsItemSelected(item) then
            table.insert(list, table.copy(indexList))
        end

        for i, v in ipairs(item._child_item) do
            table.insert(indexList, i)
            _search(v)
            table.remove(indexList)
        end
    end
    _search(self._node)

    return list
end

function CCTreeView:SelectItemByIndexList(indexList, bSelect, bNotUpdateSelect)
    local curNode = self._node
    for _, i in ipairs(indexList) do
        curNode = curNode._child_item[i]
        if curNode == nil then
            return
        end
    end
    self:SelectItem(curNode)
    return curNode
end

function CCTreeView:GetNoSelParentSelItems()
    local selItemList = {}

    local function getSelList(item)
        if self:IsItemSelected(item) then
            table.insert(selItemList, item)
        else
            for _, v in ipairs(self:GetItemChildList(item)) do
                getSelList(v)
            end
        end
    end

    getSelList(self._node)

    return selItemList
end