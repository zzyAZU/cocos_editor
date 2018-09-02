EditCtrl, Super = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_live2d_ctrl')


function EditCtrl:on_init_ui()
	self.edit.OnEditReturn = function(value)
        if not self._data then
            return
        end
		self._data.jsonPath = value
        if self:UpdateData(self._data) then
            self._editCallback(self._data)
        end
    end

    local title = self._validateParm['title'] or '选择文件'
    local file_type_name = self._validateParm['file_type_name'] or '文件'
    local ext = file_type_name .. '|' .. self._validateParm['file_ext'] or '*.*'
    --第一个按钮选择文件按钮
    self.btn1.OnClick = function()
        local value = win_open_file(title, g_logic_editor.get_project_res_path(), ext)
        if not is_valid_str(value) then
            return
        end

        if not self._data then
            return
        end
        self._data.jsonPath = value
        if self:UpdateData(self._data) then
            self._editCallback(self._data)
        end
    end

    self.btn2.OnClick = function()
        if not self._data then
            return
        end
        local jsonPath = self._data['jsonPath']
        if g_fileUtils:isFileExist(jsonPath) then
            os.execute('explorer /select, ' .. string.gsub(g_logic_editor.get_project_res_path() .. jsonPath, '/', '\\'))
        end
    end

    self.name:SetString(self._validateParm['name'])
    -- self.btn:SetText('选择')
    self.btn1:SetText('选择')
    self.btn2:SetText('打开')

    self.motion_name:SetString('选择motion')

    if self._ani_combo_data and is_valid_str(self._ani_combo_data) then
        self.motion_combo:SetString(self._ani_combo_data)
    else
        self.motion_combo:SetString('')
    end
end



-- override
function EditCtrl:on_update_data()
    if not self._data then  --兼容没有本地文件
        return
    end
    self.edit:SetText(tostring(self._data.jsonPath))
    self._ani_combo_data = self._data.motion or ''

    local fileStr = g_fileUtils:getStringFromFile(tostring(self._data.jsonPath))
    local plistConf = luaext_json_dencode(fileStr)

    if not is_table(plistConf) then
        return
    end

    local motionConfs = plistConf.motions


    self.motion_combo:SetItems({})
    for name, _ in pairs(motionConfs or {}) do
        if is_valid_str(name) then
            self.motion_combo:AddMenuItem(name, function()
                if self._ani_combo_data ~= name then
                    self.motion_combo:SetString(name)
                    self._ani_combo_data = name
                    self._data.motion = self._ani_combo_data
                    if self:UpdateData(self._data) then
                        self._editCallback(self._data)
                    end
                end
            end)
        end
    end


    if not is_valid_str(self._ani_combo_data) then
    	self._data.motion = self._ani_combo_data
    end 

    self.motion_combo:SetString(self._ani_combo_data)
end