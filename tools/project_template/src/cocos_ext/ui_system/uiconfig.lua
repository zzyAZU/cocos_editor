local constant_uisystem = g_constant_conf.constant_uisystem

UIConfig = CreateClass()

function UIConfig:__init__(typeName, baseCfg, registerFun)
    assert(baseCfg == nil or isinstance(baseCfg, UIConfig), baseCfg)

    self._type = typeName
    self._baseUIConfig = baseCfg

    self._defCfg = {['type_name'] = typeName}
    self._regAttrNameAlias = {}  -- 属性别名
    self._checkConfFunList = {}  -- Conf 结构转换

    self._createFun = nil
    self._createAttrList = nil
    self._attrOrder = {}

    self._saveAttrOrder = {'type_name'} --保存配置时按照属性的次序顺序保存

    if baseCfg then
        self._defCfg = table.copy(baseCfg._defCfg)
        self._defCfg['type_name'] = typeName
        -- def cfg replace
        for attr, _ in pairs(self._defCfg) do
            local def = constant_uisystem['default_control_value'][self._type]
            if def then
                local defValue = def[attr]
                if defValue ~= nil then
                    self._defCfg[attr] = defValue
                end
            end
        end

        self._regAttrNameAlias = table.copy(baseCfg._regAttrNameAlias)
        self._checkConfFunList = table.copy(baseCfg._checkConfFunList)

        self._createFun = baseCfg._createFun
        self._createAttrList = baseCfg._createAttrList
        self._attrOrder = table.copy(baseCfg._attrOrder)

        self._saveAttrOrder = table.copy(baseCfg._saveAttrOrder)
    end

    registerFun(self)

    -- move child_list to end
    assert(table.arr_remove_v(self._saveAttrOrder, 'child_list'))
    table.insert(self._saveAttrOrder, 'child_list')

    -- validate
    for _, group in ipairs(self._attrOrder) do
        assert(is_function(group['setAttr']))
    end
end

function UIConfig:RegAttr(name)
    local defValue = constant_uisystem['default_control_value'][self._type][name]
    assert_msg(defValue ~= nil, 'ui config attr [%s] [%s] not exists ', self._type, name)

    -- 属性职能注册一次
    assert(not table.find_v(self._saveAttrOrder, name))
    table.insert(self._saveAttrOrder, name)

    assert(self._defCfg[name] == nil)
    self._defCfg[name] = defValue
end

function UIConfig:RegAttrAlias(name, alias)
    assert_msg(self._defCfg[name] ~= nil, 'name [%s] not exist in [%s]', name, self._defCfg.type_name)
    assert_msg(self._regAttrNameAlias[alias] == nil, 'alias [%s] exists', alias)

    self._regAttrNameAlias[alias] = name
end

function UIConfig:RegCreate(...)
    local attrList = {...}
    local fun = table.remove(attrList)
    assert(is_function(fun))

    -- check
    for _, attr in ipairs(attrList) do
        assert(self._defCfg[attr] ~= nil)
    end

    self._createFun = fun
    self._createAttrList = attrList
end

function UIConfig:InsertSetAttrOrder(v, index)
    for _, attr in ipairs(v) do
        assert(self._defCfg[attr] ~= nil)
    end

    if index == nil then
        table.insert(self._attrOrder, v)
    else
        table.insert(self._attrOrder, index, v)
    end
end

--注册隶属于attrName组属性的设置回调函数， 同一个属性只能注册一次
function UIConfig:RegSetAttr(attrName, regFun)
    for _, v in ipairs(self._attrOrder) do
        if v[1] == attrName then
            v['setAttr'] = regFun
        end
    end
end

-- 为了转换旧配置到新配置
function UIConfig:RegCheckConf(fun)
    assert(is_function(fun))
    assert(not table.find_v(self._checkConfFunList, fun))
    table.insert(self._checkConfFunList, fun)
end

function UIConfig:GenConfig(conf)
    if conf['__checked__'] == nil then
        -- 兼容老配置的处理
        for _, fun in ipairs(self._checkConfFunList) do
            fun(conf)
        end

        -- 处理 alias
        local t = {}
        for k, v in pairs(conf) do
            t[self._regAttrNameAlias[k] or k] = v
        end

        -- 默认值填充
        local t1 = {}
        for k, v in pairs(self._defCfg) do
            if t[k] == nil then
                t1[k] = v
            else
                t1[k] = t[k]
            end
        end

        table.merge(table.clear(conf), t1)['__checked__'] = true
    end

    return conf
