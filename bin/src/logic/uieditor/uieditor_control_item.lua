local constant_uieditor = g_constant_conf['constant_uieditor']


local function round_scale(s)
    return math.round_number(s * 1000) / 1000
end

local function round_angle(s)
   return math.round_number(s * 100) / 100 
end





--[[ ui编辑器的单一控件配置，管理对应的对象列表以及显示视图中创建的对应控件 ]]
UIControlItem = CreateClass()

--[[
    根据指定配置以及相关信息生成 对应 control 以及 merge config 并加入 device_layer 以及 object list 中  并且生成对应 item 并返回
    conf: 控件配置信息
    parentItem: 挂接的父节点, if parentItem == nil then control 自身为根节点
    pos: 插入父节点的子节点索引位置
    panel: ui编辑器面板
]]
function UIControlItem:__init__(conf, parentItem, pos, panel)
    self._parentItem = parentItem
    self._childList = {}
    self._panel = panel
    self._listObjects = panel.listObjects
    self._btnInListView = nil
    self._selFrame = nil  -- 视图中显示的操纵UI（当选中的时候会显示）

    local temp_conf = table.copy(conf)
    temp_conf.child_list = {}

    self._control, self._cfg = g_uisystem.create_item(temp_conf, parentItem and parentItem._control or panel.layerDevice)
    self._cfg = table.deepcopy(self._cfg)  -- 更改的 cfg 会影响 cache 里面的内容

    if parentItem then
        if not pos then
            table.insert(parentItem._childList, self)
        else
            table.insert(parentItem._childList, pos, self)
        end
    end
    self:_updateZOrder()

    self:_initUI(pos)

    for _, sub_conf in ipairs(conf.child_list or {}) do
        UIControlItem:New(sub_conf, self, nil, panel)
    end

    self:_updateItem()
end

-- 矫正显示次序
function UIControlItem:_updateZOrder()
    local parentItem = self._parentItem
    if parentItem then
        local parentCtrl = parentItem._control
        local pos = table.find_v(parentItem._childList, self)
        for i = pos + 1, #parentItem._childList do
            local ctrl = parentItem._childList[i]._control
            local zorder = ctrl:getLocalZOrder()
            ctrl:retain()
            ctrl:removeFromParent(false)
            parentCtrl:addChild(ctrl, zorder)
            ctrl:release()
        end
    end
end

--[[将item与编辑器面板相关控件相关联并注册相关操作]]
function UIControlItem:_initUI(pos)
    --生成对应button添加到list_object列表中
    local list_objects = self._listObjects
    local parent_btn = self._parentItem and self._parentItem._btnInListView
    local btn = list_objects:AddItem(g_uisystem.load_template('editor/uieditor/items/uieditor_list_object_template'), parent_btn, pos)
    btn.uicontrol_item = self --btnInListview添加一个item的引用
    self._btnInListView = btn

    btn.chVisible.OnChecked = function(bChecked)
        --OP
        self._control:setVisible(bChecked)
        self:RefreshItemConfig()
        self._panel:EditPush()
    end

    btn.chLock.OnChecked = function(bChecked)
        --OP
        self._cfg['lock'] = bChecked
        self._listObjects:LockItem(self._btnInListView, bChecked)
        self._panel:EditPush()
        if not bChecked then
            self._listObjects:ExpandItem(self._btnInListView, true)
        end
    end

    btn.on_fold_btn_update = function()
        print('on_fold_btn_update')
        btn.chLock:setVisible(self._listObjects:GetItemChildCount(btn) > 0)
    end

    btn.btn.OnClick = function()
        if g_ui_event_mgr.is_ctrl_down() then
            self._panel:CtrlSelectControlItem(self)--多选
        elseif g_ui_event_mgr.is_shift_down() then
            local selItem = self._panel:GetSelectedControlItem()
            if selItem and selItem ~= self then
                --shift多选
                local y1 = selItem._btnInListView:convertToWorldSpace(ccp(0, 0)).y
                local y2 = self._btnInListView:convertToWorldSpace(ccp(0, 0)).y
                local miny, maxy = math.min(y1, y2), math.max(y1, y2)
                local items = {}
                self._listObjects:ForEachItem(function(item)
                    item = item.uicontrol_item
                    if item and not list_objects:IsItemFolded(item._btnInListView) then
                        local y = item._btnInListView:convertToWorldSpace(ccp(0, 0)).y
                        if y >= miny and y <= maxy then
                            table.insert(items, item)
                        end
                    end
                end)
                self._panel:SelectControlItems(items)
            end
        else
            self._panel:SelectControlItem(self)--单选
        end

        self._panel:_editRefreshCurselData()
    end

    if self._cfg['lock'] then
        self._listObjects:LockItem(btn, true)
    end
