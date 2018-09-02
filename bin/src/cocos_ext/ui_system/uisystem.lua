--[[====================================
=
=           ui 管理 单例
=
========================================]]
local constant_uisystem = g_constant_conf['constant_uisystem']

_ctrlCfg = {}
_templateCache = {}
_templatePath = nil
_cachedCustomizeConf = {}

-- 除了 child_list 其他属性全部都浅拷贝
local function _copyTemplate(template)
    local ret = {}
    for k, v in pairs(template) do
        if k ~= 'child_list' then
            ret[k] = v
        end
    end

    local tcl = template['child_list']
    if tcl then
        local cl = {}
        ret['child_list'] = cl
        for _, v in ipairs(tcl) do
            table.insert(cl, _copyTemplate(v))
        end
    end

    return ret
end

-- 自定制模板逻辑(编辑器逻辑没做缓存机制)
local function _loadCustomizeTemplate(template, customizeInfo)
    local templateMap = customizeInfo['__template__']

    if templateMap == nil then
        templateMap = {}
        customizeInfo['__template__'] = templateMap
    end

    local ret = templateMap[template]
    if ret then
        return ret
    else
        ret = _copyTemplate(template)
        local nodeInfo = gen_root_node_conf(ret)

        -- 更改自定制的属性
        for name, attr_list in pairs(customizeInfo) do
            local nodeConf = nodeInfo[name]
            if nodeConf then
                for attr, value in pairs(attr_list) do
                    nodeConf[attr] = value
                end
            end
        end

        _cachedCustomizeConf[customizeInfo] = true
        templateMap[template] = ret

        return ret
    end
end

-- 设置 build_system 存放的目录
function set_template_path(templatePath)
    _templatePath = templatePath
end

function get_template_path()
    assert(_templatePath)
    return _templatePath
end

-- 在系统里面注册一个控件类型
function RegisterControl(name, base, regFun)
    assert(is_valid_str(name) and not _ctrlCfg[name])
    assert(base == nil or is_valid_str(base) and _ctrlCfg[base])
    assert(is_function(regFun))

    _ctrlCfg[name] = relative_import('uiconfig').UIConfig:New(name, base and _ctrlCfg[base], regFun)
end

function get_control_config(name)
    assert(name == nil or is_valid_str(name))
    return name == nil and _ctrlCfg or _ctrlCfg[name]
end

function create_item(conf, parent, root, aniConf)
    local uicfg = _ctrlCfg[conf['type_name']]
    if uicfg == nil then
        error_msg('type_name [%s] not reg', conf.type_name)
    end

    if aniConf == nil then
        -- 只有根节点才有动画数据
        aniConf = {}
    end

    local ctrl, conf = uicfg:Create(conf, parent, root, aniConf)
    ctrl:SetAnimationConf(aniConf)
    return ctrl, conf
end

-- 获取指定template模板的带有名称的root赋值类型的配置映射，并且格式化每一个节点配置内容
-- template 可以为配置或者模板名称
-- 调用后 template 的默认属性将会被设置
function gen_root_node_conf(template)
    if is_string(template) then
        template = load_template(template)
    end

    local nodeInfo = {}

    local function findNameConf(nodeConf)
        local type_name = nodeConf['type_name']
        _ctrlCfg[type_name]:GenConfig(nodeConf)

        local name = nodeConf['name']
        if name ~= '' and nodeConf['assign_root'] then
            nodeInfo[name] = nodeConf
        end

        for _, subConf in ipairs(nodeConf['child_list']) do
            findNameConf(subConf)
        end
    end
    findNameConf(template)

    return nodeInfo
end

function load_template(name, customizeInfo)
    local cacheTemplate = _templateCache[name]
    if cacheTemplate and not g_native_conf['debug_control'].bIsReloadRes then
        if customizeInfo then
            return _loadCustomizeTemplate(cacheTemplate, customizeInfo)
        else
            return cacheTemplate
        end
    end

    print('======load_template', name)

    local ret
    local path = _templatePath .. name .. string.format('__%s__.json', g_native_conf['cur_multilang_index'])
    if g_fileUtils:isFileExist(path) then
        ret = table.read_from_file(path)
    else
        path = _templatePath .. name .. '.json'
        if g_fileUtils:isFileExist(path) then
            ret = table.read_from_file(path)
        end
    end

    if not ret or not is_template_valid(ret) then
        printf('load_template [%s] failed:%s', path, str(ret))
        return constant_uisystem.default_empty_template_conf
    end

    _templateCache[name] = ret

    if customizeInfo then
        return _loadCustomizeTemplate(ret, customizeInfo)
    else
        return ret
    end
