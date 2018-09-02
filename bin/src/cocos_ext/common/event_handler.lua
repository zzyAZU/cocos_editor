--[[====================================
=
=         事件机制
=
========================================]]

--用于处理事件分发的类
EventHandler = CreateClass()

-- 支持 newHandler.eventName = callback 的方式快捷注册事件
function EventHandler:__init__()
    self._bTriggeringEvent = {}

    self._eventMap = {}         --key 事件类型, value  callData list
    self._callbackInfoMap = {}  --key 事件类型, value  事件回调数据映射： func - callData
    self._nDefPriority = 0

    self._bindObjectEvents = {}  -- 记录与某对象绑定的事件

    self._delayTrigger = {}

    -- 快捷注册新事件回调方式
    self.newHandler = setmetatable({}, {__newindex = function(t, name, func)
        self:AddCallback(name, func)
    end})
end

--注册ui事件，允许同一个事件对应多个回调
function EventHandler:RegisterEvent(name)
    assert(not self._eventMap[name] and not self._callbackInfoMap[name])

    self._eventMap[name] = {}
    self._callbackInfoMap[name] = {}
end

function EventHandler:IsEventReg(name)
    return self._eventMap[name] ~= nil
end

function EventHandler:SetDefaultPriority(nPriority)
    self._nDefPriority = nPriority
end

-- 增加一个事件回调
-- name: 事件名称
-- nPriority: 事件接收的优先级
-- 注意：同一个事件的同一个函数只能注册一次
function EventHandler:AddCallback(name, func, nPriority, bCallbackOnce, bindObject)
    nPriority = nPriority or self._nDefPriority
    
    assert(is_function(func))

    if self._eventMap[name] == nil then
        local eventNames = {}
        for name in pairs(self._eventMap) do
            table.insert(eventNames, name)
        end
        error_msg('event [%s] not valid available evnet name are:%s', name, str(eventNames))
    end
    assert(self._callbackInfoMap[name])
    assert(not self._callbackInfoMap[name][func])
    
    --callbackData struct:
    --                  1       2       3
    local callData = {name, func, nPriority, bCallbackOnce}
    self._callbackInfoMap[name][func] = callData
    table.arr_rinsert_if(self._eventMap[name], callData, function(i, v)
        if v[3] <= nPriority then 
            return i + 1 
        end
    end)

    if bindObject then
        local bindObjMap = self._bindObjectEvents[bindObject]
        if bindObjMap == nil then
            bindObjMap = {}
            self._bindObjectEvents[bindObject] = bindObjMap
        end

        local st = bindObjMap[name]
        if st == nil then
            st = {}
            bindObjMap[name] = st
        end
        st[func] = true
    end
end

function EventHandler:AddCallbackOnce(name, func, nPriority, bindObject)
    self:AddCallback(name, func, nPriority, true, bindObject)
end

-- 移除一个事件回调，if func == None remove all
-- 支持传一个函数移除，这样的话默认删除的事件为函数的名称
-- 如果只传事件名称则会删除所有的回调(慎用)
function EventHandler:RemoveCallback(name, func)
    if name == nil then
        -- remove all callback
        for k, _ in pairs(self._eventMap) do
            self._eventMap[k] = {}
        end

        for k, _ in pairs(self._callbackInfoMap) do
            self._callbackInfoMap[k] = {}
        end
    else
        if func then
            local callData = self._callbackInfoMap[name][func]
            if not callData then return end
            self._callbackInfoMap[name][func] = nil
            table.arr_remove_v(self._eventMap[name], callData)
        else
            --删除所有的回调
            self._eventMap[name] = {}
            self._callbackInfoMap[name] = {}
        end
    end

    return true
end

-- 将指定优先级的事件给移除掉
-- bRemoveLessPriority： if bRemoveLessPriority == true then 比指定优先级还要低的事件也会被移除
function EventHandler:RemoveCallbackByPriority(name, nPriority)
    local callbackInfo = self._callbackInfoMap[name]
    if not callbackInfo then return end

    local removed = table.arr_remove_if(self._eventMap[name], function(i, v)
        if v[3] == nPriority then
            return i, true
        end
    end)
    
    for _, data in ipairs(removed) do
        callbackInfo[data[2]] = nil
    end
end

-- @desc:
--  根据 func 的返回值移除指定事件回调 func 传入的参数为 对应事件的priority参数
--  func 的参数与返回值与 table.arr_remove_if 的 func 一致
function EventHandler:RemoveCallbackByCondition(name, func)
    local callbackInfo = self._callbackInfoMap[name]
    if not callbackInfo then return end
    for _, data in ipairs(table.arr_remove_if(self._eventMap[name], func)) do
        callbackInfo[data[2]] = nil
    end
end

function EventHandler:RemoveCallbackByBindObj(bindObject)
    local bindObjMap = self._bindObjectEvents[bindObject]
    if bindObjMap == nil then
        return
    end

    for eventName, setCallback in pairs(bindObjMap) do
        for callback in pairs(setCallback) do
            self:RemoveCallback(eventName, callback)
        end
    end

    self._bindObjectEvents[bindObject] = nil
end

-- @desc:
--  触发指定事件，返回所有事件触发后返回的值列表
--  如果事件返回的第二个值为 true 则 swallow
function EventHandler:Trigger(name, ...)
    assert(self._eventMap[name], name)

    if self._bTriggeringEvent[name] then
        printf('error! event [%s] already in trigger', name)
        return
    end

    self._bTriggeringEvent[name] = true

    local ret = {}
    local bSwalow
    local nCount = 0

    local callbackOnceList = {}
    local args = {...}

    for i, data in ipairs(table.copy(self._eventMap[name])) do
        nCount = nCount + 1
        xpcall(function()
            ret[i], bSwalow = data[2](unpack(args, 1, table.maxn(args)))
        end, __G__TRACKBACK__)

        if data[4] then
            table.insert(callbackOnceList, data[2])
        end
        
        --swallow
        if bSwalow then break end
    end
    ret.__count__ = nCount

    self._bTriggeringEvent[name] = nil

    for _, v in ipairs(callbackOnceList) do
        -- 这里要容错下，因为现在确实可能任何情况一个事件被移除
        self:RemoveCallback(name, v)
    end
    return ret
end

function EventHandler:DelayTrigger(name, ...)
    local bEmpty = table.is_empty(self._delayTrigger)
    table.insert(self._delayTrigger, {name, {...}, select('#', ...)})

    if bEmpty then
        delay_call(0, function()
            for _, info in ipairs(self._delayTrigger) do
                self:Trigger(info[1], unpack(info[2], 1, info[3]))
            end
            self._delayTrigger = {}
        end)
    end
end
