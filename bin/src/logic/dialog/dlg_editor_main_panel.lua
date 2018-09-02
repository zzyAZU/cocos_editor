--[[编辑器主面板]]

Panel = g_panel_mgr.new_panel_class('editor/editor_main_ui')

local constant_uieditor = g_constant_conf['constant_uieditor']
local constant_uisystem = g_constant_conf['constant_uisystem']

-- overwrite
function Panel:init_panel()
    self.uieditorPanel = g_panel_mgr.show_with_parent('dlg_uieditor_main_panel', self.nodeSub)
    self.anieditorPanel = g_panel_mgr.show_with_parent('dlg_anieditor_main_panel', self.nodeSub)

    cc.CCCheckButton.LinkCheckView({self.checkUI, self.checkAni}, {self.uieditorPanel:get_layer(), self.anieditorPanel:get_layer()}, 1)

    self:set_panel_key_event_priority(-999999)
    self:set_panel_swallow_key_event(false)
    -- quick switch ui <-> ani
    self:add_key_event_callback({'KEY_SHIFT', 'KEY_TAB'}, function()
        if self.checkUI:GetCheck() then
            self:ShowActionAniEditor()
        else
            self:ShowUIEditor()
        end
    end)

    self:add_logic_event_callback('logic_event_on_drop_file', bind(self._on_drop_file, self))
end

function Panel:ShowUIEditor()
    self.checkUI:SetCheck(true, true)
end

function Panel:ShowActionAniEditor()
   self.checkAni:SetCheck(true, true) 
end

--拖拽文件
function Panel:_on_drop_file(filePath, position)

    local project_res_path = g_logic_editor:get_project_res_path()
    filePath = string.gsub(filePath, "\\", "/")
    local begin_project_res_index, end_project_res_index = string.find(filePath, project_res_path)
    if begin_project_res_index == nil then
        message('请选择当前项目res目录资源')
        return
    end
    
    local releative_path = string.sub(filePath, end_project_res_index + 1)
    local suffix_format_begin_index, suffix_format_end_index = string.find(releative_path, "%.")
    if not suffix_format_begin_index then
        return
    end
    local suffix_str = string.sub(releative_path, suffix_format_end_index + 1)
    local file_suffix_to_node_conf = constant_uieditor.file_suffix_to_node[suffix_str]
    if not file_suffix_to_node_conf then
        message('没有找到文件类型配置，请选择有效的文件')
        return
    end
    if file_suffix_to_node_conf.check_sub_type_policy then
        local policy_func = file_suffix_to_node_conf.check_sub_type_policy
        local is_valid, sub_type = policy_func(releative_path)
        if is_valid then
            if sub_type ~= suffix_str then
                file_suffix_to_node_conf = file_suffix_to_node_conf[sub_type]    
            end
        else
            message('没有找到子格式，请选择有效的文件')
            return
        end
    end
    
    if file_suffix_to_node_conf then
        local drag_policy_func_name = file_suffix_to_node_conf['drag_policy'] or "drag_generate_ui_node"
        if drag_policy_func_name then
            self[drag_policy_func_name](self, releative_path, file_suffix_to_node_conf,position)
        end
    end
end

--生成节点
function Panel:drag_generate_ui_node(releative_path, conf, position)
    local defConf = conf.defConf or table.deepcopy(constant_uisystem.default_control_value[conf.type_name])

    for _, param in ipairs(conf.params or {}) do
        local cur_conf = defConf
        local file_key_path = param.file_key_path
        local keys = string.split(file_key_path, ".")
    
        for index, key in ipairs(keys or {}) do
            if index ~= #keys then
                local sub_conf = defConf[key] or {}
                defConf[key] = sub_conf
                cur_conf = sub_conf
            else
                local change_param = param.change_param
                if change_param then
                    releative_path = change_param(releative_path)
                end
                cur_conf[key] = releative_path
            end
        end
    end

    local panel = g_multi_doc_manager.get_cur_open_panel()
    if not panel then
        message('当前没有打开任何配置文件，无法操作')
        return
    end

    local item = panel:GetSelectedControlItem() or panel.root_item

    if position then

        local parentItem = item
        if item ~= panel.root_item and (g_ui_event_mgr.is_ctrl_down() or g_ui_event_mgr.is_alt_down()) then
            parentItem = item:GetParentItem()
            defConf.pos = position
        else
            local localPosition = parentItem:GetCtrl():convertToNodeSpace(position)
            localPosition.x = math.floor(localPosition.x)
            localPosition.y = math.floor(localPosition.y)
            defConf.pos = localPosition
        end
    end
    panel:AddUIControlItem(conf.type_name, defConf)
end

--打开ui文件
function Panel:drag_open_ui_template(releative_path, conf)
    local ui_template_index = string.find(releative_path, constant_uisystem.template_path)
    if not ui_template_index then
        return
    end
    
    local releative_ui_name = string.sub(releative_path, ui_template_index + #constant_uisystem.template_path, -#constant_uieditor.config_file_ext - 1)
    if not self.checkUI:GetCheck() then
        self:ShowUIEditor()
    end
    g_multi_doc_manager.open_file(releative_ui_name)
end

function Panel:drag_open_anim_tempelate(releative_path, conf)
    local ani_template_index = string.find(releative_path, constant_uisystem.ani_template_path)
    if not ani_template_index then
        return
    end
    
    local releative_ani_name = string.sub(releative_path, ani_template_index + #constant_uisystem.ani_template_path, -#constant_uieditor.config_file_ext - 1)
    if not self.checkAni:GetCheck() then
        self:ShowActionAniEditor()
    end
    g_ani_multi_doc_manager.open_file(releative_ani_name)
end