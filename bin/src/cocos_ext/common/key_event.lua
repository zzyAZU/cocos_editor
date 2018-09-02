--按键事件
local _keyListener = nil

local _keyPressState = {}
local _listPressKeys = {}

local _panelKeyCallbackMap = {}

local _curOrderedPanelList = {}

local _commonKeyCallbackList = {}


function is_key_pressed(key)
    local keyCode = cc.KeyCode[key]
    assert(keyCode)
    return _keyPressState[keyCode] == true
end

function is_ctrl_down()
    return is_key_pressed('KEY_CTRL')
end

function is_alt_down()
    return is_key_pressed('KEY_ALT')
end

function is_shift_down()
    return is_key_pressed('KEY_SHIFT')
end

local function _updateTopPanel()
    _curOrderedPanelList = {}

    local panelLayers = {}
    for panel, _ in pairs(_panelKeyCallbackMap) do
        assert(panel:is_valid())
        panelLayers[panel:get_layer()] = panel
    end

    local curScene = g_director:getRunningScene()
    if curScene == nil then
        return delay_update_panel_order()
    end

    local function searchNode(node)
        if not node:isVisible() then
            return
        end

        local children = node:getChildren()
        local negIndex

        -- zorder >= 0
        for i = #children, 1, -1 do
            local child = children[i]
            if child:getLocalZOrder() >= 0 then
                searchNode(child)
            else
                negIndex = i
                break
            end
        end

        -- self
        local p = panelLayers[node]
        if p then
            local priority = p:get_panel_key_event_priority()
            local l = _curOrderedPanelList[priority]
            if l == nil then
                l = {}
                _curOrderedPanelList[priority] = l
            end
            table.insert(l, p)
        end

        -- zorder < 0
        if negIndex then
            for i = negIndex, 1, -1 do
                local child = children[i]
                searchNode(child)
            end
        end
    end

    searchNode(curScene)
end

local _delaySchedule
function delay_update_panel_order()
    if _delaySchedule == nil then
        _delaySchedule = delay_call(0, function()
            _delaySchedule = nil
            _updateTopPanel()
        end)
    end
end

local function _cmpKeysLess(v1, v2)
    return v1 < v2
end

local function _onKeyEvent(genKeys, bIncreI)
    if bIncreI == false then
        _updateTopPanel()
    end

    -- panel key event
    for _, listPanel in sorted_pairs(_curOrderedPanelList, _cmpKeysLess) do
        local bStop = false
        for _, curPanel in ipairs(listPanel) do
            local listData = _panelKeyCallbackMap[curPanel][genKeys]
            if listData then
                for _, data in ipairs(table.copy(listData)) do
                    local keys, bIncre, func = unpack(data)
                    if bIncre == true or bIncreI == false then
                        func()
                    end
                end
            end

            if curPanel:is_stop_propagate(genKeys) then
                bStop = true
                break
            end
        end

        if bStop then
            break
        end
    end

    -- common key event callback
    local dataList = _commonKeyCallbackList[genKeys]
    if dataList then
        for _, data in ipairs(table.copy(dataList)) do
            local bIncre, bSwallowEvent, _, func = unpack(data)
            if bIncre == true or bIncreI == false then
                func()
            end

            if bSwallowEvent then
                break
            end
        end
    end
end

function validate_and_parse_keys(keys)
    -- validate keys
    if is_table(keys) then
        for i, k in ipairs(keys) do
            if is_string(k) then
                local keyCode = cc.KeyCode[k]
                if keyCode then
                    keys[i] = keyCode
                else
                    error_msg('keyCode [%s] not valid', keyCode)
                end
            end
        end
    else
        if is_string(keys) then
            keys = cc.KeyCode[keys]
        end
        assert(is_number(keys))
        keys = {keys}
    end

    return table.concat(keys, '|')
end