end

--[[从节点列表中移除自身，处理自身的选中状态]]
function UIControlItem:RemoveSelf()
    if not self._control:IsValid() then
        return
    end

    --删除选中对象处理
    for _, v in ipairs(self._panel:GetSeletedList()) do
        if self:IsAncestor(v) then
            self._panel:SelectControlItem(nil)
            break
        end
    end
    
    --移除父节点的引用
    if self._parentItem then
        table.arr_remove_v(self._parentItem._childList, self)
        self._parentItem = nil
    end

    --移除控件
    self._control:removeFromParent(true)
    self._control = nil

    --清list_objects
    self._listObjects:DeleteItem(self._btnInListView)
    self._listObjects = nil
end

function UIControlItem:GetCtrl()
    return self._control
end

function UIControlItem:GetCfg()
    return self._cfg
end

function UIControlItem:GetTypeName()
    return self._cfg['type_name']
end

function UIControlItem:GetAniData()
    return self._cfg['ani_data']
end

function UIControlItem:GetParentItem()
    return self._parentItem
end

--[[获取该项在父项的索引位置,如果是根节点则返回nil]]
function UIControlItem:GetParentItemIndex()
    return self._listObjects.GetParentItemIndex(self._btnInListView)
end

function UIControlItem:GetChildList()
    return self._childList
end

function UIControlItem:GetBtnInListView()
    return self._btnInListView
end

function UIControlItem:GetRootItem()
    local root = self
    while root._parentItem do
        root = root._parentItem
    end
    return root
end

--[[将该item以及 child_item 生成UI配置]]
function UIControlItem:DumpItemCfg()
    local t = table.deepcopy(self._cfg)
    
    --除去默认属性
    local defConf = g_uisystem.get_control_config(t['type_name']):GetDefConf()
    for k, v in pairs(t) do
        if k == 'child_list' then
            t.child_list = #self._childList > 0 and {} or nil
        elseif k == 'type_name' then
        elseif k == 'customize_info' then
            for _, conf in ipairs(v) do
                if is_table(conf['template_info']) and table.is_empty(conf['template_info']) then
                    conf['template_info'] = {}
                end

                if is_table(conf['template_info']) then
                   conf['template_info']['__template__'] = nil 
                end

                if conf.name == '' then
                    conf.name = nil
                end
            end
            if table.is_empty(v) then
                t[k] = nil
            end
        elseif k == 'ani_data' then
            -- 动画数据只有带有帧数据的项才会被保存
            for aniName, aniConf in pairs(v) do
                if table.is_empty(aniConf) or not is_array(aniConf) then
                    v[aniName] = nil
                else
                    table.arr_remove_if(aniConf, function(i, aniName)
                        if g_uisystem.load_ani_template(aniName) == nil then
                            return i, true
                        end
                    end)

                    if table.is_empty(aniConf) then
                        v[aniName] = nil
                    end
                end
            end
            if table.is_empty(v) then
                t[k] = nil
            end
        elseif k == 'template_info' then
            -- 删除v中的冗余数据
            for _k, _v in pairs(v) do
                if _k == '__template__' or table.count(_v) <= 0 then
                    v[_k] = nil
                end
            end

            if table.count(v) > 0 then
                t[k] = v
            else
                t[k] = nil
            end
        elseif k == 'size' and constant_uieditor['control_size_can_not_change'][self._cfg['type_name']] then
            -- 不能设置 size 的控件将不会保存 size 属性
            t[k] = nil
        elseif defConf[k] == nil or is_equal(v, defConf[k]) then
            t[k] = nil
        end
    end

    for _, sub_item in ipairs(self._childList) do
        table.insert(t.child_list, sub_item:DumpItemCfg())
    end
    return t
