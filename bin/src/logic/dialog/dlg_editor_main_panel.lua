--[[编辑器主面板]]

Panel = g_panel_mgr.new_panel_class('editor/editor_main_ui')

local constant_uieditor = g_constant_conf['constant_uieditor']
local constant_uisystem = g_constant_conf['constant_uisystem']

-- overwrite
function Panel:init_panel()
    self.uieditorPanel = g_panel_mgr.show_with_parent('dlg_uieditor_main_panel', self.nodeSub)
    self.anieditorPanel = g_panel_mgr.show_with_parent('dlg_anieditor_main_panel', self.nodeSub)
    self.toolsPanel = g_panel_mgr.show_with_parent('dlg_tools_main_panel', self.nodeSub)

    cc.CCCheckButton.LinkCheckView({self.checkUI, self.checkAni, self.checkTool}, {self.uieditorPanel:get_layer(), self.anieditorPanel:get_layer(), self.toolsPanel:get_layer()}, 1)

    self:set_panel_key_event_priority(-999999)
    self:set_panel_swallow_key_event(false)

    self.btnSetting.OnClick = function()
        g_panel_mgr.show('editor.dlg_setting_panel')
    end

    self.btnOpenResDir.OnClick = function()
        win_explorer(g_logic_editor.get_project_res_path())
    end

    -- 运行游戏
    self.btnRunGame.OnClick = function()
        local gameWorkDir = g_logic_editor.get_game_work_dir()
        if gameWorkDir then
            gameWorkDir = string.gsub(gameWorkDir, '/', '\\')
        else
            message('当前指向的资源目录不是一个有效的开发目录无法')
            return
        end

        local appName = string.match(win_get_exe_dir(), '^.+\\(.+%.exe)$')
        local exeDir = g_logic_editor.get_editor_root_path() .. 'engine/debug/' .. appName
        local cmd =string.format('start %s -workdir %s -app_name game -id game -console', exeDir, gameWorkDir)

        printf('cmd:%s', cmd)
        os.execute(cmd)
    end

    -- quick switch ui <-> ani
    self:add_key_event_callback({'KEY_SHIFT', 'KEY_TAB'}, function()
        if self.checkUI:GetCheck() then
            self:ShowActionAniEditor()
        else
            self:ShowUIEditor()
        end
    end)
end

function Panel:ShowUIEditor()
    self.checkUI:SetCheck(true, true)
end

function Panel:ShowActionAniEditor()
   self.checkAni:SetCheck(true, true) 
end
