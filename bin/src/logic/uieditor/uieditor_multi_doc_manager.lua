--[[
    UI编辑器多文档管理
    g_multi_doc_manager 单例
]]
local constant_uieditor = g_constant_conf.constant_uieditor

local _curPanel = nil     -- 当前打开显示的界面
local _openPanelOrder = {}  -- 打开显示的面板序列
local _openPanelList = {}  -- 打开的所有文档对应的panel(tab页从左到右的显示序列)

-- 保存最近打开的模板配置
local function _addRecentFile(panel)
    assert(panel:is_valid())
    local templateName = panel:GetTemplateName()
    if not is_valid_str(templateName) then
        return
    end

    local recentFiles = get_recent_open_file_list()
    table.arr_remove_v(recentFiles, templateName)
    table.insert(recentFiles, 1, templateName)

    --数量上限
    if #recentFiles > constant_uieditor.max_recent_open_files then
        table.remove(recentFiles)
    end

    g_native_conf['uieditor_recent_open_files'] = recentFiles
end

-- 根据一个模板的全局路径获取模板名称
local function _getTemplateNameByFullPath(fullFilePath)
    if not g_fileUtils:isFileExist(fullFilePath) then
        return
    end

    local pattern = g_logic_editor.get_project_ui_template_path()..'(.+)%.json$'
    return string.match(fullFilePath, pattern)
end

-- 获取最近打开的模板配置
function get_recent_open_file_list()
    local ret = {}

    -- update recent files validation
    for _, templateName in ipairs(g_native_conf['uieditor_recent_open_files']) do
        if g_uisystem.is_template_valid(templateName) then
            table.insert(ret, templateName)
        end
    end

    g_native_conf['uieditor_recent_open_files'] = ret

    return ret
end

-- 获取当前打开的 panels
function get_open_panel_list()
    return _openPanelList
end

-- 获取当前打开显示的 panel
function get_cur_open_panel()
    return _curPanel
end

function get_cur_open_panel_index()
    if _curPanel == nil then
        return nil
    else
        return table.find_v(_openPanelList, _curPanel)
    end
end

function open_file(templateName)
    local ret = {}
    if templateName then
        local panel = open_file_by_template_name(templateName)
        if panel then
            table.insert(ret, panel)
        end
    else
        local fileList = win_open_multiple('ui_template', g_logic_editor.get_project_ui_template_path(), '*.json', true)
        for _, fullPath in ipairs(fileList) do
            local panel = open_file_by_template_name(_getTemplateNameByFullPath(fullPath))
            if panel then
                table.insert(ret, panel)
            end
        end
    end
    return ret
end

-- 打开并显示 templateName 对应的 panel
function open_file_by_template_name(templateName)
    if not g_uisystem.is_template_valid(templateName) then
        printf('open_file_by_template_name [%s] not valid', str(templateName))
        return
    end

    g_editor_panel:ShowUIEditor()

    local _, p = table.find_if(_openPanelList, function(_, v)
        return v:GetTemplateName() == templateName
    end)

    if p then
        return show_cur_panel(p)
    else
        local panel = g_editor_panel.uieditorPanel:NewUIEditorPanel(templateName)
        table.insert(_openPanelList, panel)
        table.insert(_openPanelOrder, 1, panel)
        _addRecentFile(panel)
        _curPanel = panel

        g_logicEventHandler:Trigger('uieditor_multi_doc_status_changed')
        return panel
    end
end

-- 设置当前显示的文档
function show_cur_panel(panel)
    assert(panel:is_valid())

    if _curPanel == panel then
        return
    end

    assert(_curPanel == _openPanelOrder[1])
    assert(table.arr_remove_v(_openPanelOrder, panel))
    table.insert(_openPanelOrder, 1, panel)

    _curPanel = panel

    g_logicEventHandler:Trigger('uieditor_multi_doc_status_changed')

    return panel
end

