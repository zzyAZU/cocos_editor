local _mouseListener = nil
local _mouseCallbackMap = {}  -- 鼠标移动事件

local _nodeZorderList = {}  -- z 次序由高到底排列

-- 只处理无按键下的鼠标移动
local _curFocusedNode = nil

local function _updateNodeZorderList()
    _nodeZorderList = {}
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

        if _mouseCallbackMap[node] then
            table.insert(_nodeZorderList, node)
        end

        -- zorder < 0
        if negIndex then
            for i = negIndex, 1, -1 do
                searchNode(children[i])
            end
        end
    end

    local scene = g_director:getRunningScene()
    if scene then
        searchNode(scene)
    end

    if table.is_empty(_nodeZorderList) and _mouseListener then
        g_eventDispatcher:removeEventListener(_mouseListener)
        _mouseListener = nil
        g_logicEventHandler:RemoveCallback('logic_event_on_drop_file')
    end
end

local function _nodeForTouch(pt)
    for _, node in ipairs(_nodeZorderList) do
        if node:IsPointIn(pt) then
            return node
        end
    end
end

function remove_mouse_event(node)
    local data = _mouseCallbackMap[node]
    assert(data)
    _mouseCallbackMap[node] = nil
end

local function _onMouseMove(pos)
    _updateNodeZorderList()

    local oldFocusedNode = _curFocusedNode
    _curFocusedNode = _nodeForTouch(pos)
    --先处理旧的节点的相关消息 先触发 MoveOutSide
    if oldFocusedNode and oldFocusedNode:IsValid() and oldFocusedNode ~= _curFocusedNode then
        local v = _mouseCallbackMap[oldFocusedNode]
        assert(v.node == oldFocusedNode)
        --  inside -> outside
        assert(v.bMoveInside)
        v.bMoveInside = false
        oldFocusedNode.eventHandler:Trigger('OnMouseMove', false, nil, true)
    end

    for _, v in pairs(table.copy(_mouseCallbackMap)) do
        local node = v.node
        if node:IsValid() then
            if _curFocusedNode == node then
                -- inside
                if v.bMoveInside then
                    node.eventHandler:Trigger('OnMouseMove', true, pos, false)
                else
                    -- outside -> inside
                    v.bMoveInside = true
                    node.eventHandler:Trigger('OnMouseMove', true, pos, true)
                end
            else
                -- outside
                if v.bMoveInside then
                    -- inside -> outside
                    v.bMoveInside = false
                    node.eventHandler:Trigger('OnMouseMove', false, pos, true)
                end
            end
        else
            remove_mouse_event(node)
        end
    end
end

local function _initMouseEvent()
    assert(_mouseListener == nil)

    local mouseListener = cc.EventListenerMouse:create()

    -- mouse click
    mouseListener:registerScriptHandler(function(event)
        -- print('EVENT_MOUSE_DOWN', event:getMouseButton())
        if _curFocusedNode and _curFocusedNode:IsValid() then
            local pos = event:getLocationInView()
            _curFocusedNode.eventHandler:Trigger('OnMouseDown', event:getMouseButton(), pos)
        end
    end, cc.Handler.EVENT_MOUSE_DOWN)

    mouseListener:registerScriptHandler(function(event)
        -- print('EVENT_MOUSE_UP', event:getMouseButton())
        if _curFocusedNode and _curFocusedNode:IsValid() then
            local pos = event:getLocationInView()
            _curFocusedNode.eventHandler:Trigger('OnMouseUp', event:getMouseButton(), pos)
        end
    end, cc.Handler.EVENT_MOUSE_UP)


    local timer_id = nil
    local function _timerCall(fun)
        if timer_id then
            return
        end

        timer_id = delay_call(0, function()
            fun()
            timer_id = nil            
        end)
    end


    -- mouse move
    local lastMovePos = nil
    mouseListener:registerScriptHandler(function(event)
        lastMovePos = event:getLocationInView()
        _timerCall(function()
            -- print('EVENT_MOUSE_MOVE', str(lastMovePos))
            _onMouseMove(lastMovePos)
            lastMovePos = nil
        end)
    end, cc.Handler.EVENT_MOUSE_MOVE)

    -- mouse wheel
    local curScrollY = 0
    mouseListener:registerScriptHandler(function(event)
        curScrollY = curScrollY + event:getScrollY()
        _timerCall(function()
            -- print('EVENT_MOUSE_SCROLL', curScrollY)
            if _curFocusedNode and _curFocusedNode:IsValid() then
                _curFocusedNode.eventHandler:Trigger('OnMouseWheel', curScrollY)
            end
            curScrollY = 0
        end)
    end, cc.Handler.EVENT_MOUSE_SCROLL)

    g_eventDispatcher:addEventListenerWithFixedPriority(mouseListener, 1)

    _mouseListener = mouseListener

    g_logicEventHandler:AddCallback('logic_event_on_drop_file', function(filePaths, pt)
        _onMouseMove(pt)
        -- 每一个拖拽到目标
        for _, node in ipairs(_nodeZorderList) do
            if node:IsPointIn(pt) then
                node.eventHandler:Trigger('OnDropFile', filePaths, pt)
            end
        end
    end)

    g_logicEventHandler:AddCallback('logic_event_restart_app', function()
        if mouseListener then
            g_eventDispatcher:removeEventListener(mouseListener)
            mouseListener = nil
        end
    end)
end


--[[
    为指定节点注册一个鼠标移动的事件，控件的默认状态为 move out side
    注意：MouseEvent 只与节点相关
]]
function add_mouse_event(node)
    assert(node:IsValid())

    -- 非 windows 系统不支持 鼠标事件
    if g_application:getTargetPlatform() ~= cc.PLATFORM_OS_WINDOWS then
        return
    end

    if _mouseListener == nil then
        _initMouseEvent()
    end

    if _mouseCallbackMap[node] then
        return
    end

    --默认鼠标不在节点里面
    local data = {node = node, bMoveInside = false}
    _mouseCallbackMap[node] = data
end
