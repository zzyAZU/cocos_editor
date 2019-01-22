local function _calcStrPosByType(osx, x, width, bChangePercent)
    -- print('_calcStrPosByType', osx, x, width)
    local sx

    --从位置反推到position_str
    if tonumber(osx) then
        sx = math.round_number(x)
    else
        local percent = string.match(osx, '([0-9.-]*)%%')
        if percent then
            if bChangePercent then
                if width == 0 then
                    return '0%' .. math.round_number(x)
                end

                local p = math.round_number(x / width * 100)
                local n = math.round_number(x - width * p / 100)
                sx = p..'%'..tostring(n == 0 and '' or n)
            else
                local offset = math.round_number(x - width * percent / 100)
                if offset == 0 then
                    return percent .. '%'
                else
                    return percent .. '%' .. offset
                end
            end
        elseif string.sub(osx, 1, 1) == 'i' then
            sx = "i" .. tostring(math.round_number(width - x))
        else
            local scaleLen = string.match(osx, '([0-9.-]*)$')
            if scaleLen then
                --这样格式的长度不能改变
                sx = osx
            else
                sx = math.round_number(x)
            end
        end
    end
    
    return sx
end

--将坐标转换成osx,osy给定的坐标形式
function editor_utils_calc_str_position_by_type(osx, osy, x, y, parent_size, bChangePercent)
    -- print('editor_utils_calc_str_position_by_type', osx, osy, x, y, parent_size, str(parent_size))
    return _calcStrPosByType(osx, x, parent_size.width, bChangePercent), _calcStrPosByType(osy, y, parent_size.height, bChangePercent)
end

function editor_utils_is_valid_sprite_plist(filePath)
    if filePath == nil or filePath == '' then
        return false
    end

    local plistConf = utils_get_plist_conf(filePath)

    if not is_table(plistConf) or not is_table(plistConf['frames']) then
        return false
    end

    local metadata = plistConf['metadata']
    if not is_table(metadata) then
        return false
    end

    local textureFileName = metadata['realTextureFileName'] or metadata['textureFileName']

    return is_valid_str(textureFileName) and g_fileUtils:isFileExist(g_fileUtils:fullPathFromRelativeFile(textureFileName, filePath))
end

function editor_utils_is_valid_font_atlas_plist(filePath)
    if filePath == nil then
        return false
    elseif filePath == '' then
        return true
    end

    local plistConf = utils_get_plist_conf(filePath)

    if not is_table(plistConf) then
        return false
    end

    if plistConf['itemHeight'] and plistConf['itemWidth'] and plistConf['firstChar'] then
        return g_fileUtils:isFileExist(g_fileUtils:fullPathFromRelativeFile(tostring(plistConf['textureFilename']), filePath))
    else
        return false
    end
end

function editor_utils_is_valid_particle_plist(filePath)
    if filePath == nil then
        return false
    elseif filePath == '' then
        return true
    end

    local plistConf = utils_get_plist_conf(filePath)

    if not is_table(plistConf) then
        return false
    end

    if plistConf['duration'] and plistConf['emitterType'] then
        return g_fileUtils:isFileExist(g_fileUtils:fullPathFromRelativeFile(tostring(plistConf['textureFileName']), filePath))
    else
        return false
    end
end

function editor_utils_is_valid_spine_json(filePath)
    if filePath == nil then
        return false
    elseif filePath == '' then
        return true
    end

    local fileStr = g_fileUtils:getStringFromFile(filePath)
    if not is_valid_str(fileStr) then
        return false
    end

    local plistConf = luaext_json_dencode(fileStr)

    if not is_table(plistConf) then
        return false
    end

    if plistConf['skeleton'] and plistConf['bones'] then
        local path, _ = string.match(filePath, '(.*).json')
        local atlasPath = string.format('%s.atlas', path)
        local pngPath = string.format('%s.png', path)
        return g_fileUtils:isFileExist(atlasPath) and g_fileUtils:isFileExist(pngPath)
    else
        return false
    end
end

