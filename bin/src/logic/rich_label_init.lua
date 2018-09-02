
-- 根据info_prop_buy_config里面的物品id和物品数量获取图标和名字  #C[prop]id|count#n
cc.RichLabel.register_custom_format('prop', function(content, color, size, richLabel)
    local node = cc.Node:Create()
    local prop_id = nil
    local count = 1
    local index = string.find(content, '|')
    if index then
        prop_id = string.sub(content, 0, index - 1)
        count = string.sub(content, index + 1, #content)
    end
    
    local prop_data_buy = g_conf_mgr.get_conf('info_prop_buy_config')
    local prop_name = prop_data_buy[tonumber(prop_id)] and prop_data_buy[tonumber(prop_id)].name or ""
    local nameImg = "#C[item]"..prop_id.."#n"
    local languageIndex = g_native_conf.cur_multilang_index
    local labelName
    labelName = string.format("%s%sX%d",prop_name,nameImg, count)
    if languageIndex == 'cn' then
        labelName = string.format("%s%sX%d",prop_name,nameImg, count)
    else
        labelName = string.format("%s%s%dX",prop_name,nameImg, count)
    end
    local sptImg = cc.RichLabel:Create("#C[item]"..prop_id.."#n", size)
    local sptContent = cc.RichLabel:Create(labelName, size)
    local contWidth, contHeight = sptContent:GetContentSize()
    sptContent:setAnchorPoint(0, 0)
    sptContent:SetPosition(0, 0)
    node:addChild(sptContent)
    node:SetContentSize(contWidth, contHeight)
    return node
end)

-- 根据info_prop_buy_config里面的物品id获取图标 #C[item]prop_id*scale#n
cc.RichLabel.register_custom_format('item', function(content, color, size, richLabel)
    local node = cc.Node:Create()
    local prop_id = nil
    local scale = 1
    local index = string.find(content, '*')
    if index then
        prop_id = string.sub(content, 0, index - 1)
        scale = string.sub(content, index + 1, #content)
    else
        prop_id = content
    end
    scale = scale * 1.3

    local spt = nil
    local prop_img = get_prop_img_by_id(tonumber(prop_id))
    if prop_img and prop_img ~= '' then
        spt = cc.Sprite:Create('', prop_img)
    else
        spt = cc.Sprite:Create('', 'gui/badam_ui/common/blank.png')
    end
    local oldWidth, oldHeight = spt:GetContentSize()
    local newWidth = oldWidth * (size / oldHeight) * scale
    local newHeight = size * scale
    spt:SetContentSize(newWidth, newHeight)
    spt:SetPosition(0, -(newHeight - size) / 2)
    spt:setAnchorPoint(0, 0)
    node:addChild(spt)

    node:SetContentSize(newWidth, size)
    return node
end)


-- 带下划线可点击的
-- 有以下两种格式，text是要显示的文本，color是文本颜色，otherParamsStringToOnCustomEvent是传给事件的字符串参数
-- #C[underline]eventName::text*color*otherParamsStringToOnCustomEvent#n
-- #C[underline]eventName::text#n
cc.RichLabel.register_custom_format('underline', function(content, color, size, richLabel)
    local node = cc.Node:create()

    local event, text = string.match(content, '([a-z_A-Z]*)::(.+)')

    -- 让underline支持传参数给OnCustomEvent
    local paramText, paramColor, paramOthers = string.match(text, '(.-)%*(%x-)%*(.+)$')
    if paramText and paramColor and paramOthers then
        text = paramText
        color = ccc3FromHex("0x" .. paramColor)
    end

    local label = cc.Label:Create(text, nil, size)
    label:setAnchorPoint(ccp(0, 0))
    label:setColor(color)
    node:addChild(label)

    local lsz = label:getContentSize()
    node:setContentSize(lsz)

    local colorHex = bit.lshift(color.r, 16) + bit.lshift(color.g, 8) + color.b
    local colorHexInverse = bit.bnot(colorHex)

    local lineWidth = 2
    local line = cc.DrawNode:create()
    line:setLineWidth(lineWidth)
    line:setPosition(ccp(-lineWidth, 0))
    line:drawLine(ccp(0, 0), ccp(lsz.width, 0), ccc4fFromHex(colorHex + 0xff000000))
    node:addChild(line)

    if is_valid_str(event) then
        local layer = cc.Layer:Create()
        layer:HandleTouchMove(true, true, false, 0, false)
        layer:setContentSize(lsz)
        layer:setAnchorPoint(ccp(0, 0))
        node:addChild(layer)

        layer.OnClick = function()
            richLabel.eventHandler:Trigger('OnCustomEvent', 'underline', event, paramOthers)
        end

        layer.OnBegin = function()
            label:setColor(ccc3FromHex(colorHexInverse))
            line:clear()
            line:drawLine(ccp(0, 0), ccp(lsz.width, 0), ccc4fFromHex(colorHexInverse + 0xff000000))
            return true
        end

        layer.OnEnd = function()
            label:setColor(ccc3FromHex(colorHex))
            line:clear()
            line:drawLine(ccp(0, 0), ccp(lsz.width, 0), ccc4fFromHex(colorHex + 0xff000000))
        end
    end

    return node
end)

-- 图片 #C[image]path*scale#n
cc.RichLabel.register_custom_format('image', function(content, color, size, richLabel)
    local node = cc.Node:Create()
    local image = nil
    local scale = 1
    local index = string.find(content, '*')
    if index then
        image = string.sub(content, 0, index - 1)
        scale = string.sub(content, index + 1, #content)
    else
        image = content
    end
    scale = scale * 1.3
    if image and image ~= '' then
        local spt = cc.Sprite:Create('', image)
        local oldWidth, oldHeight = spt:GetContentSize()
        local newWidth = oldWidth * (size / oldHeight) * scale
        local newHeight = size * scale
        spt:SetContentSize(newWidth, newHeight)
        spt:SetPosition(0, -(newHeight - size) / 2)
        spt:setAnchorPoint(0, 0)
        node:addChild(spt)
        node:SetContentSize(newWidth, size)
    else
        error('image command with a wrong image path in rich label')
    end
    return node
end)

-- 动画
local CCAnimateSprite = tolua_get_class('CCAnimateSprite')
cc.RichLabel.register_custom_format('animation', function(content, color, size, richLabel)
    local obj = CCAnimateSprite:Create()
    obj:SetFrameDelay(0.1)
    obj:SetAniSptDisplayFrameByPath(content, nil, true)
    obj:Play(-1, true)
    return obj
end)

cc.RichLabel.register_custom_format('template', function(content, color, size, richLabel)
    return g_uisystem.load_template_create(content)
end)

cc.RichLabel.register_custom_format('label', function(content, color, size, richLabel)
    local obj = cc.RichLabel:Create(content, size)
    obj:setTextColor(color)
    obj:enableRawText(true)
    return obj
end)


-- 图片 #C[charmap]path*str*scale#n
cc.RichLabel.register_custom_format('charmap', function(content, color, size, richLabel)
    local node = cc.Node:Create()
    local altasPath, labelContent, scale = string.match(content, "(.*)%*(.*)%*([%d%.]+)")
    if altasPath and altasPath ~= "" then
        local label = cc.Label:CreateWithCharMap(altasPath)
        node:addChild(label)
        label:setString(labelContent)
        label:setAnchorPoint(0, 0)
        label:setScale(scale)
        local oldWidth, oldHeight = label:GetContentSize()
        local newWidth = oldWidth * scale
        local newHeight = oldHeight * scale

        node:SetContentSize(newWidth, newHeight)
    end

    return node
end)

-- 超链接 #C[link]title#href
-- #C[link]百度#http://www.baidu.com#n
cc.RichLabel.register_custom_format('link', function(content, color, size, richLabel)
    local node = cc.Node:create()

    local title, href_url = string.match(content, "(.*)#(http.*)")

    if not title then
        title = content
        href_url = content
    end

    local label = cc.Label:Create(title, nil, size)
    label:setAnchorPoint(ccp(0, 0))
    label:setColor(color)
    node:addChild(label)

    local lsz = label:getContentSize()
    node:setContentSize(lsz)
    local layer = cc.Layer:Create()
    layer:HandleTouchMove(true, true, true, 20, false)
    layer:setContentSize(lsz)
    layer:setAnchorPoint(ccp(0, 0))
    node:addChild(layer)

    local colorHex = bit.lshift(color.r, 16) + bit.lshift(color.g, 8) + color.b
    local colorHexInverse = bit.bnot(colorHex)

    layer.OnClick = function()
        cc.Application:getInstance():openURL(href_url)
    end

    layer.OnBegin = function()
        label:setColor(ccc3FromHex(colorHexInverse))
        return true
    end

    layer.OnEnd = function()
        label:setColor(ccc3FromHex(colorHex))
    end

    layer.OnCancel = function()
        label:setColor(ccc3FromHex(colorHex))
    end

    return node
end)

-- 图片 #C[emoj]path#n
cc.RichLabel.register_custom_format('emoj', function(content, color, size, richLabel)
   
    local node = cc.Node:Create()
    if not content then
        return node
    end
    local is_exist_emoj, file_path = utils_is_exist_emoj(content)
    if not is_exist_emoj then
        return node
    end

    size = size * 1.2
    local spt = cc.Sprite:Create('', file_path)
    local oldWidth, oldHeight = spt:GetContentSize()
    local newWidth = oldWidth * (size / oldHeight)
    local newHeight = size
    spt:SetContentSize(newWidth, newHeight)
    spt:SetPosition(0, -(newHeight - size) / 2)
    spt:setAnchorPoint(0, 0)
    node:addChild(spt)
    node:SetContentSize(newWidth, size)
    
    return node
end)

-- scale不是必需的，scale为2表示放大20%
-- labelAtlas #C[atlas]number*scale#n
cc.RichLabel.register_custom_format('atlas', function(content, color, size, richLabel)
    local node = cc.Node:Create()
    local targetScale = 1
    local targetNumber = ""
    --
    if string.match(content, '(%d+)%*(%d+)') then
        local number, scale = string.match(content, '(%d+)%*(%d+)')
        targetScale = targetScale * scale * 0.01
        targetNumber = number
    elseif string.match(content, '(%d+)') then
        targetNumber = string.match(content, '(%d+)')
    end
    -- 
    local obj = cc.Label:CreateWithCharMap(g_conf_mgr.get_constant('constant').DEFAULT_TURNTABLE_GAME_NUMER)
    obj:setString(targetNumber)
    obj:setScale(targetScale)
    local oldWidth, oldHeight = obj:GetContentSize()
    local newHeight = size * targetScale
    local newWidth = oldWidth * targetScale + newHeight / 4
    obj:SetPosition(newHeight / 8, newHeight / 2)
    obj:setAnchorPoint(0, 0.5)
    node:addChild(obj)

    node:SetContentSize(newWidth, size)
    return node
end)