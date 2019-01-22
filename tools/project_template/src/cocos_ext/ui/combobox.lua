--[[
    CCCombobox
]]
local constant_uisystem = g_constant_conf.constant_uisystem

local CCCombobox, Super = tolua_get_class('CCCombobox')
-- override
function CCCombobox:Create(combobox_template,combobox_popup_layer_template)
    self.combobox_template = combobox_template or 'default/ctrls/combobox/ctrl_combobox'
    self.combobox_popup_layer_template = combobox_popup_layer_template or 'default/ctrls/combobox/ctrl_combobox_popup_layer'
    return g_uisystem.load_template_create(self.combobox_template):CastTo(self):_init()
end

-- override
function CCCombobox:_init()
    Super._init(self)

    self._nPopupWidth = 250 --菜单的宽度
    self._bPopup = false

    self._itemData = {}

    return self
end

-- override
function CCCombobox:_registerInnerEvent()
    Super._registerInnerEvent(self)

    self:_regInnerEvent('OnBeforPopup')
    self:_regInnerEvent('OnMenuClick')
    self:_regInnerEvent('OnMenuMouseMove')

    self.newHandler.OnClick = function()
        self:Popup(not self._bPopup, true)
    end

    self:registerScriptHandler(function(data)
        if 'exitTransitionStart' == data then
            local popupLayer = self._itemData.popupLayer
            if tolua_is_obj(popupLayer) then
                popupLayer:removeFromParent()
                self._itemData.popupLayer = nil
            end
        end
    end)
end

--override
function CCCombobox:SetContentSize(sw, sh)
    local size = Super.SetContentSize(self, sw, sh)
    self['_bg_']:SetContentSize(size.width, size.height)
    self['_text_']:SetPosition(22, size.height / 2)

    return size
end

function CCCombobox:Popup(bPopup, bTriggerEvent)
    if self._bPopup == bPopup then
        return
    end

    if bTriggerEvent then
        self.eventHandler:Trigger('OnBeforPopup')
    end
    self._bPopup = bPopup
    self:_updatePopupPanel()
end

--[[设置popupframe的宽度, item 宽度 + icon 宽度 == popupframe 宽度]]
function CCCombobox:SetPopupFrameWidth(nItemWidth)
    self._nPopupWidth = nItemWidth
end