-- 设置 index 对应的 panel 为当前显示的文档
function show_panel_by_index(index)
    assert(index >= 1 and index <= #_openPanelList)
    return show_cur_panel(_openPanelList[index])
end

function new_file()
    _curPanel = g_editor_panel.uieditorPanel:NewUIEditorPanel(nil)
    table.insert(_openPanelList, _curPanel)
    table.insert(_openPanelOrder, 1, _curPanel)

    g_logicEventHandler:Trigger('uieditor_multi_doc_status_changed')

    return _curPanel
end

--[[保存当前打开的文档]]
function save_file(panel, templateName)
    assert(panel:is_valid())

    if not panel:CanSave() then
        message('空内容无法保存')
        return
    end

    if templateName == nil then
        templateName = win_save_file('保存配置', g_logic_editor.get_project_ui_template_path())
    end

    if is_valid_str(templateName) then
        panel:SaveConfig(templateName)
    else
        return
    end
    _addRecentFile(panel)
    g_uisystem.reload_template(templateName)
    g_logicEventHandler:Trigger('uieditor_multi_doc_status_changed')

    message("保存成功")
end

--[[关闭当前文档]]
function close_file(closePanel)
    closePanel = closePanel or _curPanel
    assert(closePanel:is_valid())

    local function closeFunc()
        _addRecentFile(closePanel)

        closePanel:close_panel()

        assert(table.arr_remove_v(_openPanelList, closePanel))
        assert(table.arr_remove_v(_openPanelOrder, closePanel))

        if _curPanel == closePanel then
            _curPanel = _openPanelOrder[1]
        end

        g_logicEventHandler:Trigger('uieditor_multi_doc_status_changed')
    end

    if closePanel:NeedSave() then
        win_confirm_yes_no(nil, "当前的工作未保存，是否放弃保存？", closeFunc)
    else
        closeFunc()
    end
end

function switch_panel()
    if #_openPanelOrder > 1 then
        assert(_curPanel == _openPanelOrder[1])
        table.remove(_openPanelOrder, 1)
        table.insert(_openPanelOrder, 2, _curPanel)
        _curPanel = _openPanelOrder[1]
        g_logicEventHandler:Trigger('uieditor_multi_doc_status_changed')
    end
end

function move_panel(panel, offset)
    local i, v  = table.find_v(_openPanelList, panel)
    i = i + offset
    if i < 1 or i > #_openPanelList then
        return
    end
    table.arr_remove_v(_openPanelList, panel)
    table.insert(_openPanelList, i, panel)
    g_logicEventHandler:Trigger('uieditor_multi_doc_status_changed')
end


-- 保存指定的配置
function save_template_conf(panel)
    local conf, saveFullPath = panel.root_item:DumpItemCfg(), panel:GetSaveFilePath()
    assert(g_uisystem.is_template_valid(conf))

    local ws = {}
    local function _ws(str)
        table.insert(ws, str)
    end

    local function _wt(nCount)
        for i = 1, nCount do
            _ws('\t')
        end
    end

    local function _w(t, nTab)
        if is_table(t) then
            if is_array(t) then
                _ws('[\n')
                local bHasContent = false
                for _, v in ipairs(t) do
                    _wt(nTab)
                    _w(v, nTab + 1)
                    _ws(',\n')
                    bHasContent = true
                end
                if bHasContent then
                    table.remove(ws)
                end
                _ws('\n')
                _wt(nTab - 1)
                _ws(']')
            else
                _ws('{\n')
                local keys = table.keys(t)
                table.arr_bubble_sort(keys, function(v1, v2)
                    return tostring(v1) < tostring(v2)
                end)

                local bHasContent = false
                for _, k in ipairs(keys) do
                    _wt(nTab)
                    _w(tostring(k))
                    _ws(':')
                    _w(t[k], nTab + 1)
                    _ws(',\n')
                    bHasContent = true
                end
                if bHasContent then
                    table.remove(ws)
                end
                _ws('\n')
                _wt(nTab - 1)
                _ws('}')
            end
        elseif is_number(t) then
            _ws(tostring(t))
        else
            _ws(luaext_json_encode(t))
        end
    end

    local function _wc(conf, nTab)
        local controlConfig = g_uisystem.get_control_config(conf['type_name'])

        -- fix type alias
        conf['type_name'] = controlConfig:GetDefConf()['type_name']

        -- save attr order
        _ws('{\n')
        local bHasContent = false
        for _, attr in ipairs(controlConfig:GetSaveAttrOrder()) do
            local attrV = conf[attr]
            if attrV ~= nil then
                _wt(nTab)
                _w(tostring(attr))
                _ws(':')

                if attr == 'child_list' then
                    _ws('[\n')
                    local bHasContent = false
                    for _, cfg in ipairs(attrV) do
                        _wt(nTab + 1)
                        _wc(cfg, nTab + 2)
                        _ws(',\n')
                        bHasContent = true
                    end
                    if bHasContent then
                        table.remove(ws)
                    end
                    _ws('\n')
                    _wt(nTab)
                    _ws(']')
                else
                    _w(attrV, nTab + 1)
                end
                _ws(',\n')

                bHasContent = true
            end
        end
        if bHasContent then
            table.remove(ws)
        end
        _ws('\n')
        _wt(nTab - 1)
        _ws('}')
    end

    _wc(conf, 1)

    g_fileUtils:writeStringToFile(table.concat(ws), saveFullPath)

    g_uisystem.reload_template(panel:GetTemplateName())
end
