EditCtrl, Super = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_spine_ctrl')

function EditCtrl:on_init_ui()
	self.edit.OnEditReturn = function(value)
		self._data.jsonPath = value
        if self:UpdateData(self._data) then
            self._editCallback(self._data)
        end
    end

    local title = self._validateParm['title'] or '选择文件'
    local file_type_name = self._validateParm['file_type_name'] or '文件'
    local ext = file_type_name .. '|' .. self._validateParm['file_ext'] or '*.*'
    --第一个按钮选择文件按钮
    self.btn.OnClick = function()
        value = win_open_file(title, g_logic_editor.get_project_res_path(), ext)
        if not is_valid_str(value) then
            return
        end
        self._data.jsonPath = value
        if self:UpdateData(self._data) then
            self._editCallback(self._data)
        end
    end

    self.name:SetString(self._validateParm['name'])
    self.btn:SetText('文件')

   	self.ani_name:SetString('选择动画名')
	-- self.ani_combo:SetItems({})
end


-- override
function EditCtrl:on_update_data()
    self.edit:SetText(tostring(self._data.jsonPath))
    self._ani_combo_data = self._data.action

    local fileStr = g_fileUtils:getStringFromFile(tostring(self._data.jsonPath))
    local plistConf = luaext_json_dencode(fileStr)

    if not is_table(plistConf) then
        return
    end
    local animationConfs = plistConf.animations

    self.ani_combo:SetItems({})
    for name, _ in pairs(animationConfs or {}) do
    	self.ani_combo:AddMenuItem(name, function()
    		if self._ani_combo_data ~= name then
    			self.ani_combo:SetString(name)
    			self._ani_combo_data = name
    			self._data.action = self._ani_combo_data
    			if self:UpdateData(self._data) then
		            self._editCallback(self._data)
		        end
    		end
    	end)


    	if not is_valid_str(self._ani_combo_data) then
    		self._ani_combo_data = name
    		self._data.action = self._ani_combo_data
    	end
    end 
    self.ani_combo:SetString(self._ani_combo_data)
end