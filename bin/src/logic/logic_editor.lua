--[[
    编辑器逻辑
]]

--默认跟编辑器目录一致
local _projectResPath
local _projectUITemplatePath
local _projectAniTemplatePath
local _projectScriptPath
local _projectScriptDialogPath
local _gameWorkDir

local _scriptUseTemplateInfo = {}
local _templateUsedByScriptsInfo = {}
local _templateUseAniInfo = {}
local _aniUsedByTemplateInfo = {}


local function _init_native_config()
    -- 项目资源目录
    g_conf_mgr.register_native_conf('editor_project_res_path', 'not valid path')

    -- 设计分辨率
    g_conf_mgr.register_native_conf('editor_design_resolution_size', {
        width = 1280,
        height = 720,
    })

    g_conf_mgr.register_native_conf('editor_recent_open_proj_res_path', {})

    -- 记录最近打开的模板
    g_conf_mgr.register_native_conf('uieditor_recent_open_files', {})

    -- 记录最近打开的动画配置
    g_conf_mgr.register_native_conf('anieditor_recent_open_files', {})

    -- 模板列表
    g_conf_mgr.register_native_conf('uieditor_template_ctrls_dir', 'uieditor_template_ctrls')

    -- 帮助信息
    g_conf_mgr.register_script_conf('editor_help_info', {
        op_doc_url = 'http://note.youdao.com/noteshare?id=aff09f42a4f53177171e638c81853204&sub=DC80525D4CE246139538BE3C348C1D29',  -- 编辑器操作文档
        evn_doc_url = 'http://note.youdao.com/noteshare?id=e89ed0967396ff847c4d745d1846f374&sub=ABE0DCE82F3F4AD580E94B5209A19816',  -- 安装环境文档
    })
end

local function _initLogicEvents()
    g_logicEventHandler:RegisterEvent('uieditor_multi_doc_status_changed')
    g_logicEventHandler:RegisterEvent('anieditor_multi_doc_status_changed')
end

-- 程序初始化的时候会调用这个
function init()
    -- 编辑器配置初始化
    print('init editor~~~')
    _init_native_config()
    _initLogicEvents()

    -- 预览模式
    if win_startup_conf['preview_template'] then
        -- preview_lang
        local preview_lang = win_startup_conf['preview_lang']
        g_native_conf['cur_multilang_index'] = preview_lang

        -- preview_design_size
        local w, h = string.match(win_startup_conf['preview_design_size'], '^(%d+)X(%d+)$')
        local resolutionSize = CCSize(tonumber(w), tonumber(h))
        g_native_conf['editor_design_resolution_size'] = resolutionSize
        update_design_resolution(nil, nil, resolutionSize.width, resolutionSize.height)

        -- preview_res_path search path
        g_fileUtils:addSearchPath(win_startup_conf['preview_res_path'], true)
        local langSearchPath = string.format(win_startup_conf['preview_res_path'] .. 'res_%s/', preview_lang)
        if g_fileUtils:isDirectoryExist(langSearchPath) then
            g_fileUtils:addSearchPath(langSearchPath, true)
        end

        -- run preview scene
        local scene = cc.Scene:create()
        if g_director:getRunningScene() then
            g_director:pushScene(scene)
        else
            g_director:runWithScene(scene)
        end
        

        local preview_template = win_startup_conf['preview_template']
        if g_uisystem.is_template_valid(preview_template) then
            -- preview_ani_name
            local preview_ani_name = win_startup_conf['preview_ani_name']
            if preview_ani_name ~= 'nil' then
                print('play_template_animation_with_parent')
                g_uisystem.play_template_animation(preview_template, preview_ani_name, scene)
            else
                print('load_template_create')
                g_uisystem.load_template_create(preview_template, scene)
            end
        else
            message('无效的模板:{1}', preview_template)
        end
    else
        -- 适配编辑器设置的设计分辨率
        local resolutionSize = g_native_conf['editor_design_resolution_size']
        update_design_resolution(resolutionSize.width, resolutionSize.height, resolutionSize.width, resolutionSize.height)

        g_panel_mgr.show_in_new_scene_with_create_callback('dlg_editor_main_panel', function(editorMainPanel)
            rawset(_G, 'g_editor_panel', editorMainPanel)

            rawset(_G, 'g_multi_doc_manager', direct_import('uieditor.uieditor_multi_doc_manager'))

            rawset(_G, 'g_ani_multi_doc_manager', direct_import('anieditor.anieditor_multi_doc_manager'))

            if not set_project_path(g_native_conf['editor_project_res_path']) then
                message('项目资源目录无效，请重新设置')
                g_panel_mgr.show('editor.dlg_setting_panel')
            end
        end)
    end

    print('init editor end~~~')
end

