--[[====================================
=
=         界面管理逻辑， 面板基类
=
========================================]]

BasePanel = CreateClass()

-- 构造函数，传入 父节点 和 模板名
-- override
function BasePanel:__init__(parent, panel_name, bMultiple, linkNode)
    if parent == nil then
        error_msg(parent ~= nil, 'create panel [%s] parent is nil', panel_name)
    end

    self._regAllNets = {}

    -- 记录面板名字
    self._panelName = panel_name
    self._bMultiple = bMultiple
    self._parent = parent
    self._layer = linkNode or self:on_create_template()
    self._layer.__related_panel__ = self

    -- init key event parms
    self._keyEventPriority = 0
    self._bSwallowKeyEvent = true
    self._panelNotSwallowKey = {}
    self._panelSwallowKey = {}

    -- 忽略处理返回的面板不注册事件
    self._layer:_regInnerEvent('OnEscClick')

    self._layer.OnEscClick = function()
        self:esc_key_close()
    end

    platform_report_panel_begin(self._panelName)
end

-- override
function BasePanel:on_get_template_name()
    assert(false)
end

-- override
function BasePanel:on_create_template()
    return g_uisystem.load_template_create(self:on_get_template_name(), self._parent, self)
end

-- override
function BasePanel:init_panel(...)
    error('to be override')
end

-- init_panel 之后被调用
-- override
function BasePanel:on_init_end()
end

-- 在面板销毁之前的清理操作，例如取消监听事件等
-- override
function BasePanel:on_before_destroy()
end

-- 按回退键被调用
-- override
function BasePanel:esc_key_close()
    self:close_panel()
end

-- 当前实例是否为 multiple
function BasePanel:is_multi_panel()
    return self._bMultiple
end

-- 获取面板的主层次，即cocos对象的根节点
function BasePanel:get_layer()
    return self._layer
end

-- 面板是否有效
function BasePanel:is_valid()
    return tolua_is_obj(self._layer)
end

function BasePanel:close_panel()
    g_panel_mgr.close(self)
end

-- 支持全局逻辑事件支持
function BasePanel:add_logic_event_callback(name, func, nPriority, bCallbackOnce)
    local function _callback(...)
        if self:_checkNodeValid() then
            return func(...)
        end
    end

    g_logicEventHandler:AddCallback(name, _callback, nPriority, bCallbackOnce, self)

    return _callback
end

function BasePanel:add_global_event_callback(name, func, nPriority, bCallbackOnce)
    local function _callback(...)
        if self:_checkNodeValid() then
            return func(...)
        end
    end

    g_eventHandler:AddCallback(name, _callback, nPriority, bCallbackOnce, self)

    return _callback
end

function BasePanel:add_game_event_callback(name, gameType, func, nPriority, bCallbackOnce)
    assert(g_game_mgr.is_game_event_valid(name))
    assert(g_game_mgr.is_game_type_valid(gameType))
    self:add_logic_event_callback(name, function(tp, game)
        if gameType == tp then
            func(game)
        end
    end, nPriority, bCallbackOnce)
end

-- 注册 data map 变更事件
function BasePanel:add_data_map_changed_callback(keys, callback, nPriority, bCallbackOnce)
    self:add_logic_event_callback('data_map_changed', function(ks, data)
        if self:_checkNodeValid() then
            if table.arr_is_equal(keys, ks) then
                callback(data)
            end
        end
    end, nPriority, bCallbackOnce)
end

function BasePanel:_checkNodeValid()
    if self:is_valid() then
        return true
    else
        self:_unregisterInnerEvent()
        __G__TRACKBACK__('node invalid,panel_name = '..self._panelName)
        return false
    end
end

function BasePanel:_unregisterInnerEvent()
    g_logicEventHandler:RemoveCallbackByBindObj(self)
    g_eventHandler:RemoveCallbackByBindObj(self)
    g_ui_event_mgr.remove_panel_key_event(self)
    for net, _ in pairs(self._regAllNets) do
        net:RemoveCallbackByBindObj(self)
    end
end

function BasePanel:add_key_event_callback(keys, bIncre, func)
    if is_function(bIncre) then
        func = bIncre
        bIncre = false
    end

    g_ui_event_mgr.add_panel_key_event(keys, bIncre, self, func)
end

function BasePanel:add_control_key_event_callback(keys, bIncre, func)
    local originKeys = table.copy(keys)
    self:add_key_event_callback(originKeys, bIncre, func)

    local ctrlKeys = table.copy(keys)
    table.insert(ctrlKeys, 1, 'KEY_CTRL')
    self:add_key_event_callback(ctrlKeys, bIncre, func)

    local altKeys = table.copy(keys)
    table.insert(altKeys, 1, 'KEY_ALT')
    self:add_key_event_callback(altKeys, bIncre, func)

    local shiftKeys = table.copy(keys)
    table.insert(shiftKeys, 1, 'KEY_SHIFT')
    self:add_key_event_callback(shiftKeys, bIncre, func)
end

function BasePanel:set_panel_key_event_priority(nPriority)
    self._keyEventPriority = nPriority
end

function BasePanel:set_panel_swallow_key_event(bSwallow)
    self._bSwallowKeyEvent = bSwallow
end