end

--[[判断是否是另一个 item 的祖先（相等也算）]]
function UIControlItem:IsAncestor(item)
    while item do
        if self == item then
            return true
        end
        item = item._parentItem
    end
end

--[[
    根据item 的config信息, 刷新控件属性
    刷新显示控件并刷新对应的selUI以及btnInListView
]]
function UIControlItem:RefreshItemControl(bReorderPosAndSize, bReloadControl)
    --remove child
    for _, v in ipairs(self._childList) do 
        v._control:retain()
        v._control:removeFromParent(false)
    end

    if bReloadControl then
        if self._parentItem then
            local parentCtrl = self._parentItem._control
            self._control:removeFromParent(true)
            self._control = g_uisystem.create_item(self._cfg, parentCtrl)

            -- reorder z
            local childList = self._parentItem._childList
            local pos = table.find_v(childList, self)
            for i = pos + 1, #childList do
                local item = childList[i]
                item._control:retain()
                item._control:removeFromParent(false)
                parentCtrl:addChild(item._control, item._cfg['zorder'])
                item._control:release()
            end
        else
            local parent = self._control:getParent()
            self._control:removeFromParent(true)
            self._control = g_uisystem.create_item(self._cfg, parent)
        end
    else
        --同步基础属性
        local pos = self._cfg['pos']
        self._control:SetPosition(pos.x, pos.y)
        self._control:setAnchorPoint(self._cfg['anchor'])
        local scale = self._cfg['scale']
        self._control:setScaleX(ccext_get_scale(scale.x))
        self._control:setScaleY(ccext_get_scale(scale.y))
        self._control:setRotation(self._cfg['rotation'])
        self._control:setVisible(not self._cfg['hide'])
        local size = self._cfg['size']
        self._control:SetContentSize(size.width, size.height)
    end

    --restore child
    for _, v in ipairs(self._childList) do
        self._control:addChild(v._control, v._cfg['zorder'])
        v._control:release()
    end

    if bReorderPosAndSize then
        local function _reorderSizeAndPosition(item)
            local ctrl = item:GetCtrl()

            if ctrl._x then
                ctrl:SetPosition(ctrl._x, ctrl._y)
            end

            if ctrl._w then
                ctrl:SetContentSize(ctrl._w, ctrl._h)
            end

            for _, item in ipairs(item._childList) do
                _reorderSizeAndPosition(item)
            end
        end
        _reorderSizeAndPosition(self)
    end

    --刷新显示控件并刷新对应的selUI以及btnInListView
    self:_updateItem()
end

--[[
    根据控件的属性值刷新对应配置属性,
    一般是通过可视化编辑改变控件属性进而同步到配置里面,
    此情况下需要对修改的配置进行备份.
]]
function UIControlItem:RefreshItemConfig(bReorderPosAndSize, bReloadControl)
    local ctrl = self._control
    local parentCtrl = self._control:getParent()
    local parent_size = CCSize(parentCtrl:GetContentSize())

    --刷新坐标信息
    local opos = self._cfg['pos']
    local osx, osy = opos.x, opos.y
    local x, y = ctrl:getPosition()
    local sx, sy = editor_utils_calc_str_position_by_type(osx, osy, x, y, parent_size)
    self._cfg['pos'] = {x = sx or osx, y = sy or osy}

    --刷新大小
    local width, height = ctrl:GetContentSize()
    if constant_uieditor['control_size_can_not_change'][self._cfg['type_name']] then
        self._cfg['size'] = {width = width, height = height}
    else
        local osize = self._cfg['size']
        local osw, osh = osize.width, osize.height
        local sw, sh = editor_utils_calc_str_position_by_type(osw, osh, width, height, parent_size)
        self._cfg['size'] = {width = sw or osw, height = sh or osh}
    end

    --anchor point
    local anchor = ctrl:getAnchorPoint()
    self._cfg['anchor'] = {x = round_scale(anchor.x), y = round_scale(anchor.y)}

    --刷新缩放
    if tonumber(self._cfg['scale'].x) then
        self._cfg['scale'].x = round_scale(ctrl:getScaleX())
    end
    if tonumber(self._cfg.scale.y) then
        self._cfg['scale'].y = round_scale(ctrl:getScaleY())
    end

    --刷新旋转角度
    pcall(function()
        -- rotationx y可能不一致而报错
        self._cfg['rotation'] = round_angle(ctrl:getRotation())
    end)

    --visibility
    self._cfg['hide'] = not self._control:isVisible()

    self:RefreshItemControl(bReorderPosAndSize, bReloadControl)
