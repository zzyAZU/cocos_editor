
function create_edit_class(base, editTemplate)
    local editBaseClass = relative_import('edit_ctrl_base')['EditCtrlBase']
    if is_valid_str(base) then
        base = relative_import(base)['EditCtrl']
    elseif base == nil then
        base = editBaseClass
    end

    assert(issubclass(base, editBaseClass))

    local ret = CreateClass(base)

    if is_valid_str(editTemplate) then
        function ret:on_choose_template_name()
            return editTemplate
        end
    end

    return ret
end




--------------------------------------------------------------- validate type
local function _validateNum(_data, data, _validateParm)
    data = tonumber(data)

    if data == nil then
        return
    end

    local precision = _validateParm['precision']
    if is_number(precision) then
        local multi = 10 ^ precision
        data = math.round_number(data * multi) / multi
    end

    local min = _validateParm['min']
    if min then
        if data < min then
            return
        end
    else
        local min_b = _validateParm['min_b']
        if min_b then
            if data <= min_b then
                return
            end
        end
    end

    local max = _validateParm['max']
    if max then
        if data > max then
            return
        end
    else
        local max_b = _validateParm['max_b']
        if max_b then
            if data >= max_b then
                return
            end
        end
    end

    if not is_equal(_data, data) then
        return data
    end
end

local function _checkPos(x)
    if is_string(x) then
        local m = luaext_string_match(x, '([0-9.-]*)(%|i)?([0-9.-]*)')
        if m then
            local p1, p2, p3 = m[1], m[2], m[3]
            if p2 == '' then
                return tonumber(p1)
            elseif p2 == 'i' then
                return tonumber(p3) and p2..p3
            else
                return tonumber(p1) and (p3 == '' or tonumber(p3)) and x
            end
        end
    elseif is_number(x) then
        return x
    end
end

local function _checkSize(x)
    if is_string(x) then
        local m = luaext_string_match(x, '([0-9.-]*)(%|\\$|i)?([0-9.-]*)')
        if m then
            local p1, p2, p3 = m[1], m[2], m[3]
            if p2 == '' then
                return tonumber(p1)
            elseif p2 == 'i' then
                return tonumber(p3) and p2..p3
            else
                return tonumber(p1) and (p3 == '' or tonumber(p3)) and x
            end
        else
            printf('_checkSize %s not valid 1', str(x))
            return 0
        end
    elseif is_number(x) then
        return x
    else
        printf('_checkSize %s not valid 2', str(x))
        return 0
    end
end

local function _checkScale(x)
    if is_string(x) then
        local m = luaext_string_match(x, '([0-9.-]*)(w|s|q|k|g)?')
        if m then
            local p1, p2 = m[1], m[2]
            if p2 == '' then
                return tonumber(p1)
            else
                return tonumber(p1) and x
            end
        end
    elseif is_number(x) then
        return x
    end
end

local function _validTemplateInfo(ret)
    if is_table(ret) then
        ret = table.deepcopy(ret)
        ret['__template__'] = nil
        return ret
    else
        return false
    end
end

local function _validContainerTemplateInfo(ret)
    if is_table(ret) then
        ret = table.deepcopy(ret)
        for i, v in ipairs(ret) do
            if g_uisystem.load_template(v['template']) == nil or not is_table(v['template_info']) then
                return false
            end

            v['template_info']['__template__'] = nil
        end
        return ret
    else
        return false
    end
end

