--[[
    websocket
]]
local netBase = import('net_websocket_base')
local GameNetBase = netBase.GameNet


local _all_nets = {}

local _netClassInfo = {}
local _nets = {}  -- 一般只允许每个net 一个实例
local _netSearchPath = {}
-- 服务端时间戳同步
local _serverTimeOffset = nil
local _min_send_heart_beat_delay = 100000000

function close_all_nets()
    print('begin close_all_nets')
    for net, _ in pairs(_all_nets) do
        print('close net', net._protosName)
        net:Close()
    end
    _all_nets = {}

    for name, net in pairs(_nets) do
        print('do close net', name)
        net:Close()
    end
    _nets = {}

    print('end close_all_nets')
end

-- deprecated
function get_all_nets()
    return _all_nets
end

-- 所有的 net 被创建后需要被此函数处理
local function on_create_net_obj(netObj)
    netObj:RegisterNetEvent('on_net_do_open', function()
        _all_nets[netObj] = true
    end)

    netObj:RegisterNetEvent('on_net_do_close', function()
        _all_nets[netObj] = nil
    end)

    netObj:RegisterNetEvent('on_net_heartbeat_time_delay', function(curTime, lastSendTime, stamp)
        local timeDelay = curTime - lastSendTime
        if _min_send_heart_beat_delay > timeDelay then
            -- print('set_min_heart_beat_delay', timeDelay)
            _min_send_heart_beat_delay = timeDelay

            _serverTimeOffset = stamp / 1000 - curTime
            g_logicEventHandler:Trigger('logic_servertime_update', _serverTimeOffset)
        end
    end)

    return netObj
end

-- deprecated
function new_net_obj(base)
    return on_create_net_obj(base and netBase[base]:New() or GameNetBase:New())
end

-- 获取服务器时间戳
function get_server_time_stamp()
    if _serverTimeOffset == nil then
        return os.time(), false
    else
        return utils_get_tick() + _serverTimeOffset, true
    end
end

function add_net_search_path(path, bFront)
    assert(not table.find_v(_netSearchPath, path))
    if bFront then
        table.insert(_netSearchPath, 1, path)
    else
        table.insert(_netSearchPath, path)
    end
end

function create_net(name, ...)
    assert_msg(_nets[name] == nil, 'net [%s] already created', name)

    local netClass = _netClassInfo[name]
    if netClass then
        netClass = netClass[1]
    else
        netClass = CreateClass(GameNetBase)
        local evn = {
            -- 对应的 net 定义模块需要实现 net 的各种方法
            Net = netClass,
            Super = GameNetBase,
        }
        for _, path in ipairs(_netSearchPath) do
            local mName = string.format('%s/%s', path, name)
            local m = direct_import(mName, evn)
            if m then
                _netClassInfo[name] = {netClass, m}
                break
            end
        end
    end

    local obj = netClass:New(...)
    _nets[name] = obj
    return on_create_net_obj(obj)
end

function get_net(name)
    return _nets[name]
end

function destroy_net(name)
    local net = _nets[name]
    if net then
        net:DestroyNet()
        _nets[name] = nil
        import_unload(_netClassInfo[name][2])
        _netClassInfo[name] = nil
    end
end
