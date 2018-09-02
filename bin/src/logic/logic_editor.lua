--[[
    编辑器逻辑
]]

--默认跟编辑器目录一致
local _projectResPath
local _projectUITemplatePath
local _projectAniTemplatePath



local function _init_native_config()
    -- 项目资源目录
    g_conf_mgr.register_native_conf('editor_project_res_path', 'not valid path')

    -- 设计分辨率
    g_conf_mgr.register_native_conf('editor_design_resolution_size', {
        width = 1280,
        height = 720,
    })

    -- 记录最近打开的模板
    g_conf_mgr.register_native_conf('uieditor_recent_open_files', {})

    -- 记录最近打开的动画配置
    g_conf_mgr.register_native_conf('anieditor_recent_open_files', {})

    -- 模板列表 todo
    -- g_conf_mgr.register_native_conf('uieditor_template_config', {})
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

    g_panel_mgr.show_in_new_scene_with_create_callback('dlg_editor_main_panel', function(editorMainPanel)
        rawset(_G, 'g_editor_panel', editorMainPanel)

        rawset(_G, 'g_multi_doc_manager', direct_import('uieditor.uieditor_multi_doc_manager'))

        rawset(_G, 'g_ani_multi_doc_manager', direct_import('anieditor.anieditor_multi_doc_manager'))

        if not set_project_path(g_native_conf['editor_project_res_path']) then
            message('项目资源目录无效，请重新设置')
            g_panel_mgr.show('editor.dlg_setting_panel')
        end
    end)

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

-----------------------项目路径相关 这里的目录名最后需要有目录分隔符
function set_project_path(respath)
    respath = respath:gsub('\\', '/')

    _projectResPath = respath:sub(-1) == '/' and respath or respath .. '/'
    _projectUITemplatePath = _projectResPath .. g_uisystem.get_template_path()
    _projectAniTemplatePath = _projectResPath .. g_uisystem.get_ani_template_path()

    if is_project_path_valid() then
        g_native_conf['editor_project_res_path'] = _projectResPath
        _processSearchPaths()
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

function get_project_ani_template_path()
    return _projectAniTemplatePath
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