function editor_utils_is_valid_live2d_json(filePath)
    if filePath == nil then
        return false
    elseif filePath == '' then
        return true
    end

    local fileStr = g_fileUtils:getStringFromFile(filePath)
    if not is_valid_str(fileStr) then
        return false
    end

    local plistConf = luaext_json_dencode(fileStr)

    if not is_table(plistConf) then
        return false
    end
    if plistConf['textures'] and plistConf['model'] then
        local basePath, _ = string.match(filePath, '(.*)/.*.json')
        local localModelPath = plistConf['model']
        local modelPath = string.format('%s/%s', basePath, localModelPath)
        if not g_fileUtils:isFileExist(modelPath) then
            return false
        end
        for _, localTexturePath in ipairs(plistConf['textures']) do
            local texturePath = string.format("%s/%s", basePath, localTexturePath)
            if not g_fileUtils:isFileExist(texturePath) then
                return false
            end
        end
        return true
    end

    return false
end

function editor_utils_is_valid_3dmodel_file(filePath)
    -- todo...
    return true
end

function editor_utils_create_edit_ctrls(typeName, ...)
    local m = direct_import(string.format('logic.edit_ctrls.%s', typeName))
    assert_msg(m, 'editor_utils_create_edit_ctrls [%s] not valid', typeName)
    return m.EditCtrl:New(typeName, ...)
end

function editor_utils_capture_template_sprite(templateName, parent)
    local w, h = parent:GetContentSize()
    local p1, p2, p3, p4 = get_design_resolution()
    update_design_resolution(w, h, p3, p4)

    local previewNode = cc.Node:create()
    previewNode:SetContentSize(w, h)
    g_uisystem.load_template_create(templateName, previewNode)
    local renderTexture = cc.RenderTexture:create(w, h, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888, gl.DEPTH24_STENCIL8_OES)
    renderTexture:retain()
    renderTexture:begin()
    previewNode:visit()
    renderTexture:endToLua()

    local texture = renderTexture:getSprite():getTexture()
    local newSprite = cc.Sprite:createWithTexture(texture)
    parent:addChild(newSprite)
    newSprite:setScaleY(-1)
    newSprite:SetPosition('50%', '50%')
    renderTexture:release()
    
    update_design_resolution(p1, p2, p3, p4)

    return newSprite
end

function editor_utils_adjust_popup_layer_pos(popuplayer, pos)
    popuplayer:setPosition(pos)

    local w, h = popuplayer:GetContentSize()

    local anchor = {}
    local winSize = g_director:getWinSize()

    if pos.x + w > winSize.width then
        --右
        anchor.x = 1
    else
        --左
        anchor.x = 0
    end

    -- print(pos.y, h)
    if pos.y < h then
        --上
        anchor.y = 0
        if h + pos.y > winSize.height then
            pos.y = winSize.height - h
        end
    else
        --下
        anchor.y = 1
    end
    popuplayer:setPosition(pos)
    popuplayer:setAnchorPoint(anchor)
end

function editor_utils_is_valid_mp3_file(filePath)
    if filePath == nil then
        return false
    end

    return true
end

