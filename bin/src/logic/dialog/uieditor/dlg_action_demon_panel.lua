
Panel = g_panel_mgr.new_panel_class('editor/uieditor/uieditor_action_demon')

-- overwrite
function Panel:init_panel(actionName)    
    self:updateAction(actionName)
end

function Panel:updateAction(actionName)
    if actionName == self.actionName then
        self:close_panel()
    else
        self.actionName = actionName

        local __temp_path = string.format("%s/action_demon_config/__temp_generate_%s.txt", g_fileUtils:getWritablePath(), actionName)
        if g_fileUtils:isFileExist(__temp_path) then
            local info_list = table.read_from_file(__temp_path)
            self:_drawActionByActionConfig(info_list)
        else
            editor_utils_generate_action_info(actionName, true, function(info_list)
                self:_drawActionByActionConfig(info_list)
            end)
        end
    end
end

function Panel:_drawActionByActionConfig(posList)
    if not self:get_layer():IsValid() then
        return
    end
    local drawNode = cc.DrawNode:create()
    self.node:AddChild(nil, drawNode)
    local lastPosition = posList[1]
    for _, pos in ipairs(posList) do
        drawNode:drawSegment(lastPosition, pos, 2, cc.c4f(0, 1, 0, 1))
        lastPosition = pos
    end
end