end

function UIControlItem:ConvertPos(osx, osy)
    local ctrl = self._control
    local parent_size = CCSize(ctrl:getParent():GetContentSize())

    local x, y = ctrl:getPosition()
    osx = osx or self._cfg['pos']['x']
    osy = osy or self._cfg['pos']['y']
    osx, osy = editor_utils_calc_str_position_by_type(osx, osy, x, y, parent_size, true)
    self._cfg['pos'] = ccp(osx, osy)
    self:RefreshItemControl()
end

function UIControlItem:ConvertSize(osx, osy)
    local ctrl = self._control
    local parent_size = CCSize(ctrl:getParent():GetContentSize())

    local x, y = ctrl:GetContentSize()
    osx = osx or self._cfg['size']['width']
    osy = osy or self._cfg['size']['height']
    osx, osy = editor_utils_calc_str_position_by_type(osx, osy, x, y, parent_size)
    self._cfg['size'] = CCSize(osx, osy)
    self:RefreshItemControl()
end

--[[判断pos坐标点中了哪个最上层的item]]
function UIControlItem:ItemForTouch(pos)
    -- 锁了的节点无法点中
    if self._cfg['lock'] then
        return
    end

    for _, v in ipairs(table.arr_reverse(self._childList)) do
        local item = v:ItemForTouch(pos)
        if item then
            return item
        end
    end
    if self:IsTouched(pos) then
        return self
    end
end

function UIControlItem:IsTouched(pos)
    if     self._control:IsVisible() and
        self._control:IsPointIn(pos) then
        return true
    end
end

--[[在世界坐标系下判断item是否完全在矩形内]]
function UIControlItem:IsItemInRect(l, t, r, b)
    local ctrl = self._control
    local width, height = ctrl:GetContentSize()
    local function IsPointIn(pt)
        return pt.x >= l and pt.x <= r and pt.y >= b and pt.y <= t
    end
    return IsPointIn(ctrl:convertToWorldSpace(ccp(0, 0))) and
            IsPointIn(ctrl:convertToWorldSpace(ccp(0, height))) and
            IsPointIn(ctrl:convertToWorldSpace(ccp(width, height))) and
            IsPointIn(ctrl:convertToWorldSpace(ccp(width, 0)))
end

--[[
    将处于矩形内的节点以及子节点加入到list中, l t r b 均为世界坐标系
    如果父节点已经处于rect内，则不加入子节点
]]
function UIControlItem:ItemInRect(l, t, r, b, list)
    -- 锁了的节点无法点中
    if self._cfg['lock'] then
        return
    end

    if self._control:IsVisible() then
        if self:IsItemInRect(l, t, r, b) then 
            table.insert(list, self)
        end

        for _, item in ipairs(self._childList) do
            item:ItemInRect(l, t, r, b, list)
        end
    end
end

--[[item 的选中状体始终与 list_objects 中的 btn 的选中状态保持一致]]
function UIControlItem:IsSelected()
    return self._listObjects:IsItemSelected(self._btnInListView)
end

--[[设置当前item的选中状态]]
function UIControlItem:SelectControlItem(bSelect)
    self._listObjects:MultiSelectItem(self._btnInListView, bSelect)
    self:_updateSelBGUI()