check_fun = {
    ['edit_type_string'] = function(_data, data, _validateParm)
        local ret = tostring(data)

        local re_pattern = _validateParm['re_pattern']
        if is_valid_str(re_pattern) then
            if not luaext_string_match(ret, re_pattern) then
                message('输入内容不匹配:{1}', re_pattern)
                return
            end
        end

        local min_len = _validateParm['min_len']
        if min_len then
            if #ret < min_len then
                return
            end
        end

        local max_len = _validateParm['max_len']
        if max_len then
            if #ret > max_len then
                return
            end
        end

        if not is_equal(_data, ret) then
            return ret
        end
    end,

    edit_type_number = _validateNum,

    ['edit_type_number2'] = function(_data, data, _validateParm)
        if is_table(data) then
            return data
        else
            data = string.split(tostring(data), ' ')
            if #data ~= 2 then
                return
            end

            local ret = table.copy(_data)
            local t1, t2 = unpack(_validateParm['target'])
            local n1 = _validateNum(_data and _data[t1], data[1], _validateParm)
            local n2 = _validateNum(_data and _data[t2], data[2], _validateParm)
            
            if n1 then
                ret[t1] = n1
            end
            if n2 then
                ret[t2] = n2
            end
            if not is_equal(_data, ret) then
                return ret
            end
        end
    end,

    ['edit_type_pos'] = function(_data, data, _validateParm)
        if is_table(data) then
            return data
        else
            local pos = string.split(tostring(data), ' ')
            if #pos ~= 2 then
                return
            end
            local ret = ccp(_checkPos(pos[1]), _checkPos(pos[2]))
            if not is_equal(_data, ret) then
                return ret
            end
        end
    end,

    ['edit_type_size'] = function(_data, data, _validateParm)
        if is_table(data) then
            return data
        else
            local pos = string.split(tostring(data), ' ')
            if #pos ~= 2 then
                return
            end

            local ret = CCSize(_checkSize(pos[1]), _checkSize(pos[2]))
            if not is_equal(_data, ret) then
                return ret
            end
        end
    end,

    ['edit_type_scale'] = function(_data, data, _validateParm)
        if is_table(data) then
            return data
        else
            local pos = string.split(tostring(data), ' ')
            if #pos ~= 2 then
                return
            end

            local ret = ccp(_checkScale(pos[1]), _checkScale(pos[2]))
            if not is_equal(_data, ret) then
                return ret
            end
        end
    end,

    ['edit_type_scale_1'] = function(_data, data, _validateParm)
        local ret = is_number(data) and data or _checkScale(tostring(data))
        if not is_equal(_data, ret) then
            return ret
        end
    end,

    ['edit_type_select_color'] = function(_data, data, _validateParm)
        local ret
        if is_string(data) then
            ret = tonumber('0x' .. data)
            if ret == nil then
                return
            end
        elseif is_number(data) then
            ret = data
        else
            ret = bit.lshift(data.r, 16) + bit.lshift(data.g, 8) + data.b
        end

        if ret < 0 then
            ret = 0
        elseif ret > 0xffffff then
            ret = 0xffffff
        end

        if not is_equal(_data, ret) then
            return ret
        end
    end,

    ['edit_type_select_sprite_frame'] = function(_data, data, _validateParm)
        if is_table(data) then
            if not is_equal(data, _data) then
                return data
            end
        end

        data = string.split(tostring(data), ' ')
        local plist, path
        if #data == 1 then
            path = data[1]
        elseif #data == 2 then
            plist = data[1]
            path = data[2]
        end

        if get_sprite_frame(path, plist) then
            local ret = {plist = plist, path = path}
            if not is_equal(_data, ret) then
                return ret
            end
        end
    end,

    ['edit_type_select_sprite_frame_name'] = function(_data, data, _validateParm)
        local ret = tostring(data)
        local plist = _validateParm['edit_conf'][_validateParm['plist']]

        if ret == '' or get_sprite_frame(ret, plist) then
            if not is_equal(_data, ret) then
                return ret
            end
        end
    end,

    ['edit_type_select_capinsets'] = function(_data, data, _validateParm)
        if is_table(data) then
            return data
        end

        local capInsets = string.split(tostring(data), ' ')
        if #capInsets ~= 4 then
            return
        end

        local ret = {}
        for i = 1, 4 do
            local n = math.round_number(tonumber(capInsets[i]))
            if n == nil  or n < 0 then
                n = 0
            end
            table.insert(ret, n)
        end
        local ret = CCRect(unpack(ret))
        if not is_equal(_data, ret) then
            return ret
        end
    end,

    ['edit_type_select_multilang'] = function(_data, data, _validateParm)
        local ret = is_number(data) and math.round_number(data) or tostring(data)
        if not is_equal(_data, ret) then
            return ret
        end
    end,

    ['edit_type_select_file'] = function(_data, data, _validateParm)
        local ret = string.gsub(tostring(data), '\\', '/')

        local validate_file = _validateParm['validate_file']
        if is_function(validate_file) then
            if not validate_file(ret) then
                return
            end
        else
            -- 默认检测方式
            if g_fileUtils:isFileExist(ret) then
                local ext = string.match(ret, '^.+/[^/]+%.([a-z]+)$')
                if ext == nil or not string.find(_validateParm['file_ext'], ext) then
                    return
                end
            else
                return
            end
        end

        if not is_equal(_data, ret) then
            return ret
        end
    end,

    ['edit_type_select_spine_file'] = function(_data, data, _validateParm)
        local ret = string.gsub(tostring(data.jsonPath), '\\', '/')

        local validate_file = _validateParm['validate_file']
        if is_function(validate_file) then
            if not validate_file(ret) then
                return
            end
        else
            -- 默认检测方式
            if g_fileUtils:isFileExist(ret) then
                local ext = string.match(ret, '^.+/[^/]+%.([a-z]+)$')
                if ext == nil or not string.find(_validateParm['file_ext'], ext) then
                    return
                end
            else
                return
            end
        end

        if not is_equal(_data, ret) then
            data.jsonPath = ret
            return data
        end
    end,

    ['edit_type_select_live2d_file'] = function(_data, data, _validateParm)
        local ret = string.gsub(tostring(data.jsonPath), '\\', '/')

        local validate_file = _validateParm['validate_file']
        if is_function(validate_file) then
            if not validate_file(ret) then
                return
            end
        else
            -- 默认检测方式
            if g_fileUtils:isFileExist(ret) then
                local ext = string.match(ret, '^.+/[^/]+%.([a-z]+)$')
                if ext == nil or not string.find(_validateParm['file_ext'], ext) then
                    return
                end
            else
                return
            end
        end

        if not is_equal(_data, ret) then
            data.jsonPath = ret
            return data
        end
    end,

    ['edit_type_select_template'] = function(_data, data, _validateParm)
        local ret = tostring(data)
        if g_uisystem.load_template(ret) and _data ~= ret then
            return ret
        end
    end,

    ['edit_type_template_info'] = function(_data, data, _validateParm)
        local ret = is_table(data) and data or eval(tostring(data))
        ret = _validTemplateInfo(ret)
        if ret and not is_equal(_data, ret) then
            return ret
        end
    end,

    ['edit_type_container_template_info'] = function(_data, data, _validateParm)
        local ret = is_table(data) and data or eval(tostring(data))
        local ret = _validContainerTemplateInfo(ret)
        if ret and not is_equal(_data, ret) then
            return ret
        end
    end,

    ['edit_type_select_action_ani'] = function(_data, data, _validateParm)
        local ret = tostring(data)
        if g_uisystem.load_ani_template(ret) and _data ~= ret then
            return ret
        end
    end,
    ['edit_type_list_pos'] = function(_data, data, _validateParm)
        if is_table(data) then
            return data
        else
            local pos = string.split(tostring(data), ' ')
            if #pos ~= 2 then
                return ccp(0, 0)
            end
            local ret = ccp(_checkPos(pos[1]), _checkPos(pos[2]))
            if not is_equal(_data, ret) then
                return ret
            end
        end
        return ccp(0, 0)
    end
}

