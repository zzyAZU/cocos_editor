--[[====================================
=
=           RichLabel 扩展
=
========================================]]
-- 特殊符号
-- 1.颜色:#cffffff...#n
-- 2.转义:##(所有需要显示#的地方都需要转义)
-- 3.自定义: #C[custom_id]content#n (custom_id match regex ^#C\\[([a-zA-Z_0-9]+)\\])

local _customCreateInfo = {}


function cc.RichLabel:Create(text, fontSize, maxw, hAlign)
    if maxw == nil then
        maxw = 0
    end

    if hAlign == nil then
        hAlign = cc.TEXT_ALIGNMENT_LEFT
    end
    return self:create(GetTextByLanguageI(text), fontSize, maxw, hAlign):_init()
end

--override
function cc.RichLabel:_registerInnerEvent()
    tolua_super(cc.RichLabel)._registerInnerEvent(self)
    self:_regInnerEvent('OnCustomEvent')
    self.eventHandler.newHandler.OnCustomEvent = function(custom_id, ...)
        assert(_customCreateInfo[custom_id])
    end
end

function cc.RichLabel:SetString(...)
    local ret = GetTextByLanguageI(...)
    self:setString(ret)
    return ret
end

cc.RichLabel.GetString = cc.RichLabel.getString

cc.RichLabel.SetFontSize = cc.RichLabel.setFontSize

cc.RichLabel.SetAlignment = cc.RichLabel.setHorizontalAlignment

cc.RichLabel.setAlignment = function(self, hAlight)
    self:setHorizontalAlignment(hAlight)
end

local function __g_create_custom_node_callback__(id, ...)
    -- print('__g_create_custom_node_callback__', id, ...)

    local createFun = _customCreateInfo[id]
    if is_function(createFun) then
        return createFun(...)
    else
        error_msg('__g_create_custom_node_callback__ id[%s] not exists', id)
    end
end

rawset(_G, '__g_create_custom_node_callback__', __g_create_custom_node_callback__)


function cc.RichLabel:rich_label_set_default_font(tp, fontPath)
    if g_fileUtils:isFileExist(fontPath) then
        self:set_font_name(tp, fontPath)
    else
        self:set_font_name(tp, g_constant_conf['constant_uisystem'].default_font_name)
    end
end

function cc.RichLabel.register_custom_format(custom_id, createFun)
    assert(is_string(custom_id) and string.match(custom_id, '[a-zA-Z_0-9]+'))
    assert(is_function(createFun))
    _customCreateInfo[custom_id] = createFun
end

function cc.RichLabel:EnableGrayEffect()
    if not cc_utils_is_support_sprite_ext_effect() then
        return
    end

    if self._isGray then
        return
    end
    self._isGray = true

    local program = cc_utils_add_program('shader/ccShader_Label.vert', 'shader/ccShader_RichLabel_UI_Gray.frag', cc.SHADER_LABEL_UI_GRAY_SCALE)
    if not program then
        return
    end
    local glprogramstate = cc.GLProgramState:getOrCreateWithGLProgramName(cc.SHADER_LABEL_UI_GRAY_SCALE)
    self:setGLProgramState(glprogramstate)
end

function cc.RichLabel:DisableExtEffect()
    if not cc_utils_is_support_sprite_ext_effect() then
        return
    end

    if not self._isGray then
        return
    end

    self._isGray = false

    local program = cc_utils_add_program('shader/ccShader_Label.vert', 'shader/ccShader_Label_normal.frag', cc.SHADER_LABEL_NORMAL_EXT)
    if not program then
        return
    end
    local glprogramstate = cc.GLProgramState:getOrCreateWithGLProgramName(cc.SHADER_LABEL_NORMAL_EXT)
    self:setGLProgramState(glprogramstate)
end