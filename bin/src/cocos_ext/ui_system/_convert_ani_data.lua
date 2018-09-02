local id2name = {
    [201] = 'ProgressTo',
    [202] = 'FrameAnimation',
}


local decorActions = {
    'Repeat',
    'EaseIn',
    'EaseOut',
    'EaseInOut',
    'EaseSineIn',
    'EaseSineOut',
    'EaseSineInOut',
    'EaseQuadraticActionIn',
    'EaseQuadraticActionOut',
    'EaseQuadraticActionInOut',
    'EaseCubicActionIn',
    'EaseCubicActionOut',
    'EaseCubicActionInOut',
    'EaseQuarticActionIn',
    'EaseQuarticActionOut',
    'EaseQuarticActionInOut',
    'EaseQuinticActionIn',
    'EaseQuinticActionOut',
    'EaseQuinticActionInOut',
    'EaseExponentialIn',
    'EaseExponentialOut',
    'EaseExponentialInOut',
    'EaseCircleActionIn',
    'EaseCircleActionOut',
    'EaseCircleActionInOut',
    'EaseElasticIn',
    'EaseElasticOut',
    'EaseElasticInOut',
    'EaseBackIn',
    'EaseBackOut',
    'EaseBackInOut',
    'EaseBounceIn',
    'EaseBounceOut',
    'EaseBounceInOut',
}
for i, v in ipairs(decorActions) do
    id2name[100 + i] = v
end

local normActions = {
    'DelayTime',
    'MoveTo',
    'MoveBy',
    'BezierTo',
    'BezierBy',
    'ScaleTo',
    'ScaleBy',
    'RotateTo',
    'RotateBy',
    'SkewTo',
    'SkewBy',
    'JumpTo',
    'JumpBy',
    'Blink',
    'FadeTo',
    'FadeIn',
    'FadeOut',
    'Show',
    'Hide',
    'ToggleVisibility',
    'RemoveSelf',
    'Place',
    'CallFunc',
    'Sequence',
}
for i, v in ipairs(normActions) do
    id2name[i] = v
end

local function _tryParseParm(tp, cfg, p, child_list)
    -- print('_tryParseParm', tp)
    if tp == 'DelayTime' then
        cfg['t'] = p
    elseif tp == 'FadeIn' then
        cfg['t'] = p
    elseif tp == 'FadeOut' then
        cfg['t'] = p
    elseif tp == 'Repeat' then
        cfg['n'] = p
    elseif tp == 'EaseIn' then
        cfg['p'] = p
    elseif tp == 'EaseOut' then
        cfg['p'] = p
    elseif tp == 'EaseInOut' then
        cfg['p'] = p
    elseif tp == 'Sequence' then
        local sqcl = cfg['child_list']
        if sqcl == nil then
            sqcl = {}
            cfg['child_list'] = sqcl
        end

        local removeIdx = #child_list - p + 1

        for i = 1, p do
            local subCfg = table.remove(child_list, removeIdx)
            if subCfg then
                table.insert(sqcl, subCfg)
            else
                printf('child_list [%d] not exists', i)
            end
        end
    else
        if p ~= nil then
            for k, v in pairs(p) do
                assert(cfg[k] == nil)
                cfg[k] = v
            end
        end
    end
end

local function _parseDecorInfo(decorInfo)
    local type_name = id2name[decorInfo[1]]
    local decorConf = {['type_name'] = type_name}
    _tryParseParm(type_name, decorConf, decorInfo[2])
    decorConf['p'] = decorInfo[2]
    return decorConf
end

local function _convertPosConf(vecData, node)
    if #vecData == 0 then
        return
    end

    local startIndex
    if vecData[1][1] == 0 then
        local data = vecData[1][2]
        node:SetPosition(data.x, data.y)

        startIndex = 2

        if #vecData == 1 then
            return
        end
    else
        startIndex = 1
    end

    local child_list = {}
    local ret = {
        ['type_name'] = 'Sequence',
        ['child_list'] = child_list,
    }

    local pre = 0
    for i = startIndex, #vecData do
        local time = vecData[i][1]
        local cfg = {}
        cfg['type_name'] = 'MoveTo'
        cfg['p'] = vecData[i][2]
        cfg['t'] = time - pre
        pre = time

        local decorInfo = vecData[i][3]
        if decorInfo then
            cfg['child_list'] = {
                _parseDecorInfo(decorInfo),
            }
        end

        table.insert(child_list, cfg)
    end

    return ret
end

local function _convertScaleConf(vecData, node)
    if #vecData == 0 then
        return
    end

    local startIndex
    if vecData[1][1] == 0 then
        local data = vecData[1][2]
        node:setScaleX(ccext_get_scale(data.x))
        node:setScaleY(ccext_get_scale(data.y))

        startIndex = 2
        if #vecData == 1 then
            return
        end
    else
        startIndex = 1
    end

    local child_list = {}
    local ret = {
        ['type_name'] = 'Sequence',
        ['child_list'] = child_list,
    }

    local pre = 0
    for i = startIndex, #vecData do
        local time = vecData[i][1]
        local cfg = {}
        cfg['type_name'] = 'ScaleTo'
        cfg['s'] = vecData[i][2]
        cfg['t'] = time - pre
        pre = time

        local decorInfo = vecData[i][3]
        if decorInfo then
            cfg['child_list'] = {
                _parseDecorInfo(decorInfo),
            }
        end

        table.insert(child_list, cfg)
    end

    return ret
