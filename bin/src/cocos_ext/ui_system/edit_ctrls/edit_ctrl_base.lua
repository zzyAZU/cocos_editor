
EditCtrlBase = CreateClass()

-- override
function EditCtrlBase:__init__(typeName, data, validateParm, editConf, editCallback)
    validateParm['edit_conf'] = editConf

    -- print('~~~~~~~~~~')
    -- print(typeName, data, validateParm, editCallback)
    self._typeName = typeName
    self._editConf = editConf  -- 编辑的总配置
    self._checkFun = relative_import('edit_utils').check_fun[typeName]
    self._validateParm = validateParm
    self._editCallback = editCallback
    self._layer = g_uisystem.load_template_create(self:on_choose_template_name(), nil, self)
    self._data = nil
    self:UpdateData(data)
    self:on_init_ui()
end

-- override
function EditCtrlBase:on_init_ui()
    
end

-- 显示 template 名称
-- override
function EditCtrlBase:on_choose_template_name()
    error('override me')
end

-- 更新控件显示
-- override
function EditCtrlBase:on_update_data()
   error('override me')
end



function EditCtrlBase:GetCtrl()
    return self._layer
end

function EditCtrlBase:UpdateData(data)
    -- print('UpdateData', self._typeName, self._checkFun, data)
    if is_function(self._checkFun) then
        local data = self._checkFun(self._data, data, self._validateParm)
        if data then
            -- print('data changed:', self._data, data)
            self._data = data
            self:on_update_data()
            return true
        else
            self:on_update_data()
        end
    else
        self._data = data
        self:on_update_data()
        return true
    end
end