local function _initKeyEvent()
    print('init key event')

    assert(_keyListener == nil)
    -- key
    local keyListener = cc.EventListenerKeyboard:create()

    local keyPressDelayTrigger
    keyListener:registerScriptHandler(function(keyCode, event)
        -- print('logic_key_event', keyCode, true)
        _keyPressState[keyCode] = true
        table.insert(_listPressKeys, keyCode)

        local genKeys = validate_and_parse_keys(_listPressKeys)

        if keyPressDelayTrigger then
            keyPressDelayTrigger('cancel')
        end

        local delayTime = 0.2
        keyPressDelayTrigger = delay_call(delayTime, function()
            _onKeyEvent(genKeys, true)
            if delayTime > 0 then
                delayTime = delayTime - 0.02
            end
            return delayTime
        end)

        _onKeyEvent(genKeys, false)

        -- print(cc.KeyCodeKey[keyCode + 1])
        -- local listKeys = {}
        -- for _, v in ipairs(_listPressKeys) do
        --     table.insert(listKeys, cc.KeyCodeKey[v + 1])
        -- end
        -- print(table.concat(listKeys, ' '))
    end, cc.Handler.EVENT_KEYBOARD_PRESSED)

    keyListener:registerScriptHandler(function(keyCode, event)
        _keyPressState[keyCode] = nil
        table.arr_remove_v(_listPressKeys, keyCode)
        if keyPressDelayTrigger then
            keyPressDelayTrigger('cancel')
            keyPressDelayTrigger = nil
        end
    end, cc.Handler.EVENT_KEYBOARD_RELEASED)

    g_eventDispatcher:addEventListenerWithFixedPriority(keyListener, 1)

    _keyListener = keyListener
end



--[[
    注册一个按键事件：
    key:注册的按键， 如果key为一个列表 则 按下列表中的任意一个键都会触发该事件
    bIncre:事件触发时 触发的是连续按下事件
    注：如果指定的节点不可见则无法触发相关按键回调
    
    node:事件关联的节点(如果节点已经销毁，则事件自动被移除), 如果不需要可设置为nil
    func:注册的回调
]]
function add_panel_key_event(keys, bIncre, panel, func)
    local genKeys = validate_and_parse_keys(keys)
    assert(is_boolean(bIncre))
    assert(is_function(func))
    assert_msg(panel and panel:is_valid(), 'add_panel_key_event panel [%s] not valid', str(panel))

    local callbakckInfo = _panelKeyCallbackMap[panel]
    if callbakckInfo == nil then
        callbakckInfo = {}
        _panelKeyCallbackMap[panel] = callbakckInfo
    end

    local listData = callbakckInfo[genKeys]
    if listData == nil then
        listData = {}
        callbakckInfo[genKeys] = listData
    end

    table.insert(listData, {keys, bIncre, func})

    delay_update_panel_order()

    if _keyListener == nil then
        _initKeyEvent()
    end
end

function remove_panel_key_event(panel, keys)
    if panel == nil then
        -- remove all
        _panelKeyCallbackMap = {}
    elseif keys == nil then
        -- remove panel
        _panelKeyCallbackMap[panel] = nil
    elseif _panelKeyCallbackMap[panel] then
        local genKeys = validate_and_parse_keys(keys)
        _panelKeyCallbackMap[panel][genKeys] = nil
    end

    delay_update_panel_order()
end

function add_common_key_event(keys, bIncre, bSwallowEvent, priority, func)
    local genKeys = validate_and_parse_keys(keys)
    assert(is_boolean(bIncre))
    assert(is_number(priority))
    assert(is_function(func))

    local listData = _commonKeyCallbackList[genKeys]
    if listData == nil then
        listData = {}
        _commonKeyCallbackList[genKeys] = listData
    end

    -- priority 从小到大
    table.arr_insert_if(listData, {bIncre, bSwallowEvent, priority, func}, function(i, v)
        if v[3] > priority then
            return i
        end
    end)

    if _keyListener == nil then
        _initKeyEvent()
    end
end

function remove_common_key_event(keys, func, bRemoveAll)
    if keys == nil then
        -- remove all
        _commonKeyCallbackList = {}
        return
    end

    local genKeys = validate_and_parse_keys(keys)
    local listData = _commonKeyCallbackList[genKeys]

    if listData then
        if func then
            table.arr_remove_if(listData, function(i, v)
                if v[4] == func then
                    return i, bRemoveAll
                end
            end)
        else
            _commonKeyCallbackList[genKeys] = nil
        end
    end
end
