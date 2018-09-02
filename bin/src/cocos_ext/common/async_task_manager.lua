--[[
分帧事件逻辑处理器
]]

local _taskList = {}
local _count = 0  -- 当前任务数量
local _curIndex = 0  -- 当前处理好的任务索引
local _curFrameExecT = 0

local _execDelta = 0.05  -- 每帧最大执行时间(每个函数的执行时间力度加起来会大于等于该值)
local _maxExecTime = 0.2  -- 每个 exec 函数最大执行时间


function set_execute_delta_time(t)
    _execDelta = t
end

function set_execute_max_time(t)
    _maxExecTime = t
end

local function _doDelayExecute()
    local preT = utils_get_tick()
    local i = _curIndex + 1

    while i <= _count do
        local info = _taskList[i]
        info[1](unpack(info[2]))  -- do execute
        _curIndex = i

        local curT = utils_get_tick()
        local costT = curT - preT
        if costT > _maxExecTime then
            printf('execute time [%f] > [%f] out:%s', costT, _maxExecTime, str(info))
        end

        _curFrameExecT = _curFrameExecT + costT

        if _curFrameExecT >= _execDelta then
            break
        end

        preT = curT
        i = i + 1
    end
end

local _delayExecute = nil
local function _delayCall()
    if _delayExecute then
        return
    end

    _delayExecute = delay_call(0, function()
        _curFrameExecT = 0
        _doDelayExecute()
        if _curIndex < _count then
            return 0.0001
        else
            _delayExecute = nil

            table.clear(_taskList)
            _curIndex = 0
            _count = 0
        end
    end)

    return true
end

function add_task(f, ...)
    _count = _count + 1
    _taskList[_count] = {f, {...}}  -- , debug.traceback()
    _delayCall()
end

function do_execute(fun, ...)
    if _curFrameExecT > _execDelta then
        _delayCall()
        return
    end

    local startT = utils_get_tick()
    local ret = {fun(...)}
    local costT = utils_get_tick() - startT
    if costT > _maxExecTime then
        printf('execute time [%f] > [%f] out', costT, _maxExecTime)
    end

    _curFrameExecT = _curFrameExecT + costT

    return true, unpack(ret)
end
