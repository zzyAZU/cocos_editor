--需要根据其他属性来设置内容
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_combo')

function EditCtrl:on_update_data()
end


local function _getAniInfo(plist)

	local action2framepaths = {}
	local aniFrames = {}
	if not is_valid_str(plist) then
		return action2framepaths, aniFrames
	end
	local plistConf = utils_get_plist_conf(plist)
	local frames = plistConf['frames']

	if not is_table(frames) then
		print('frames', frames)
		return action2framepaths, aniFrames
	end

	for frameName, _ in sorted_pairs(frames) do
		local startIdx, endIdx = string.find(frameName, "|")
		if startIdx then
			local action = string.sub(frameName, 1, endIdx - 1)
			local actions = action2framepaths[action]
			if not actions then
				actions = {}
				action2framepaths[action] = actions
			end
			table.insert(actions, frameName)
		else
			table.insert(aniFrames, frameName)
		end
	end

	return action2framepaths, aniFrames
end

function EditCtrl:on_init_ui()
	self.name:SetString(self._validateParm['name'])
	--_editConf
	local plist = self._editConf.plist

	local action2framepaths, aniFrames = _getAniInfo(plist)

	local all_actions = table.keys(action2framepaths)
	if #all_actions > 0 then
		self.combo:SetString('')
		self.combo:SetItems({})
		for _, action in ipairs(all_actions) do
			self.combo:AddMenuItem(action, function()
				if action ~= self._data then
					self.combo:SetString(action)
					self._data = action
					self._editCallback(self._data)
				end
			end)
       	end
       	if not is_valid_str(self._data) or not table.find_v(all_actions, self._data) then
       		self._data = all_actions[1]
       		self._editCallback(self._data)
		end
		self.combo:SetString(self._data)
	else
		self._data = ""
		self.combo:SetString('')
		self.combo:SetItems({})
		self._editCallback(self._data)
	end
end