--action_name：预览的动作
--is_generate_local_res：生成本地图片
--generate_action_callback：生成动作回调函数
--generate_compelete_callback：预览生成完成回调
function editor_utils_generate_action_preview(action_name, is_generate_local_res, generate_action_callback, generate_compelete_callback)
    local container_node = cc.Node:create()
    local drawNode = cc.DrawNode:create()
    container_node:AddChild(nil, drawNode)
    local moveNode = cc.Node:create()
    container_node:AddChild(nil, moveNode)
    container_node:setVisible(false)
    local winSize = g_director:getWinSize()

    local lastPosition = ccp(winSize.width * 1 / 4,  winSize.height * 1 / 4)
    moveNode:SetPosition(lastPosition.x,  lastPosition.y)
    local startPositionY = lastPosition.x
    local target_pos = cc.p(lastPosition.x, winSize.height * 3 / 4)
    local action = nil
    if generate_action_callback then
        action = generate_action_callback(target_pos)
    else
        local move_to_action = cc.MoveTo:create(3, target_pos)
        local action_cls = cc[action_name]
        action = action_cls:create(move_to_action)
    end
    moveNode:runAction(action)

    print('start generate action preview')
    local start_x = lastPosition.x
    local frame = 0
    local max_frame = 90
    local curScene = g_director:getRunningScene()
    local everyFrame = function()
        if frame ~= nil and frame < max_frame then
            local curPositionY = moveNode:getPositionY()
            frame = frame + 1
            local curPosition = cc.p(start_x + frame / max_frame * winSize.width / 2, curPositionY)
            drawNode:drawSegment(lastPosition, curPosition, 2, cc.c4f(0, 1, 0, 1))
            lastPosition = curPosition
            return 0.01
        else
            container_node:setVisible(true)
            --生成截屏
            local renderTexture = cc.RenderTexture:create(winSize.width, winSize.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888, gl.DEPTH24_STENCIL8_OES)
            renderTexture:retain()
            renderTexture:begin()
            container_node:visit()
            renderTexture:endToLua()
            container_node:setVisible(false)
            -- container_node:setVisible(false)
            if not is_generate_local_res then --直接返回精灵
                local texture = renderTexture:getSprite():getTexture()
                local newSprite = cc.Sprite:createWithTexture(texture)
                newSprite:retain()
                newSprite:setScaleY(-1)
                container_node:DelayCall(0.1, function()
                    if generate_compelete_callback then
                        generate_compelete_callback(newSprite)
                    end
                    container_node:removeFromParent()
                    newSprite:release()
                end)
            else
                local __temp_path = string.format("__temp_generate_%s.png", action_name)
                local result = renderTexture:saveToFile(__temp_path, cc.IMAGE_FORMAT_PNG)
                local _full_path = g_fileUtils:getWritablePath()..__temp_path
                if result then
                    moveNode:DelayCall(1, function()
                        if g_fileUtils:isFileExist(_full_path) then
                            if generate_compelete_callback then
                                generate_compelete_callback(_full_path)
                            end
                            g_fileUtils:removeFile(_full_path)
                        end
                        container_node:removeFromParent()
                    end)
                end
            end
            renderTexture:release()            
            return nil
        end
    end
    container_node:DelayCall(0.01, function()
        return everyFrame()
    end)
    
    curScene:AddChild(nil, container_node)
end

function editor_utils_generate_action_info(action_name, is_generate_local_config, generate_action_callback)
    local position_info_list = {}
    local container_node = cc.Node:create()
    local moveNode = cc.Node:create()
    container_node:AddChild(nil, moveNode)
    local size = {width = 1280, height = 720}
    container_node:SetContentSize(size.width, size.height)
    container_node:setVisible(false)
    local lastPosition = ccp(size.width * 1 / 4,  size.height * 1 / 4)
    moveNode:SetPosition(lastPosition.x,  lastPosition.y)

    local target_pos = cc.p(lastPosition.x, size.height * 3 / 4)
    table.insert(position_info_list, lastPosition)
    local move_to_action = cc.MoveTo:create(3, target_pos)
    local action_cls = cc[action_name]
    local action = action_cls:create(move_to_action)
    moveNode:runAction(action)

    print('start generate action config')
    local start_x = lastPosition.x
    local frame = 0
    local max_frame = 90
    local everyFrame = function()
        if frame ~= nil and frame < max_frame then
            local curPositionY = moveNode:getPositionY()
            frame = frame + 1
            local curPosition = cc.p(start_x + frame / max_frame * size.width / 2, curPositionY)
            position_info_list[#position_info_list + 1] = curPosition
            return 0.01
        else
            if is_generate_local_config then
                local dir_action_demon_config = g_fileUtils:getWritablePath() .. 'action_demon_config'
                g_fileUtils:CreateDirectoryIfNotExist(dir_action_demon_config)
                local __temp_path = string.format("%s/__temp_generate_%s.txt", dir_action_demon_config, action_name)
                table.write_to_file(position_info_list, __temp_path)
            end
            if generate_action_callback then
                generate_action_callback(position_info_list)
            end
            return nil
        end
    end
    container_node:DelayCall(0.01, function()
        return everyFrame()
    end)
    
    g_director:getRunningScene():AddChild(nil, container_node)
end

-- 展示修饰动画
function editor_utils_show_ease_action_demo(text)
    local constant_uieditor = g_constant_conf['constant_uieditor']
    for _, key in ipairs(constant_uieditor.show_demon_anctions) do
        if key == text then
            if(not g_panel_mgr.get_panel('uieditor.dlg_action_demon_panel')) then --未打开
                g_panel_mgr.show_in_top_scene('uieditor.dlg_action_demon_panel',text)
            else 
                g_panel_mgr.run_on_panel('uieditor.dlg_action_demon_panel', function(panel)
                    panel:updateAction(text)
                end)
            end
            return
        end
    end
end
