
EditCtrl = relative_import('edit_utils').create_edit_class(nil, 'editor/edit/uieditor_edit_callback_btn')

--点击
function EditCtrl:on_init_ui()
	self.btn.OnClick = function()
		if self._editCallback then
			self._editCallback()
		end
    end
    if self._validateParm and self._validateParm['edit_name'] then
    	self.btn:SetString(self._validateParm['edit_name'])
    end
end

function EditCtrl:on_update_data()
end