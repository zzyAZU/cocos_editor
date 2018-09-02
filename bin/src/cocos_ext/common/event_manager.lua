--[[====================================
=
=         事件机制
=
========================================]]
local _all_events = setmetatable({}, {
    __mode = 'k',
})

--用于处理事件分发的类
local EventHandler = import('event_handler').EventHandler

function new_event_handler()
    local ret = EventHandler:New()
    _all_events[ret] = true
    return ret
end

function remove_all_events()
    for eventHandler, _ in pairs(_all_events) do
        eventHandler:RemoveCallback()
    end

    _all_events = setmetatable({}, {
        __mode = 'k',
    })
end