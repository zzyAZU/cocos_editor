--[[
    编辑模板动态属性
]]
local constant_uieditor = g_constant_conf['constant_uieditor']

Panel = g_panel_mgr.new_panel_class('editor/edit/uieditor_edit_container_template_attr')

-- overwrite
function Panel:init_panel(templateName, data, btn, callback)
    self:add_key_event_callback('KEY_ESCAPE', function()
        self:close_panel()
    end)

    self._layer.OnClick = function()
        self:close_panel()
    end


    self._data = table.deepcopy(data)
    self._callback = callback

    self._rootNodeConf = g_uisystem.gen_root_node_conf(templateName)

    self._curSelNodeName = nil

    self.btnAddTemplate.OnClick = function()
        table.insert(self._data, {['template'] = templateName, ['template_info'] = {}})
        self:_updateData()
        self._callback(self._data)
    end

    self:_updateData()

    local wpos = btn:convertToWorldSpace(ccp(0,0))
    self.bg:SetPosition(wpos.x, 25)
end

function Panel:_updateData()
    self.listAttr:SetInitCount(0)

    for i, v in ipairs(self._data) do
        -- add head
        local item = self.listAttr:AddTemplateItem(nil, true)
        -- item.name:SetString('template[{1}]', i)
        item.btnDelete.OnClick = function()
            table.remove(self._data, i)
            self:_updateData()
            self._callback(self._data)
        end

        -- add template Name
        local ctrl = editor_utils_create_edit_ctrls('edit_type_select_template', v['template'], {name = string.format('template%d', i)}, nil, function(value)
            v['template'] = value
            self:_updateData()
            self._callback(self._data)
        end):GetCtrl()

        self.listAttr:AddControl(ctrl, nil, true)

        -- add dynamic attr
        local parm = {
            name = string.format('动态属性%d', i),
            edit_template = v['template'],
        }
        local ctrl = editor_utils_create_edit_ctrls('edit_type_template_info', v['template_info'], parm, nil, function(value)
            v['template_info'] = value
            -- 改动态属性的时候是不能刷新的
            -- self:_updateData()
            self._callback(self._data)
        end):GetCtrl()

        self.listAttr:AddControl(ctrl, nil, true)
    end

    self.listAttr:_refreshContainer()
end