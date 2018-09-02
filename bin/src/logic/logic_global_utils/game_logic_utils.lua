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
    if filePath == nil then
        return false
    elseif filePath == '' then
        return true
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
    local m = direct_import(string.format('cocos_ext.ui_system.edit_ctrls.%s', typeName))
    assert_msg(m, 'editor_utils_create_edit_ctrls [%s] not valid', typeName)
    return m.EditCtrl:New(typeName, ...)
end


function global_on_drop_file(filePath, position)
    g_logicEventHandler:Trigger('logic_event_on_drop_file', filePath, position)
end

