local constant_uisystem = g_constant_conf['constant_uisystem']

local function _genActions(childList, node)
    if childList == nil then
        return
    end

    local decorConfs = {}
    local seqActions = {}

    for _, childConf in ipairs(childList) do
        local tp = childConf['type_name']
        local decoratParse = g_uisystem.get_decorate_action_info()[tp]
        if decoratParse then
            table.insert(decorConfs, {decoratParse, childConf})
        else
            local parser = g_uisystem.get_all_action_info()[tp]
            if parser then
                local action = parser(childConf, node)
                if action then
                    table.insert(seqActions, action)
                else
                    print('_genActions failed', str(childConf))
                end
            else
                printf('_genActions no parser:%s', tp)
            end
        end
    end

    return decorConfs, seqActions
end

g_uisystem.reg_customize_action_type('Sequence', function(conf, node)
    local decorConfs, seqActions = _genActions(conf['child_list'], node)
    if decorConfs == nil or #seqActions == 0 then
        return
    end

    local ret = cc.Sequence:create(seqActions)

    for _, info in ipairs(decorConfs) do
        ret = info[1](info[2], node, ret)
    end

    return ret
end)

g_uisystem.reg_customize_action_type('Spawn', function(conf, node)
    local decorConfs, seqActions = _genActions(conf['child_list'], node)
    if decorConfs == nil or #seqActions == 0 then
        return
    end

    local ret = cc.Spawn:create(seqActions)

    for _, info in ipairs(decorConfs) do
        ret = info[1](info[2], node, ret)
    end

    return ret
end)




g_uisystem.reg_action_type('DelayTime', function(conf)
    return cc.DelayTime:create(conf.t)
end)

g_uisystem.reg_action_type('MoveTo', function(conf, node)
    return cc.MoveTo:create(conf.t, node:CalcPos(conf.p.x, conf.p.y))
end)

g_uisystem.reg_action_type('MoveBy', function(conf, node)
    return cc.MoveBy:create(conf.t, node:CalcPos(conf.p.x, conf.p.y))
end)

g_uisystem.reg_action_type('BezierTo', function(conf, node)
    local p, p1, p2 = conf.p, conf.p1, conf.p2
    p1 = node:CalcPos(p1.x, p1.y)
    p2 = node:CalcPos(p2.x, p2.y)
    p = node:CalcPos(p.x, p.y)
    return cc.BezierTo:create(conf.t, {p1, p2, p})
end)

g_uisystem.reg_action_type('BezierBy', function(conf, node)
    local p, p1, p2 = conf.p, conf.p1, conf.p2
    p1 = node:CalcPos(p1.x, p1.y)
    p2 = node:CalcPos(p2.x, p2.y)
    p = node:CalcPos(p.x, p.y)
    return cc.BezierBy:create(conf.t, {p1, p2, p})
end)

g_uisystem.reg_action_type('CardinalSplineBy', function(conf, node)
    local t = conf.t
    local pos_list = {}
    for _, pos_item in ipairs(conf.p_list or {}) do
        table.insert(pos_list, node:CalcPos(pos_item.x, pos_item.y))
    end
    local tension = conf.tension
    return cc.CardinalSplineBy:create(t, pos_list, tension)
end)

g_uisystem.reg_action_type('ScaleTo', function(conf, node)
    return cc.ScaleTo:create(conf.t, ccext_get_scale(conf.s.x), ccext_get_scale(conf.s.y))
end)

g_uisystem.reg_action_type('ScaleBy', function(conf, node)
    return cc.ScaleBy:create(conf.t, ccext_get_scale(conf.s.x), ccext_get_scale(conf.s.y))
end)

g_uisystem.reg_action_type('RotateTo', function(conf)
    return cc.RotateTo:create(conf.t, conf.r)
end)

g_uisystem.reg_action_type('RotateBy', function(conf)
    return cc.RotateBy:create(conf.t, conf.r)
end)

g_uisystem.reg_action_type('SkewTo', function(conf)
    return cc.SkewTo:create(conf.t, conf.s.x, conf.s.y)
end)

g_uisystem.reg_action_type('SkewBy', function(conf)
    return cc.SkewBy:create(conf.t, conf.s.x, conf.s.y)
end)

g_uisystem.reg_action_type('JumpTo', function(conf)
    return cc.JumpTo:create(conf.t, conf.p, conf.h, conf.j)
end)

g_uisystem.reg_action_type('JumpBy', function(conf)
    return cc.JumpBy:create(conf.t, conf.p, conf.h, conf.j)
end)

g_uisystem.reg_action_type('Blink', function(conf)
    return cc.Blink:create(conf.t, conf.n)
end)

g_uisystem.reg_action_type('TintTo', function(conf, node)
    local color = ccc3FromHex(conf.color)
    return cc.TintTo:create(conf.t, color.r, color.g, color.b)
end)

-- 涉及到透明度、颜色的动画默认会将节点设置 cascade enable true
g_uisystem.reg_action_type('FadeTo', function(conf, node)
    node:SetEnableCascadeOpacityRecursion(true)
    return cc.FadeTo:create(conf.t, conf.o)
end)

g_uisystem.reg_action_type('FadeIn', function(conf, node)
    node:SetEnableCascadeOpacityRecursion(true)
    return cc.FadeIn:create(conf.t)
end)

g_uisystem.reg_action_type('FadeOut', function(conf, node)
    node:SetEnableCascadeOpacityRecursion(true)
    return cc.FadeOut:create(conf.t)
end)

g_uisystem.reg_action_type('Show')

g_uisystem.reg_action_type('Hide')

g_uisystem.reg_action_type('ToggleVisibility')

g_uisystem.reg_action_type('RemoveSelf')