-- 全局环境下的逻辑初始化
local function _processSearchPaths()
    -- 重启情况的处理
    local newSearchPaths = {}
    for _, v in ipairs(g_fileUtils:getSearchPaths()) do
        if not string.find(v, 'res/') and not string.find(v, 'patch_bin_folder/') and not string.find(v, _projectResPath) then
            table.insert(newSearchPaths, v)
        end
    end

    g_fileUtils:setSearchPaths(newSearchPaths)
    g_fileUtils:addSearchPath('res/', true)
    g_fileUtils:addSearchPath(_projectResPath, true)
    local curLang = g_native_conf.cur_multilang_index
    if curLang ~= g_constant_conf['constant_uisystem'].default_lang then
        g_fileUtils:addSearchPath(string.format('%sres_%s/', _projectResPath, curLang), true)
    end

    -- print(g_fileUtils:getSearchPaths())
end

local function _checkTemplateDir()
    local templateInfo = {}
    local notValidTemplateInfo = {}
    local dirs = {}
    local function _parse(d)
        for _, info in ipairs(win_list_files(d)) do
            table.insert(dirs, info.name)
            if info.is_dir then
                _parse(info.path)
            else
                local relativeFilePath = table.concat(dirs, '/')
                local templateName = string.match(relativeFilePath, '(.+)%.json')
                if templateName and g_uisystem.is_template_valid(templateName) then
                    templateInfo[templateName] = info.path
                else
                    notValidTemplateInfo[templateName] = info.path
                end
            end
            table.remove(dirs)
        end
    end

    _parse(_projectUITemplatePath)

    return templateInfo, notValidTemplateInfo
end