end

function reload_template(name)
    if name == nil then
        _templateCache = {}
    else
        _templateCache[name] = nil
    end

    for customizeInfo, _ in pairs(_cachedCustomizeConf) do
        customizeInfo['__template__'] = nil
    end
    _cachedCustomizeConf = {}
end

function load_template_create(name, parent, root, customizeInfo)
    return create_item(load_template(name, customizeInfo), parent, root)
end

function is_template_valid(conf)
    if is_string(conf) then
        return load_template(conf) ~= nil
    end

    if not is_table(conf) then
        return false
    end

    local type_name = conf['type_name']
    if type_name == nil or _ctrlCfg[type_name] == nil then
        return false
    end

    local child_list = conf['child_list']
    if is_table(child_list) then
        for _, subConf in ipairs(child_list) do
            if not is_template_valid(subConf) then
                return false
            end
        end
    end

    return true
end

-- 播放一个 template 里面的一个动画
function play_template_animation_with_parent(conf, aniName, parent)
    local ctrl = create_item(conf, parent)
    ctrl:PlayAnimation(aniName)
    return ctrl
end

function play_template_animation(conf, aniName, parent)
    if is_string(conf) then
        conf = load_template(conf)
    end
    if parent == nil then
        parent = g_director:getRunningScene()
        assert(parent)
    end
    return play_template_animation_with_parent(conf, aniName, parent)
end

function is_text_left_to_right_order()
    return constant_uisystem.left2right_lang[g_native_conf['cur_multilang_index']] ~= nil
end


-- local _cachedTemplate = setmetatable({}, {
--     __mode = 'k',
-- })
local _cachedTemplate = {}

function load_cached_template(templateName, customizeInfo)
    local conf = is_table(templateName) and templateName or load_template(templateName, customizeInfo)
    local cachedList = _cachedTemplate[conf]

    if cachedList == nil then
        cachedList = {}
        _cachedTemplate[conf] = cachedList
    end

    for _, v in ipairs(cachedList) do
        if v:getParent() == nil then
            return v
        end
    end

    local ret = create_item(conf)
    ret:retain()
    table.insert(cachedList, ret)

    return ret
end

g_logicEventHandler:AddCallback('logic_event_restart_app', function()
    for _, cachedList in pairs(_cachedTemplate) do
        for _, v in ipairs(cachedList) do
            print('remove', v)
            v:removeFromParent(true)
        end
    end
    _cachedTemplate = {}
end)





-- action
local _allActionTypeInfo = {}  -- 所有的动画
local _actionTypeInfo = {}  -- 通用动画
local _actionSpecTypeInfo = {}  -- 特定节点支持的动画
local _actionDecorateTypeInfo = {}  -- 装饰器动画
local _aniTemplatePath = nil

local _aniConfCache = {}

function set_ani_template_path(path)
    _aniTemplatePath = path
end

function get_ani_template_path()
    return _aniTemplatePath
end

local function _isAniConfValid(conf)
    if not is_table(conf) then
        return false
    end

    local type_name = conf['type_name']
    if type_name == nil or _allActionTypeInfo[type_name] == nil then
        return false
    end

    local child_list = conf['child_list']
    if is_table(child_list) then
        for _, subConf in ipairs(child_list) do
            if not _isAniConfValid(subConf) then
                return false
            end
        end
    end

    return true
end

function is_ani_template_valid(conf)
    if is_string(conf) then
        return load_ani_template(conf) ~= nil
    end

    if not is_table(conf) then
        return false
    end

    for _, v in ipairs(conf) do
        if not _isAniConfValid(v) then
            return false
        end
    end

    return true
end

local function _copyAnimationTemplate(animtion_template)
    local ret = {}
    for k, v in pairs(animtion_template) do
        if k ~= 'child_list' then
            ret[k] = v
        end
    end

    local tcl = animtion_template['child_list']
    if tcl then
        local cl = {}
        ret['child_list'] = cl
        for _, v in ipairs(tcl) do
            table.insert(cl, _copyAnimationTemplate(v))
        end
    end

    return ret
end

function gen_root_node_ani_conf(template)
    if is_string(template) then
        template = load_template(template)
    end

    local nodeInfo = {}


    local function findNameConf(nodeConf)
        local name = nodeConf['name']
        if name and name ~= '' and name ~= 'nil' then
            nodeInfo[name] = nodeConf
        end

        for _, subConf in ipairs(nodeConf['child_list'] or {}) do
            findNameConf(subConf)
        end
    end

    for _, conf in ipairs(template) do
        findNameConf(conf)
    end
    return nodeInfo