end

--[[items 必须为 k:item v:true 的结构]]
function UIControlItem:SelectUniqueItems(items)
    self:SelectControlItem(items[self] == true)
    for _, v in ipairs(self._childList) do
        v:SelectUniqueItems(items)
    end
end

--[[该节点及子节点中只选中指定节点，if item == nil then unselect all]]
function UIControlItem:SelectUniqueItem(item, bExband)
    self:SelectControlItem(self == item)
    if not bExband and item then
        self._listObjects:UnfoldSelectedItem(item._btnInListView)
    end

    for _, v in ipairs(self._childList) do
        v:SelectUniqueItem(item, true)
    end
end

--[[获取 item 的索引列表, 如果该 item 没有被选中则 return nil]]
function UIControlItem:GetSelectedIndex()
    if self:IsSelected() then
        return self._listObjects:GetItemIndex(self._btnInListView)
    end
end

function UIControlItem:GetSelectedIndexList(list)
    local sl = self:GetSelectedIndex()
    if sl then table.insert(list, sl) end
    for _, v in ipairs(self._childList) do
        v:GetSelectedIndexList(list)
    end
end

function UIControlItem:GetItemByIndexList(indexList)
    return self._listObjects:GetItemByIndexList(indexList).uicontrol_item
end

--更新操纵UI的显示
local selUINames = {'L',        'R',            'T',            'B',        'LT',       'RT',       'LB',   'RB'}
local selfUIPos  = {{0,'50%'},  {'i0','50%'},   {'50%','i0'},   {'50%',0},  {0,'i0'},   {'i0','i0'},{0,0},  {'i0',0}}