function CCCombobox:_createMenuList(itemData, parentItem, relativeNode)
    local parent
    if parentItem == nil then
        parent = g_director:getRunningScene()
        if parent == nil then
            return
        end
    else
        parent = parentItem.popupLayer
    end

    local popupLayer = g_uisystem.load_template_create(self.combobox_popup_layer_template, parent)
    itemData.popupLayer = popupLayer

    if parentItem then
        if tolua_is_obj(parentItem.popupMenu) then
            parentItem.popupMenu:removeFromParent()
        end

        parentItem.popupMenu = popupLayer
    end

    if parentItem == nil then
        popupLayer['_maskLayer_'].OnBegin = function()
            if self:IsValid() then
                self:Popup(false, false)
            end
            return false
        end
    else
        popupLayer['_maskLayer_']:setTouchEnabled(false)
    end

    -- init data
    popupLayer['_list_']:SetInitCount(#itemData, true)
    for i, info in ipairs(itemData) do
        local text, itemName, callback = unpack(info, 1, 3)
        local item = popupLayer['_list_']:GetItem(i)
        item._text_:SetString(text)

        item:SetContentSize(self._nPopupWidth, 30)

        if item._sArrow_ then
            item._sArrow_:setVisible(is_table(info._itemData))
            item._sArrow_:SetPosition('i0', '50%')
        end

        item:HandleMouseEvent()

        local _bgActivated_ = item['_bgActivated_']
        if _bgActivated_ then
            _bgActivated_:SetContentSize(self._nPopupWidth, 30)
            item.OnMouseMove = function(bMoveInside, pos, bFirst)
                if bFirst then
                    _bgActivated_:setVisible(bMoveInside)
                end

                if bFirst then
                    self.eventHandler:Trigger('OnMenuMouseMove', bMoveInside, text, itemName)
                end

                -- print(bMoveInside, info)
                if bMoveInside then
                    if is_table(info._itemData) then
                        self:_createMenuList(info._itemData, itemData, item)
                    else
                        if itemData.popupMenu then
                            itemData.popupMenu:removeFromParent()
                            itemData.popupMenu = nil
                        end
                    end
                end
            end
        end

        item.OnClick = function()
            assert(self._bPopup == true)
            if is_table(info._itemData) then
                return
            end
            if self:IsValid() then
                self:Popup(false)
                self.eventHandler:Trigger('OnMenuClick', itemName)
                if callback then
                    callback()
                end
            end
        end
    end


    popupLayer['_list_']:_refreshContainer()
    local size = itemData.popupLayer['_list_']:getContentSize()
    local w, h = size.width, size.height

    -- local csize = relativeNode:getContentSize()
    local relativeNodeW, relativeNodeH = relativeNode:GetContentSize()
    local lb = relativeNode:convertToWorldSpace(ccp(0, 0))
    local rt = relativeNode:convertToWorldSpace(ccp(relativeNodeW, relativeNodeH))

    local posx, posy
    local anchor = {}
    local winSize = g_director:getWinSize()

    if parentItem == nil then
        if lb.x + w > winSize.width then
            --右
            posx = relativeNodeW
            anchor.x = 1
        else
            --左
            posx = 0
            anchor.x = 0
        end
    else
        if parentItem._menuPopupLeft then
            -- 尝试靠左
            if lb.x < w then
                -- 右
                posx = relativeNodeW
                anchor.x = 0
            else
                -- 左
                posx = 0
                anchor.x = 1
                itemData._menuPopupLeft = true
            end
        else
            -- 尝试靠右
            if rt.x + w > winSize.width then
                -- 左
                posx = 0
                anchor.x = 1
                itemData._menuPopupLeft = true
            else
                -- 右
                posx = relativeNodeW
                anchor.x = 0
            end
        end
    end

    if lb.y < h then
        if lb.y > winSize.height / 2 then
            --下
            posy = parentItem == nil and 0 or relativeNodeH
            anchor.y = 1
            h = lb.y
        else
            --上
            posy = parentItem == nil and relativeNodeH or 0
            anchor.y = 0
            if h > winSize.height - rt.y then
                h = winSize.height - rt.y
            end
        end
    else
        --下
        posy = parentItem == nil and 0 or relativeNodeH
        anchor.y = 1
    end

    local wpos = relativeNode:convertToWorldSpace(ccp(posx, posy))
    popupLayer:setPosition(parent:convertToNodeSpace(wpos))
    popupLayer:setAnchorPoint(anchor)
    popupLayer:SetContentSize(w, h)
    popupLayer['_bg_']:SetContentSize(w, h)
    popupLayer['_list_']:SetContentSize(w, h)
    popupLayer['_list_']:ScrollToTop()
end

function CCCombobox:_createPopupLayer()
    return self:_createMenuList(self._itemData, nil, self)
end

function CCCombobox:_removePopupLayer()
    if tolua_is_obj(self._itemData.popupLayer) then
        self._itemData.popupLayer:removeFromParent()
        self._itemData.popupLayer = nil
    end
end

function CCCombobox:_updatePopupPanel()
    self:_removePopupLayer()

    if self._bPopup then
        self:_createPopupLayer()
    end
end

--[[
    增加一个子项
    name: item 名称
    if index == nil then append a new item, otherwise insert a new item
]]
function CCCombobox:AddMenuItem(text, index, popUpItem, name, callback)
    if is_function(index) then
        callback = index
        index = nil
    elseif is_function(popUpItem) then
        callback = popUpItem
        popUpItem = nil
    elseif is_function(name) then
        callback = name
        name = nil
    end

    local data = {text, name, callback}
    local itemData = popUpItem and popUpItem._itemData or self._itemData
    if index then
        table.insert(itemData, index, data)
    else
        table.insert(itemData, data)
    end
end

function CCCombobox:AddPopupMenuItem(text, popUpItem, name, index)
    local data = {text, nil, _itemData={}}
    local itemData = popUpItem and popUpItem._itemData or self._itemData
    if index then
        table.insert(itemData, index, data)
    else
        table.insert(itemData, data)
    end

    return data
end

function CCCombobox:SetItems(list)
    self._itemData = {}
    for i, v in ipairs(list) do
        self:AddMenuItem(v[2], nil, nil, v[1])
    end
end

function CCCombobox:RegEvent(name, callback)
    self.newHandler.OnMenuClick = function(itemName)
        if name == itemName then
            callback()
        end
    end
end

function CCCombobox:SetString(...)
    local text = GetTextByLanguageI(...)
    self['_text_']:SetString(text)
    return text
end

function CCCombobox:GetString()
    return self['_text_']:GetString()
end
