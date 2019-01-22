--[[====================================
=
=           TemplateNode 扩展
=
========================================]]
local TemplateNode, Super = tolua_get_class('TemplateNode')

--class 的 metatable 引用不到基类
--override
function TemplateNode:Create()
    return cc.Node:create():CastTo(self):_init()
end

--override
function TemplateNode:_init()
    Super._init(self)
    self._templateConf = nil
    return self
end

--override
function TemplateNode:_registerInnerEvent()
    Super._registerInnerEvent(self)

    self:_regInnerEvent('on_load')
end

function TemplateNode:SetTemplate(templateName, templateInfo)
    local conf = g_uisystem.load_template(templateName, templateInfo)
    assert(conf)
    self._templateConf = conf
end

function TemplateNode:DoLoad(async)
    assert(self._templateConf)
    if async then
        local ok = g_async_task_mgr.do_execute(function()
            g_uisystem.create_item(self._templateConf, self, self)
            self.eventHandler:Trigger('on_load')
        end)
        if not ok then
            self:DelayCall(0.001, function()
                self:DoLoad(true)
            end)
        end
    else
        g_uisystem.create_item(self._templateConf, self, self)
    end
end