--[[注册selUI操纵item的基本事件回调(设置contentSize rotation scale position)]]
function UIControlItem:_regSelUIEvent()
    local objBk = self._selFrame
    objBk:setTouchEnabled(false)
    objBk:setTouchEnabled(true)

    -- edit move
    local selList --touch移动的时候选中的控件列表
    local selListOffset -- list 的坐标偏移
    local startPt
    
    objBk.OnBegin = function(pt)
        startPt = pt

        selList = self._panel.root_item:GetBFSSelItems()
        selListOffset = {}
        for _, v in ipairs(selList) do
            local worldPos = v._control:getParent():convertToWorldSpace(ccp(v._control:getPosition()))
            table.insert(selListOffset, {x = worldPos.x - pt.x, y = worldPos.y - pt.y})
        end
        return true
    end
    objBk.OnDrag = function(pt)
        for i, v in ipairs(selList) do
            local p = ccp(pt.x + selListOffset[i].x, pt.y + selListOffset[i].y)
            p = v._control:getParent():convertToNodeSpace(p)
            v._control:setPosition(p.x, p.y)
            v:_updateSelFrameTransform()
        end
    end
    objBk.OnEnd = function(pt)
        --OP
        if not is_equal(startPt, pt) then
            -- 防止空点
            for _, v in ipairs(selList) do
                v:RefreshItemConfig()
            end
            self._panel:RefreshSelItemPropertyConf()
            self._panel:EditPush()
        end
    end

    -- edit anchor
    local ctrlSize
    local anchorBeginP
    local anchorBeginPos
    local xl, xc, xr, yt, yc, yb
    
    objBk.anchor:setTouchEnabled(false)
    objBk.anchor:setTouchEnabled(true)
    objBk.anchor.OnBegin = function(pt)
        ctrlSize = CCSize(self._control:GetContentSize())
        xl, xc, xr, yt, yc, yb = -2.5, ctrlSize.width / 2, ctrlSize.width + 2.5, ctrlSize.height + 2.5, ctrlSize.height / 2, -2.5
        anchorBeginP = objBk:convertToNodeSpace(pt)
        anchorBeginP.x, anchorBeginP.y = round_scale(anchorBeginP.x), round_scale(anchorBeginP.y)
        anchorBeginPos = ccp(objBk.anchor:getPosition())
        return true
    end
    local function _is_equal(n1, n2)
        if math.abs(n1 - n2) <= 5 then
            return n2
        end
    end
    objBk.anchor.OnDrag = function(pt)
        pt = objBk:convertToNodeSpace(pt)
        pt.x = _is_equal(pt.x, xl) or _is_equal(pt.x, xc) or _is_equal(pt.x, xr) or anchorBeginPos.x + round_scale(pt.x) - anchorBeginP.x
        pt.y = _is_equal(pt.y, yt) or _is_equal(pt.y, yc) or _is_equal(pt.y, yb) or anchorBeginPos.y + round_scale(pt.y) - anchorBeginP.y
        objBk.anchor:setPosition(pt)
        local curAnchor = ccp((pt.x + 2.5) / (ctrlSize.width + 5), (pt.y + 2.5) / (ctrlSize.height + 5))
        self._panel:ShowTips('锚点坐标：(%.2f,%.2f)', curAnchor.x, curAnchor.y)
    end
    objBk.anchor.OnEnd = function(pt)
        local oldAnchor = self._control:getAnchorPoint()

        local x, y = objBk.anchor:getPosition()
        local curAnchor = ccp((x + 2.5) / (ctrlSize.width + 5), (y + 2.5) / (ctrlSize.height + 5))

        self._control:setAnchorPoint(curAnchor)

        x, y = self._control:getPosition()
        local sx, sy = self._control:getScaleX(), self._control:getScaleY()
        self._control:setPosition(ccp(x + ctrlSize.width * sx * (curAnchor.x - oldAnchor.x), y + ctrlSize.height * sy * (curAnchor.y - oldAnchor.y)))

        self:RefreshItemConfig()

        self._panel:EditPush()
        self._panel:RefreshSelItemPropertyConf()
    end

    -- edit size scale rotation
    for _, name in ipairs(selUINames) do
        local anchorPoint
        local posx, posy
        local anchorWPos
        local beginWPos  -- OnBegin点中的世界坐标
        local ctrl_down  -- 如果是 ctrl 按下则调整 scale 属性
        local alt_down  -- 如果是 atl 线下则调整旋转
        local oRotation  -- OnBegin 时 ctrl 的角度

        objBk[name]:setTouchEnabled(false)
        objBk[name]:setTouchEnabled(true)
        objBk[name].OnBegin = function(pt)
            anchorPoint = self._control:getAnchorPoint()
            posx, posy = self._control:getPosition()
            anchorWPos = self._control:getParent():convertToWorldSpace(ccp(posx, posy))
            beginWPos = pt
            ctrl_down = g_ui_event_mgr.is_ctrl_down()
            alt_down = g_ui_event_mgr.is_alt_down()

            if alt_down then
                xpcall(function()
                    oRotation = self._control:getRotation()
                end, function(msg)
                    oRotation = nil
                end)
            end
            return true
        end
        objBk[name].OnDrag = function(pt)
            --ctrl局部坐标系
            local lPos = self._control:convertToNodeSpace(pt)
            local osize = CCSize(self._control:GetContentSize())
            local anchorPos = ccp(osize.width * anchorPoint.x, osize.height * anchorPoint.y)

            if ctrl_down then
                --设置Scale
                local oscaleX, oscaleY = self._control:getScaleX(), self._control:getScaleY()
                local scaleX, scaleY = oscaleX, oscaleY

                if string.find(name, 'L') and lPos.x < anchorPos.x and anchorPoint.x > 0 then
                    scaleX = (anchorPos.x - lPos.x)/(anchorPoint.x * osize.width) * oscaleX
                elseif string.find(name, 'R') and lPos.x > anchorPos.x and anchorPoint.x < 1 then
                    scaleX = (lPos.x - anchorPos.x)/((1 - anchorPoint.x) * osize.width) * oscaleX
                end
                
                if string.find(name, 'B') and lPos.y < anchorPos.y and anchorPoint.y > 0 then
                    scaleY = (anchorPos.y - lPos.y)/(anchorPoint.y * osize.height) * oscaleY
                elseif string.find(name, 'T') and lPos.y > anchorPos.y and anchorPoint.y < 1 then
                    scaleY = (lPos.y - anchorPos.y)/((1 - anchorPoint.y) * osize.height) * oscaleY
                end

                if #name == 2 then
                    -- 四个边角等倍缩放比例
                    scale = round_scale(math.max(scaleX, scaleY))
                    self._control:setScale(scale)
                    self._panel:ShowTips('scale = %f', scale)
                else
                    scaleX = round_scale(scaleX)
                    scaleY = round_scale(scaleY)
                    self._control:setScaleX(scaleX)
                    self._control:setScaleY(scaleY)
                    self._panel:ShowTips('scaleX = %f, scaleY = %f', scaleX, scaleY)
                end
                self:_updateSelFrameTransform()
            elseif alt_down then
                if not oRotation then
                    return
                end
                --设置角度
                local p0 = ccp(beginWPos.x - anchorWPos.x, beginWPos.y - anchorWPos.y)
                local p1 = ccp(pt.x - anchorWPos.x, pt.y - anchorWPos.y)
                local cross = p0.x * p1.y - p0.y * p1.x
                local angle = math.acos((p0.x * p1.x + p0.y * p1.y) / math.sqrt((p0.x * p0.x + p0.y * p0.y) * (p1.x * p1.x + p1.y * p1.y)))
                local angle = math.radian2angle(angle)
                
                local rotation = cross > 0 and oRotation - angle or oRotation + angle
                local rotation = round_angle(rotation)
                self._control:setRotation(rotation)
                self._panel:ShowTips('当前旋转角度:%f度', rotation)
                self:_updateSelFrameTransform()
            else
                --设置contentSize
                local size = table.copy(osize)
                if string.find(name, 'L') and lPos.x < anchorPos.x and anchorPoint.x > 0 then
                    size.width = (anchorPos.x - lPos.x) / anchorPoint.x
                elseif string.find(name, 'R') and lPos.x > anchorPos.x and anchorPoint.x < 1 then
                    size.width = (lPos.x - anchorPos.x) / (1 - anchorPoint.x)
                end

                if string.find(name, 'B') and lPos.y < anchorPos.y and anchorPoint.y > 0 then
                    size.height = (anchorPos.y - lPos.y) / anchorPoint.y
                elseif string.find(name, 'T') and lPos.y > anchorPos.y and anchorPoint.y < 1 then
                    size.height = (lPos.y - anchorPos.y) / (1 - anchorPoint.y)
                end
                size.width = math.round_number(size.width)
                size.height = math.round_number(size.height)
                self._control:SetContentSize(size.width, size.height)
                self._panel:ShowTips('当前 width = %d height = %d', size.width, size.height)
                self:_updateSelFramePos()
            end
        end
        objBk[name].OnEnd = function(pt)
            self:RefreshItemConfig(true, true)
            self._panel:EditPush()

            self._panel:RefreshSelItemPropertyConf()
        end
    end