end

local function _convertRotationConf(vecData, node)
    if #vecData == 0 then
        return
    end

    local startIndex
    if vecData[1][1] == 0 then
        local data = vecData[1][2]
        node:setRotation(data)

        startIndex = 2
        if #vecData == 1 then
            return
        end
    else
        startIndex = 1
    end

    local child_list = {}
    local ret = {
        ['type_name'] = 'Sequence',
        ['child_list'] = child_list,
    }

    local pre = 0
    for i = startIndex, #vecData do
        local time = vecData[i][1]
        local cfg = {}
        cfg['type_name'] = 'RotateTo'
        cfg['r'] = vecData[i][2]
        cfg['t'] = time - pre
        pre = time

        local decorInfo = vecData[i][3]
        if decorInfo then
            cfg['child_list'] = {
                _parseDecorInfo(decorInfo),
            }
        end

        table.insert(child_list, cfg)
    end

    return ret
end

local function _convertOpacityConf(vecData, node)
    if #vecData == 0 then
        return
    end

    local startIndex
    if vecData[1][1] == 0 then
        local data = vecData[1][2]
        node:setOpacity(data)

        startIndex = 2
        if #vecData == 1 then
            return
        end
    else
        startIndex = 1
    end

    local child_list = {}
    local ret = {
        ['type_name'] = 'Sequence',
        ['child_list'] = child_list,
    }

    local pre = 0
    for i = startIndex, #vecData do
        local time = vecData[i][1]
        local cfg = {}
        cfg['type_name'] = 'FadeTo'
        cfg['o'] = vecData[i][2]
        cfg['t'] = time - pre
        pre = time

        local decorInfo = vecData[i][3]
        if decorInfo then
            cfg['child_list'] = {
                _parseDecorInfo(decorInfo),
            }
        end

        table.insert(child_list, cfg)
    end

    return ret
end





local function _convertCustomizeConf(vecData)
    local listConf = {}
    for _, v in ipairs(vecData) do
        local tp = id2name[v[2][1]]
        local p = v[2][2]
        local decorInfo = v[3]
        local cfg = {}
        cfg['type_name'] = tp

        xpcall(function()
            _tryParseParm(tp, cfg, p, listConf)
        end, function(msg)
            print(msg)
            print(tp, v)
        end)
        

        if decorInfo then
            local decorConf = _parseDecorInfo(decorInfo)
            local child_list = cfg['child_list']
            if child_list then
                table.insert(child_list, decorConf)
            else
                cfg['child_list'] = {decorConf}
            end
        end

        table.insert(listConf, cfg)
    end

    if table.count(listConf) == 1 then
        return listConf[1]
    else
        return {
            ['type_name'] = 'Sequence',
            ['child_list'] = listConf,
        }
    end
end

local function _parseOldAniConf(conf, node)
    local listConf = {}

    for aniID, vecData in pairs(conf) do
        aniID = tonumber(aniID)

        local cfg
        if aniID == 1 then
            cfg = _convertPosConf(vecData, node)
        elseif aniID == 2 then
            cfg = _convertScaleConf(vecData, node)
        elseif aniID == 3 then
            cfg = _convertRotationConf(vecData, node)
        elseif aniID == 4 then
            cfg = _convertOpacityConf(vecData, node)
        else
            cfg = _convertCustomizeConf(vecData, node)
        end

        if cfg then
           table.insert(listConf, cfg)
        else
            -- print('parse old data failed', aniID, vecData)
        end
    end

    return listConf
end

-- 将旧版的动画数据转换成新版
function try_convert_ani_conf(conf, node, customizeInfo)
    -- print('try_convert_ani_conf', conf)
    if is_array(conf) then
        local listAniConf = {}
        for _, ani_path in ipairs(conf) do
            
            local aniConf, nodeInfo = g_uisystem.load_ani_template(ani_path, customizeInfo ~= nil)
            if aniConf then
                for _, v in ipairs(aniConf) do
                    table.insert(listAniConf, v)
                end
                if nodeInfo and customizeInfo then
                    
                    for action_name, action_conf in pairs(customizeInfo) do
                        if nodeInfo[action_name] then
                            for k, v in pairs(action_conf) do
                                nodeInfo[action_name][k] = v
                            end
                        end
                    end
                    
                end
            end
        end

        local len = #listAniConf

        -- print('listAniConf', len, listAniConf)


        if len == 1 then
            return listAniConf[1]
        elseif len > 1 then
            return {
                ['type_name'] = 'Spawn',
                ['child_list'] = table.from_arr_trans_fun(listAniConf, function(_, v)
                    return v
                end)
            }
        else
            printf('try_convert_ani_conf not valid:%s', str(conf))
            return
        end
    end

    local parseListConf = _parseOldAniConf(conf, node)

    local ret
    if table.count(parseListConf) == 1 then
        return parseListConf[1]
    else
        return {
            ['type_name'] = 'Spawn',
            ['child_list'] = parseListConf,
        }
    end

    return ret
end