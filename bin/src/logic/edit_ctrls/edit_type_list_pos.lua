EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_list_pos')

function EditCtrl:on_init_ui()
end

-- override
function EditCtrl:on_update_data()
	
	local total_item_count = #self._data
	self.posList:SetContentSize(250, total_item_count * 30)
	self:GetCtrl():SetContentSize(250, total_item_count * 30)
	self.posList:SetInitCount(0, false)
	self.posList:SetInitCount(total_item_count, false)
	
	for index = 1, total_item_count do
		local posItem = self.posList:GetItem(index)
		posItem.name:SetString(string.format('控制点%s:', index))

		local pos = self._data[index]
		posItem.edit:SetText(string.format('%s %s', tostring(pos.x), tostring(pos.y)))

		posItem.edit.OnEditReturn = function(value)
	        if self:TryUpdateData(index, value) then
	            self._editCallback(self._data)
	        end
    	end
	end
end

function EditCtrl:TryUpdateData(index, value)
	if is_function(self._checkFun) then
		local data = self._checkFun(self._data[index], value, self._validateParm)
		if data then
			self._data[index] = data
			return true
		end
	else
		self._data[index] = value
		return true
	end
end


function EditCtrl:UpdateData(data)
    -- print('UpdateData', self._typeName, self._checkFun, data)
    if is_function(self._checkFun) then
    	local isValid = true
    	for index = 1, #data do
    		local item_data = data[index]
    		if not self._checkFun(item_data, item_data, self._validateParm) then
    			isValid = false
    			return
    		end
    	end
    	if isValid then
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