end

function UIControlItem:_updateSelFrameTransform()
    local p = self._control
    local transform = {}
    while p ~= self._panel.layerDevice do
        table.insert(transform, 1, p:getNodeToParentTransform())
        p = p:getParent()
    end
    self._selFrame:setNodeToParentTransform(table.arr_reduce(transform, mat4_multiply))
end

function UIControlItem:_updateSelFrameSizeAndTranForm()
    local w, h = self._control:GetContentSize()
    self._selFrame:SetContentSize(w, h)
    self:_updateSelFrameTransform()
end

function UIControlItem:_updateSelFramePos()
    local objBk = self._selFrame

    local w, h = self._control:GetContentSize()
    self._selFrame:SetContentSize(w, h)

    objBk.border:SetContentSize(w, h)
    objBk.border.c:SetPosition(w / 2, h / 2)

    local anchorPoint = self._control:getAnchorPoint()
    objBk.anchor:SetPosition(-2.5 + anchorPoint.x * (w + 5), -2.5 + anchorPoint.y * (h + 5))
    objBk.anchor:setVisible(w >= 20 and h >= 20)

    for i, name in ipairs(selUINames) do
        objBk[name]:SetPosition(selfUIPos[i][1], selfUIPos[i][2])

        if name == 'L' or name == 'R' or name == 'T' or name == 'B' then
            objBk[name]:setVisible(w >= 15 and h >= 15)
        end
    end

    -- 区别选中的控件
    objBk.border:SetLineColor(self == self._panel:GetSelectedControlItem() and ccc4aFromHex(0xff9F6099) or ccc4aFromHex(0xff0000FF))

    self:_updateSelFrameTransform()