end

--[[返回对应的控件以及对应详细配置]]
function UIConfig:Create(conf, parent, root, aniConf)
    -- gen full conf
    self:GenConfig(conf)

    -- create
    local params = {}
    for _, attr in ipairs(self._createAttrList) do
        assert(conf[attr] ~= nil)
        table.insert(params, conf[attr])
    end

    -- print(string.format('###_createFun [%s] param:\n%s', conf.type_name, str(params)))
    local ctrl = self._createFun(parent, root, unpack(params))
    -- print('###_createFun end')

    -- gen ani data
    for aniname, aniData in pairs(conf['ani_data']) do
        if aniConf[aniname] == nil then
            aniConf[aniname] = {}
        end

        table.insert(aniConf[aniname], {ctrl, aniData})
    end

    if not root then
        root = ctrl
    end

    -- set attr
    for _, group in ipairs(self._attrOrder) do
        local args = {}
        for _, attr in ipairs(group) do
            -- assert_msg(conf[attr] ~= nil, 'attr [%s] not exists in conf [%s]', str(attr), str(conf))
            table.insert(args, conf[attr])
        end

        group['setAttr'](ctrl, parent, root, unpack(args))
    end

    for _, child_conf in ipairs(conf['child_list']) do
        g_uisystem.create_item(child_conf, ctrl, root, aniConf)
    end

    return ctrl, conf
end


------------------------------------------------------------------------------------------------------------------------------------
function UIConfig:GetDefConf()
    return self._defCfg
end

function UIConfig:GetBase()
    return self._baseUIConfig
end

function UIConfig:GenEditAttrs()
    if self._listCtrlConf then
        return self._listCtrlConf
    end

    local control_edit_info = g_constant_conf['constant_uieditor']['control_edit_info']

    local listConfig = {}
    local cur = self
    while cur do
        table.insert(listConfig, 1, cur)
        cur = cur._baseUIConfig
    end

    local listCtrlConf = {}
    local exestsCtrlConf = {}

    for _, config in ipairs(listConfig) do
        for _, v in ipairs(control_edit_info[config._type] or {}) do
            local attr = v['attr']
            if exestsCtrlConf[attr] == nil then
                table.insert(listCtrlConf, v)
                exestsCtrlConf[attr] = #listCtrlConf
            else
                listCtrlConf[exestsCtrlConf[attr]] = v
            end
        end
    end

    self._listCtrlConf = listCtrlConf

    return listCtrlConf
end

function UIConfig:GetEditInfo()
    if self._editInfo then
        return self._editInfo
    end

    local editInfos = table.from_table_values(self:GenEditAttrs(), 'attr')

    self._editInfo = editInfos

    return editInfos
end

function UIConfig:GenEditControls(propertyList, controlItem, panel)
    local editAttrs = self:GenEditAttrs()
    local editAttrsFilter = {}
    for _, conf in ipairs(editAttrs) do
        local bShow = true
        local curConf = conf
        while curConf['rely_on'] do
            local rely_on = curConf['rely_on']
            if not controlItem:GetCfg()[rely_on] then
                bShow = false
                break
            end

            _, curConf = table.find_if(editAttrs, function(k, v)
                return v.attr == rely_on
            end)
        end

        if bShow then
            table.insert(editAttrsFilter, conf)
        end
    end

    propertyList:SetInitCount(#editAttrsFilter)
    propertyList.OnCreateItem = function(i, item)
        local conf = editAttrsFilter[i]
        local attr = conf['attr']
        local controlConf = controlItem:GetCfg()
        local ctrl = editor_utils_create_edit_ctrls(conf['tp'], controlConf[attr], conf['parm'], controlConf, function(value)
            controlItem:GetCfg()[attr] = value
            panel:EditPush()
            local refresPolicy = conf['refresPolicy']
            if refresPolicy then
                refresPolicy(controlItem)
            end
        end):GetCtrl()

        item:SetContentSize(ctrl:GetContentSize())
        item:addChild(ctrl)
        ctrl:setAnchorPoint(ccp(0, 0))
        ctrl:SetPosition(0, 0)
    end
end

function UIConfig:GetSaveAttrOrder()
    return self._saveAttrOrder
end
