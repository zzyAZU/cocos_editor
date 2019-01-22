--[[
    ui 编辑器设置界面
]]
Panel = g_panel_mgr.new_panel_class('editor/dialog/setting_panel')

-- overwrite
function Panel:init_panel()
    self.btnClose.OnClick = function()
        if g_logic_editor.is_project_path_valid() then
            self:close_panel()
        else
            message('资源目录未初始化无法关闭设置面板')
        end
    end

    self.btnChooseProjectPath.OnClick = function()
        local path = win_open_directory('选择项目资源目录', '', true)
        if is_valid_str(path) then
            self.editProjectResPath:SetText(path)
        end
    end

    self.comboRecentSelResPath.OnBeforPopup = function()
        self.comboRecentSelResPath:SetItems({})
        local validResPaths = {}
        for _, resPath in ipairs(g_native_conf['editor_recent_open_proj_res_path']) do
            if g_fileUtils:isDirectoryExist(resPath) then
                table.insert(validResPaths, resPath)
                self.comboRecentSelResPath:AddMenuItem(resPath, function()
                    self.editProjectResPath:SetText(resPath)
                end)
            end
        end
        g_native_conf['editor_recent_open_proj_res_path'] = validResPaths
    end

    self.btnOK.OnClick = function()
        self:OnOK()
    end

    for lang, _ in pairs(g_constant_conf['constant_uisystem'].all_lang) do
        self.comboLang:AddMenuItem(lang, function()
            self.comboLang:SetString(lang)
        end)
    end

    -- 新建项目
    self.btnNewProject.OnClick = function()
        local projectTemplatePath = g_logic_editor.get_project_template_path()
        if projectTemplatePath then
            local p = win_save_file('项目目录', g_fileUtils:getWritablePath(), true)
            if is_valid_str(p) then
                p = p .. '/'
                if g_fileUtils:isDirectoryExist(p) then
                    message('请选择一个不存在的目录')
                else
                    if g_fileUtils:SyncDir(projectTemplatePath, p) then
                        self.editProjectResPath:SetString(p..'res')
                        win_explorer(p)
                    end
                end
            end
        else
            message('项目模板目录找不到')
        end
    end

    self:_updateData()
end

function Panel:OnOK()
    local function getsize(s)
        local w, h = s:match('%s*(%d+)%s+(%d+)%s*')
        w, h = tonumber(w), tonumber(h)
        if w and h then
            return w, h
        end
    end

    -- project path
    local projectResPath = self.editProjectResPath:GetString()

    if g_logic_editor.set_project_path(projectResPath) then
        -- save to recent open res path
        local editor_recent_open_proj_res_path = g_native_conf['editor_recent_open_proj_res_path']
        table.arr_remove_v(editor_recent_open_proj_res_path, projectResPath)
        table.insert(editor_recent_open_proj_res_path, projectResPath)
        g_native_conf['editor_recent_open_proj_res_path'] = editor_recent_open_proj_res_path
    else
        message('project path not valid')
        return
    end

    -- lang
    g_native_conf['cur_multilang_index'] = self.comboLang:GetString()

    --design resolution
    local w, h = getsize(self.editDesignResolution:GetString())
    if w == nil then
        message('design resolution size not valid')
        return
    end
    g_native_conf['editor_design_resolution_size'] = {
        width = w,
        height = h
    }

    utils_restart_game()
end

function Panel:_updateData()
    self.editProjectResPath:SetText(g_native_conf['editor_project_res_path'])

    self.comboLang:SetString(g_native_conf['cur_multilang_index'])

    local designSize = g_native_conf['editor_design_resolution_size']
    self.editDesignResolution:SetText(string.format('%d %d', designSize.width, designSize.height))
end