g_uisystem.reg_action_type('Place', function(conf, node)
    return cc.Place:create(node:CalcPos(conf.p.x, conf.p.y))
end)

g_uisystem.reg_action_type('CallFunc', function(conf, node)
    return cc.CallFunc:create(function()
        if node.eventHandler:IsEventReg(conf.n) then
            node.eventHandler:Trigger(conf.n, conf.p)
        else
            printf('animation CallFunc name[%s] not reg:%s', conf.n, debug.traceback())
        end
    end)
end)

g_uisystem.reg_spec_action_type('CCProgressTimer', 'ProgressTo', function(conf, node)
    return cc.ProgressTo:create(conf.t, conf.p)
end)

g_uisystem.reg_spec_action_type('CCAnimateSprite', 'FrameAnimation', function(conf, node)
    return cc.CallFunc:create(function()
        node:SetAniSptDisplayFrameByPath(conf.p, nil, true)
        node:ReStart(conf.c, true)
    end)
end)

g_uisystem.reg_customize_action_type('PlayAudio', function(conf, node)
    return cc.CallFunc:create(function()
        g_audio_mgr.playSound(conf.p)
    end)
end)

g_uisystem.reg_customize_action_type('PlayMusic', function(conf, node)
    return cc.CallFunc:create(function()
        g_audio_mgr.playMusic(conf.p, false)
    end)
end)

g_uisystem.reg_customize_action_type('TemplateAction', function(conf, node)
    local template_path = conf.p
    return cc.CallFunc:create(function()
        g_uisystem.play_template_animation(template_path, conf.n, node)
    end)
end)

g_uisystem.reg_customize_action_type('PlayParticleAnimation', function(conf, node)
    return cc.CallFunc:create(function()
        local particleFile = conf['particleFile']
        if particleFile == '' then
            return
        end
        local obj = cc.ParticleSystemQuad:Create(particleFile)
        obj:setPositionType(conf['posType'])
        node:addChild(obj)
    end)
end)

g_uisystem.reg_customize_action_type('PlaySkeletonAnimation', function(conf, node)
    return cc.CallFunc:create(function()
        local animation_data = conf['animation_data']
        local jsonPath = animation_data.jsonPath
        local action = animation_data.action
        local path, _ = string.match(jsonPath, '(.*).json')
        local atlasPath = string.format('%s.atlas', path)
        local skeletonNode = sp.SkeletonAnimation:create(jsonPath, atlasPath)
        if is_valid_str(action) then
            skeletonNode:setAnimation(0, action, conf['isLoop'])
        end
        node:addChild(skeletonNode)
    end)
end)

g_uisystem.reg_decorate_action_type('Repeat', function(conf, node, action)
    return cc.Repeat:create(action, conf.n)
end)

g_uisystem.reg_decorate_action_type('EaseIn', function(conf, node, action)
    return cc.EaseIn:create(action, conf.p)
end)

g_uisystem.reg_decorate_action_type('EaseOut', function(conf, node, action)
    return cc.EaseOut:create(action, conf.p)
end)

g_uisystem.reg_decorate_action_type('EaseInOut', function(conf, node, action)
    return cc.EaseInOut:create(action, conf.p)
end)

g_uisystem.reg_decorate_action_type('EaseSineIn')
g_uisystem.reg_decorate_action_type('EaseSineOut')
g_uisystem.reg_decorate_action_type('EaseSineInOut')

g_uisystem.reg_decorate_action_type('EaseQuadraticActionIn')
g_uisystem.reg_decorate_action_type('EaseQuadraticActionOut')
g_uisystem.reg_decorate_action_type('EaseQuadraticActionInOut')

g_uisystem.reg_decorate_action_type('EaseCubicActionIn')
g_uisystem.reg_decorate_action_type('EaseCubicActionOut')
g_uisystem.reg_decorate_action_type('EaseCubicActionInOut')

g_uisystem.reg_decorate_action_type('EaseQuarticActionIn')
g_uisystem.reg_decorate_action_type('EaseQuarticActionOut')
g_uisystem.reg_decorate_action_type('EaseQuarticActionInOut')

g_uisystem.reg_decorate_action_type('EaseQuinticActionIn')
g_uisystem.reg_decorate_action_type('EaseQuinticActionOut')
g_uisystem.reg_decorate_action_type('EaseQuinticActionInOut')

g_uisystem.reg_decorate_action_type('EaseExponentialIn')
g_uisystem.reg_decorate_action_type('EaseExponentialOut')
g_uisystem.reg_decorate_action_type('EaseExponentialInOut')

g_uisystem.reg_decorate_action_type('EaseCircleActionIn')
g_uisystem.reg_decorate_action_type('EaseCircleActionOut')
g_uisystem.reg_decorate_action_type('EaseCircleActionInOut')

g_uisystem.reg_decorate_action_type('EaseElasticIn')
g_uisystem.reg_decorate_action_type('EaseElasticOut')
g_uisystem.reg_decorate_action_type('EaseElasticInOut')

g_uisystem.reg_decorate_action_type('EaseBackIn')
g_uisystem.reg_decorate_action_type('EaseBackOut')
g_uisystem.reg_decorate_action_type('EaseBackInOut')

g_uisystem.reg_decorate_action_type('EaseBounceIn')
g_uisystem.reg_decorate_action_type('EaseBounceOut')
g_uisystem.reg_decorate_action_type('EaseBounceInOut')

g_uisystem.reg_decorate_action_type('RepeatForever', function(conf, node, action)
    return cc.RepeatForever:create(action)
end)

g_uisystem.reg_decorate_action_type('Speed', function(conf, node, action)
    return cc.Speed:create(action, conf.speed)
end)