function BasePanel:get_panel_key_event_priority()
    return self._keyEventPriority
end

-- 对于 swallow 的面板可以设置哪些不 swallow 的事件
function BasePanel:set_panel_not_swallow_key_event_for_keys(keys, bTrue)
    local genKeys = g_ui_event_mgr.validate_and_parse_keys(keys)
    self._panelNotSwallowKey[genKeys] = bTrue
end

-- 对于不 swallow 的面板可以设置哪些 swallow 的事件
function BasePanel:set_panel_swallow_key_event_for_keys(keys, bTrue)
    local genKeys = g_ui_event_mgr.validate_and_parse_keys(keys)
    self._panelSwallowKey[genKeys] = bTrue
end

function BasePanel:is_stop_propagate(genKeys)
    if self._bSwallowKeyEvent then
        if self._panelNotSwallowKey[genKeys] then
            return false
        else
            return true
        end
    else
        if self._panelSwallowKey[genKeys] then
            return true
        else
            return false
        end
    end
end

-- override
function BasePanel:_destroy()
    if self:is_valid() then
        self:on_before_destroy()
        self._layer:removeFromParent()
        self:_unregisterInnerEvent()
        platform_report_panel_end(self._panelName)
    end
end

-- 注册网络回调事件窗口关闭的时候取消注册该网络事件
function BasePanel:register_net_event(net, command, callback, nPriority, bCallbackOnce)
    self._regAllNets[net] = true
    local function _callback(...)
        if self:_checkNodeValid() then
            return callback(...)
        end
    end
    net:RegisterNetEvent(command, _callback, nPriority, bCallbackOnce, self)

    return _callback
end

function BasePanel:get_panel_name()
    return self._panelName
end

-----------------------------------------------------
BaseDialogPanel = CreateClass(BasePanel)

-- override
function BaseDialogPanel:is_dialog()
    return true
end

function BaseDialogPanel:_show_open_ani()
    local popNode = self:_get_pop_node()
    if popNode then
        local origScaleX = popNode:getScaleX()
        local origScaleY = popNode:getScaleY()
        popNode:setScale(0.3)
        local sequenceAction = cc.Sequence:create(
            cc.EaseQuadraticActionOut:create(cc.ScaleTo:create(0.2, origScaleX + 0.1, origScaleY + 0.1)), 
            cc.EaseQuadraticActionOut:create(cc.ScaleTo:create(0.03, origScaleX, origScaleY)),
            cc.CallFunc:create(function()
                self:_on_open_ani_compelete()
            end)
        )
        popNode:runAction(sequenceAction)
    else
        error('dialog without pop node')
    end
end

function BaseDialogPanel:_show_close_ani()
    self:_get_pop_node():runAction(cc.Sequence:create(
        cc.ScaleTo:create(0.2, 0.2),
        cc.CallFunc:create(function()
            if self:is_valid() then
                self._layer:removeFromParent()
            end
        end)
    ))
end

-- override
function BaseDialogPanel:on_init_end()
    if self:is_dialog() then
        self:_show_blur_bg()
        self._is_open_ani_compelete = false
        self:_show_open_ani()
    end
end

-- override
function BaseDialogPanel:_destroy()
    if self:is_dialog() then
        if self:is_valid() then
            self:on_before_destroy()
            self:_unregisterInnerEvent()
            platform_report_panel_end(self._panelName)
            self:_show_close_ani()
        end
    else
        BasePanel._destroy(self)
    end
end

function BaseDialogPanel:_get_pop_node()
    assert(self:is_dialog())

    if self.lastPropNode then
        return self.lastPropNode
    end

    local popNode = nil
    if self.dlgRootNode then
        popNode = self.dlgRootNode
    else
        local layer = self:get_layer()
        local children = layer:getChildren()
        if #children > 1 then
            popNode = children[2]
        elseif #children == 1 then
            popNode = children[1]
        end
    end
    self.lastPropNode = popNode
    return popNode
end

--延迟处理

function BaseDialogPanel:register_net_event(net, command, callback, nPriority, bCallbackOnce)
    self._regAllNets[net] = true
    local function _callback(...)
        local call_func = function(...)
            if self:_checkNodeValid() then
                return callback(...)
            end
        end
        if self._is_open_ani_compelete ~= false then
            call_func(...)
        else
            if not self._delay_callbacks then
                self._delay_callbacks = {}
            end
            table.insert(self._delay_callbacks, {call_func, {...}})
        end
        
    end
    net:RegisterNetEvent(command, _callback, nPriority, bCallbackOnce, self)

    return _callback
end

function BaseDialogPanel:_on_open_ani_compelete()
    self._is_open_ani_compelete = true
    for _, callback_info in ipairs(self._delay_callbacks or {}) do
        local callback = callback_info[1]
        callback(unpack(callback_info[2]))
    end
end


function BaseDialogPanel:_show_blur_bg()

    if not cc_utils_is_support_sprite_ext_effect() then
        return
    end

    if self._is_show_blur_bg then
        self:get_layer():setVisible(false)
        local newSprite = cc_utils_capture_screen()
        self:get_layer():AddChild(nil, newSprite, -100)
        newSprite:SetPosition('50%', '50%')
        self._blurSprite = newSprite
        self:get_layer():setVisible(true)
    end
end