end

--[[根据当前的选中状态更新selUI]]
function UIControlItem:_updateSelBGUI()
    if self:IsSelected() then
        -- selected
        if self._selFrame == nil then
            self._selFrame = g_uisystem.load_cached_template('editor/uieditor/uieditor_sel_control')
            self._panel.nodeSelFrames:addChild(self._selFrame, 1000000000)
            self:_regSelUIEvent()
        end
        self:_updateSelFramePos()
    else
        -- not selected
        if self._selFrame then
            self._selFrame:removeFromParent(true)
            self._selFrame = nil
        end
    end
end

--[[根据item的当前配置更新item关联的btnInlistView以及selFrame的显示]]
function UIControlItem:_updateItem()
    --选中UI
    self:_updateSelBGUI()
    self:_updateListViewItem()
end

function UIControlItem:_updateListViewItem()
    local btnInListView = self._btnInListView

    -- name
    local textContent
    local name = self._cfg['name']

    if name == '' then
        textContent = self._cfg['type_name']
    else
        if self._cfg.assign_root then
            textContent = string.format('[#c00ff00%s#n]%s', name, self._cfg['type_name'])
        else
            textContent = string.format('[P:#cff0000%s#n]%s', name, self._cfg['type_name'])
        end
    end

    local curAni = self._panel:GetCurSelAniName()
    if curAni then
        local aniConf = self:GetAniData()[curAni]
        if aniConf and not table.is_empty(aniConf) then
            textContent = textContent .. '->#cff0000Ani#n'
        end
    end

    btnInListView.text:SetString(textContent)

    -- visibility
    btnInListView.chVisible:SetCheck(self._control:isVisible())

    -- lock
    btnInListView.chLock:SetCheck(self._cfg['lock'])
    
    -- bg size
    local w, h = btnInListView.text:getContentSize().width + 45, 30
    btnInListView:SetContentSize(w, h)
    btnInListView['_selFrame_']:SetContentSize(w, h)
    btnInListView['_touchBg_']:SetContentSize(w, h)
    btnInListView.chLock:SetPosition('i3', '50%')
end



--utilities
function UIControlItem:ForEachItem(callback)
    local function visitItem(item)
        assert(item:GetCtrl():IsValid())
        local bPause = callback(item)
        if bPause then
            return
        else
            for _, subItem in ipairs(item:GetChildList()) do
                visitItem(subItem)
            end
        end
    end
    visitItem(self)
end

function UIControlItem:GetSelectedItems()
    local selItemList = {}

    local function getSelList(item)
        if item:IsSelected() then
            table.insert(selItemList, item)
        end

        for _, v in ipairs(item:GetChildList()) do
            getSelList(v)
        end
    end

    getSelList(self)

    return selItemList
end

function UIControlItem:GetNoSelParentSelItems()
    local selItemList = {}

    local function getSelList(item)
        if item:IsSelected() then
            table.insert(selItemList, item)
        else
            for _, v in ipairs(item:GetChildList()) do
                getSelList(v)
            end
        end
    end

    getSelList(self)

    return selItemList
end

--广度优先遍历item,按照父子顺序排序节点到 sortedList
function UIControlItem:GetBFSSelItems()
    local sortedList = {} --根据父子关系排序的列表
    
    local itemstack = {self}
    while #itemstack > 0 do
        local childList = {}
        for _, item in ipairs(itemstack) do
            if item:IsSelected() then
                table.insert(sortedList, item)
            end
            for _, childItem in ipairs(item:GetChildList()) do
                table.insert(childList, childItem)
            end
        end
        itemstack = childList
    end
    return sortedList
end