local function _checkScriptDialogDir()
    if _projectScriptDialogPath == nil then
        return
    end

    local _scriptInfo = {_list_ = {}}
    local dirs = {}

    local function _setInfo(info)
        local curInfo = _scriptInfo
        for _, v in ipairs(dirs) do
            local info = curInfo[v]
            if info == nil then
                info = {_list_ = {}}
                curInfo[v] = info
            end
            curInfo = info
        end

        table.insert(curInfo._list_, info)
    end

    local function _parse(d)
        for _, info in ipairs(win_list_files(d)) do
            if info.is_dir then
                table.insert(dirs, info.name)
                _parse(info.path)
                table.remove(dirs)
            else
                local relativeFilePath = string.format('%s/%s', table.concat(dirs, '/'), info.name)
                local content = g_fileUtils:getStringFromFile(info.path)
                if content then
                    local pattern = [[Panel\s*=\s*g_panel_mgr.new_panel_class\(('|")([a-zA-Z_/]+)('|")]]
                    local match = luaext_string_search(content, pattern)
                    if match then
                        local templateName = match[2]
                        if g_fileUtils:isFileExist(get_ui_template_file_path(templateName)) then
                            _setInfo({
                                template = templateName,
                                relative_path = relativeFilePath,
                                script_path = info.path,
                                file_name = info.name,
                            })
                        else
                            printf('error! panel:[%s] not valid used by [%s]', templateName, relativeFilePath)
                        end
                    end
                end
            end
        end
    end

    _parse(_projectScriptDialogPath)

    return _scriptInfo
end
    
function get_dialog_info()
    -- local templateInfo, notValidTemplateInfo = _checkTemplateDir()

    -- if not table.is_empty(notValidTemplateInfo) then
    --     print('notValidTemplateInfo', notValidTemplateInfo)
    -- end
    return _checkScriptDialogDir()
end

function get_template_ctrls_info()
    local dir =  _projectUITemplatePath .. g_native_conf['uieditor_template_ctrls_dir']
    g_fileUtils:CreateDirectoryIfNotExist(dir)

    local templateCtrlsInfo = {_list_ = {}}
    local listDirs = {}

    local function _setInfo(info)
        local curConf = templateCtrlsInfo
        for _, v in ipairs(listDirs) do
            local cfg = curConf[v]
            if not cfg then
                cfg = {_list_ = {}}
                curConf[v] = cfg
            end
            curConf = cfg
        end

        table.insert(curConf._list_, info)
    end

    local function _search(d)
        for _, info in ipairs(win_list_files(d)) do
            if info.is_dir then
                table.insert(listDirs, info.name)
                _search(info.path)
                table.remove(listDirs)
            else
                local fileName = string.match(info.name, '^([a-zA-Z0-9_]+)%.json$')
                if fileName then
                    table.insert(listDirs, fileName)
                    local templateName = g_native_conf['uieditor_template_ctrls_dir'] .. '/' .. table.concat(listDirs, '/')
                    table.remove(listDirs)
                    _setInfo({
                        template = templateName,
                        file_name = fileName,
                    })
                end
            end
        end
    end

    _search(dir)

    return templateCtrlsInfo
end

function get_ani_template_info()
    local templateAniInfo = {_list_ = {}}
    local listDirs = {}
    local function _setInfo(info)
        local curConf = templateAniInfo
        for _, v in ipairs(listDirs) do
            local cfg = curConf[v]
            if not cfg then
                cfg = {_list_ = {}}
                curConf[v] = cfg
            end
            curConf = cfg
        end

        table.insert(curConf._list_, info)
    end

    local function _search(d)
        for _, info in ipairs(win_list_files(d)) do
            if info.is_dir then
                table.insert(listDirs, info.name)
                _search(info.path)
                table.remove(listDirs)
            else
                local fileName = string.match(info.name, '^([a-zA-Z0-9_]+)%.json$')
                if fileName then
                    table.insert(listDirs, fileName)
                    local templateName = table.concat(listDirs, '/')
                    table.remove(listDirs)
                    if g_uisystem.is_template_has_ani_info(templateName) then
                        _setInfo({
                            template = templateName,
                            file_name = fileName,
                        })
                    end
                end
            end
        end
    end

    _search(_projectUITemplatePath)

    return templateAniInfo
end

-----------------------项目路径相关 这里的目录名最后需要有目录分隔符
function set_project_path(respath)
    respath = respath:gsub('\\', '/')

    _projectResPath = respath:sub(-1) == '/' and respath or respath .. '/'
    _projectUITemplatePath = _projectResPath .. g_uisystem.get_template_path()
    _projectAniTemplatePath = _projectResPath .. g_uisystem.get_ani_template_path()

    if is_project_path_valid() then
        g_native_conf['editor_project_res_path'] = _projectResPath
        _processSearchPaths()

        -- scripts path
        _gameWorkDir = string.match(_projectResPath, '(.+/)[^/]+/')
        _projectScriptPath = _gameWorkDir .. 'src/'
        if g_fileUtils:isDirectoryExist(_projectScriptPath) then
            _projectScriptDialogPath = _projectScriptPath .. 'logic/dialog/'
            if not g_fileUtils:isDirectoryExist(_projectScriptDialogPath) then
                printf('_projectScriptDialogPath [%s] not exists', _projectScriptDialogPath)
                _projectScriptPath = nil
                _projectScriptDialogPath = nil
            end
        else
            printf('_projectScriptPath [%s] not exists', _projectScriptPath)
            _projectScriptPath = nil
            _projectScriptDialogPath = nil
        end

        return true
    else
        return false
    end
end

function get_project_res_path()
    return _projectResPath
end

function get_project_ui_template_path()
    return _projectUITemplatePath
end

function get_ui_template_file_path(templateName)
    return string.format('%s%s.json', _projectUITemplatePath, templateName)
end

function get_project_ani_template_path()
    return _projectAniTemplatePath
end

function get_ani_template_file_path(templateName)
    return string.format('%s%s.json', _projectAniTemplatePath, templateName)
end

-- 获取当前项目的 work dir
function get_game_work_dir()
    return _gameWorkDir
end

function get_project_script_path()
    return _projectScriptPath
end

function get_project_script_dialog_path()
    return _projectScriptDialogPath
end

function is_project_path_valid()
    if _projectResPath == nil or _projectUITemplatePath == nil or _projectAniTemplatePath == nil then
        return false
    end

    local bProjectResPathExist = g_fileUtils:isDirectoryExist(_projectResPath)
    local bprojectTemplatePathExist = g_fileUtils:isDirectoryExist(_projectUITemplatePath)
    local bprojectAniTemplatePathExist = g_fileUtils:isDirectoryExist(_projectAniTemplatePath)

    print(_projectResPath, bProjectResPathExist)
    print(_projectUITemplatePath, bprojectTemplatePathExist)
    print(_projectAniTemplatePath, bprojectAniTemplatePathExist)

    return bProjectResPathExist and bprojectTemplatePathExist and bprojectAniTemplatePathExist
end

function set_editor_size(editorW, editorH)
end

function get_editor_size()
    local winsize = g_director:getWinSize()
    return winsize.width, winsize.height
end

function get_editor_root_path()
    local writablePath = string.gsub(g_fileUtils:getWritablePath(), '\\', '/')
    local editorRootPath = string.match(writablePath, string.format('^(.+/)bin/user_%s/$', win_startup_conf['id']))
    if editorRootPath and g_fileUtils:isDirectoryExist(editorRootPath) then
        return editorRootPath
    end
end

function get_tools_path()
    local editorRootPath = get_editor_root_path()
    if editorRootPath then
        local ret = editorRootPath .. 'tools/'
        if g_fileUtils:isDirectoryExist(ret) then
            return ret
        end
    end
end

function get_project_template_path()
    local toolsPath = get_tools_path()
    if toolsPath then
        local ret = toolsPath..'project_template/'
        if g_fileUtils:isDirectoryExist(ret) then
            return ret
        end
    end
end
