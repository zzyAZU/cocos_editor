-- Net: cur net class
-- Super: base net class

-- override
function Net:__init__()
    Super.__init__(self)

    self:RegProtos(__name__, {
        CMD_LOGIN_REQ = 0,
        CMD_PRINT_LOG_REQ = 1,  -- 打日志
        CMD_PRINT_NET_LOG_REQ = 3,  -- 打网络日志

        CMD_EXECUTE_SCRIPTS_REQ = 7,  -- 请求执行脚本代码
        CMD_EXECUTE_SCRIPTS_RSP = 8,  -- 执行脚本代码
    })
end

-- override
function Net:on_proto_registered()
    Super.on_proto_registered(self)

    -- 不能打日志不然会造成递归死循环
    self:EnableNetLog(false)

    self:RegisterNetEvent('on_net_open', function()
        self:Send('CMD_LOGIN_REQ', {name = platform_get_device_name()..'___'..platform_get_device_id()})
        import('logic_init').start()
    end)

    self:RegisterNetEvent('on_net_close', function()
        delay_call(1, function()
            self:connect(self._connectUrl)
        end)

        import('logic_init').start()
    end)

    self:RegisterNetEvent('CMD_EXECUTE_SCRIPTS_RSP', function(data)
        -- message('CMD_EXECUTE_SCRIPTS_RSP')
        release_print('CMD_EXECUTE_SCRIPTS_RSP')
        xpcall(function()
            loadstring(data.code)()
        end, function(e)
            release_print(e)
        end)
    end)
end

function Net:connect(url)
    self._connectUrl = url
    self:Open(url)
end

function Net:print_log(msg)
    if self:IsConnected() then
        self:Send('CMD_PRINT_LOG_REQ', {msg = msg})
    end
end

function Net:print_net_log(msg, netName)
    if self:IsConnected() then
        self:Send('CMD_PRINT_NET_LOG_REQ', {
            msg = msg,
            netName = netName,
        })
    end
end

function Net:execute_dynamic_scripts()
    if self:IsConnected() then
        self:Send('CMD_EXECUTE_SCRIPTS_REQ')
    end
end