end

function load_ani_template(name, gen_root)
    local ret = _aniConfCache[name]
    local nodeInfo = nil
    if ret then
        if gen_root then
            ret = _copyAnimationTemplate(ret)
            nodeInfo = gen_root_node_ani_conf(ret)
        end
        
        return ret, nodeInfo
    end

    path = _aniTemplatePath .. name .. '.json'
    if g_fileUtils:isFileExist(path) then
        ret = table.read_from_file(path)
    end

    if not ret or not is_ani_template_valid(ret) then
        printf('load_ani_template [%s] failed:%s', name, str(ret))
        return constant_uisystem.default_empty_ani_template_conf
    end
    _aniConfCache[name] = ret

    if gen_root then
        ret = _copyAnimationTemplate(ret)
        nodeInfo = gen_root_node_ani_conf(ret)
    end
    return ret, nodeInfo
end

function reload_ani_template(name)
    _aniConfCache[name] = nil
end

function get_decorate_action_info()
    return _actionDecorateTypeInfo
end

function get_all_action_info()
    return _allActionTypeInfo
end

local try_convert_ani_conf = relative_import('_convert_ani_data').try_convert_ani_conf
function gen_action_and_run(node, aniConf, customizeInfo)
    aniConf = try_convert_ani_conf(aniConf, node, customizeInfo)

    -- print('gen_action_and_run', aniConf)

    if not aniConf then
        return
    end

    local tp = aniConf['type_name']
    local action = _allActionTypeInfo[tp](aniConf, node)

    if action then
        node:runAction(action)
    end
end

function reg_customize_action_type(actionName, parseFun)
    assert(is_valid_str(actionName))
    assert(is_function(parseFun))
    assert(_allActionTypeInfo[actionName] == nil)
    _actionTypeInfo[actionName] = parseFun
    _allActionTypeInfo[actionName] = parseFun
end


function reg_action_type(actionName, parseFun)
    assert(is_valid_str(actionName))
    assert(is_function(parseFun) or parseFun == nil)
    assert(_allActionTypeInfo[actionName] == nil)

    -- 便捷操作
    if parseFun == nil then
        local class = cc[actionName]
        assert(tolua_is_class_t(class))
        function parseFun()
            return class:create()
        end
    end

    local function _parse(conf, node)
        local ret = parseFun(conf, node)
        local child_list = conf['child_list']
        if child_list then
            for i, childConf in ipairs(child_list) do
                local tp = childConf['type_name']
                local decoratParse = _actionDecorateTypeInfo[tp]
                if decoratParse then
                    ret = decoratParse(childConf, node, ret, child_list, i)
                end
            end
        end

        return ret
    end

    _actionTypeInfo[actionName] = _parse
    _allActionTypeInfo[actionName] = _parse
end

-- 注册特定类专有的动画类型
function reg_spec_action_type(specTypeName, actionName, parseFun)
    assert(is_valid_str(actionName))
    assert(is_function(parseFun))
    assert(_allActionTypeInfo[actionName] == nil)

    if _actionSpecTypeInfo[specTypeName] == nil then
        _actionSpecTypeInfo[specTypeName] = {}
    end

    local function _parse(conf, node)
        local ret = parseFun(conf, node)
        local child_list = conf['child_list']
        if child_list then
            for i, childConf in ipairs(child_list) do
                local tp = childConf['type_name']
                local decoratParse = _actionDecorateTypeInfo[tp]
                if decoratParse then
                    ret = decoratParse(childConf, node, ret, child_list, i)
                end
            end
        end

        return ret
    end

    _actionSpecTypeInfo[specTypeName][actionName] = parseFun
    _allActionTypeInfo[actionName] = parseFun
end


local _vecDecorateType = {}
function reg_decorate_action_type(actionName, parseFun)
    assert(is_valid_str(actionName))
    assert(is_function(parseFun) or parseFun == nil)
    assert(_allActionTypeInfo[actionName] == nil)

    -- 便捷操作
    if parseFun == nil then
        local class = cc[actionName]
        assert(tolua_is_class_t(class))
        function parseFun(conf, node, action)
            return class:create(action)
        end
    end

    _actionDecorateTypeInfo[actionName] = parseFun
    _allActionTypeInfo[actionName] = parseFun

    table.insert(_vecDecorateType, actionName)
end

