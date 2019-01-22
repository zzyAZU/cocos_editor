--[[====================================
=
=           ccui.EditBox 扩展
=
========================================]]
local constant_uisystem = g_constant_conf.constant_uisystem
local config_delay_destroy_edit_tag = 10000

local CCEditBoxExt, Super = tolua_get_class('CCEditBoxExt')

--override 创建的时候不用考虑基类初始化
function CCEditBoxExt:Create()
    return cc.ScrollView:create():CastTo(self):_init()
end

--override 
function CCEditBoxExt:_init()
    Super._init(self)
    self._bEnableMultiline = false
    self._hAlign = cc.TEXT_ALIGNMENT_RIGHT
    self._vAlign = cc.VERTICAL_TEXT_ALIGNMENT_CENTER
    self._edit = nil
    self._editText = nil

    self._isEnableRawText = true
    -- child node
    self.nodeText = cc.Node:create()
    self.nodeText:setAnchorPoint(ccp(0, 0))
    self.txt = cc.RichLabel:Create('', 25, 0, 0)
    self.txt:enableRawText(true)
    self.txtPlaceholder = cc.RichLabel:Create('', 25, 0, 0)
    self.txtPlaceholder:enableRawText(true)
    self.txtPlaceholder:SetAlignment(cc.TEXT_ALIGNMENT_RIGHT)
    self.btn = cc.Layer:Create()
    self.btn:setAnchorPoint(ccp(0, 0))

    self:addChild(self.nodeText)
    self:addChild(self.btn)
    self.nodeText:addChild(self.txt)
    self.nodeText:addChild(self.txtPlaceholder)

    self.btn:HandleTouchMove(true, true, true, '10w')
    self.btn.OnClick = function()
        self:_onEdit()
    end

    return self
end

if g_uisystem.is_text_left_to_right_order() then
    local oldInit = CCEditBoxExt._init
    function CCEditBoxExt:_init()
        local ret = oldInit(self)
        ret._hAlign = cc.TEXT_ALIGNMENT_LEFT
        ret.txtPlaceholder:SetAlignment(cc.TEXT_ALIGNMENT_LEFT)
        return ret
    end
end

--override
function CCEditBoxExt:_registerInnerEvent()
    self:_regInnerEvent('OnEditBegan')
    self:_regInnerEvent('OnEditEnded')
    self:_regInnerEvent('OnEditChanged')
    self:_regInnerEvent('OnEditReturn')
end

function CCEditBoxExt:_onEdit()
    if self._edit then
        return
    end
    -- 如果是password输入框，开始编辑的时候把原文本填入输入框
    if self._flag == cc.EDITBOX_INPUT_FLAG_PASSWORD then
        self.txt:SetString(self._editText)
    end

    local cw, ch = self:GetContentSize()
    local edit = ccui.EditBox:Create(CCSize(cw, ch), constant_uisystem.default_transparent_img_path)
    self:addChild(edit)
    edit:SetPosition('50%', '50%')
    edit:setAnchorPoint(ccp(0.5, 0.5))

    edit.newHandler.OnEditBegan = function(text)
        if not self:IsValid() then
            return
        end
        self.eventHandler:Trigger('OnEditBegan', text)
    end
    edit.newHandler.OnEditEnded = function(text)
        if not self:IsValid() then
            return
        end
        self:SetText(text)
        self.eventHandler:Trigger('OnEditEnded', text)
    end
    edit.newHandler.OnEditChanged = function(text)
        if not self:IsValid() then
            return
        end
        self:SetText(text)
        self.eventHandler:Trigger('OnEditChanged', text)
    end
    edit.newHandler.OnEditReturn = function(text)
        if not self:IsValid() then
            return
        end
        -- 避免 _edit 为 nil
        self:stopActionByTag(config_delay_destroy_edit_tag)
        self:DelayCallWithTag(0, config_delay_destroy_edit_tag, function()
            self.nodeText:setVisible(true)
            self._edit:removeFromParent()
            self._edit = nil
            
            --不支持富文本格式
            if not self._isEnableRawText then
                text = string.replace_four_utf_char_emoj(text)
            else
                text = string.filter_four_utf_char(text) 
            end
            self:SetText(text)
            
            self.eventHandler:Trigger('OnEditReturn', text)
        end)
    end

    local function _getScale(node)
        local curScale = 1
        while node ~= nil do
            curScale = curScale * node:getScaleY()
            node = node:getParent()
        end
        return curScale
    end
    edit:setFontSize(self._fontSize * _getScale(self))
    edit:setFontColor(self.txt:getTextColor())
    edit:setPlaceholderFontSize(self._fontSize)
    edit:setPlaceholderFontColor(self.txtPlaceholder:getTextColor())
    
    edit:setMaxLength(self._nMaxLength)
    edit:setReturnType(self._returnType)
    edit:setInputMode(self._inputMode)
    edit:setInputFlag(self._flag)

    local input_text = self.txt:getString()
    if not self._isEnableRawText then
        input_text = string.change_rich_label_emoj_to_utf8(input_text)
    end
    edit:SetText(input_text)

    self._edit = edit

    self:DelayCall(0, function()
        self.nodeText:setVisible(false)
        edit:touchDownAction(edit, 2)
    end)
end

--override
function CCEditBoxExt:SetContentSize(sw, sh)
    local sz = cc.ScrollView.SetContentSize(self, sw, sh)
    self:_updateTextPos()
    return sz
end

function CCEditBoxExt:SetText(text, ...)
    self._editText = text
    if self._flag == cc.EDITBOX_INPUT_FLAG_PASSWORD then
        text = self.txt:SetString(string.rep("*", #text))
    else
        text = self.txt:SetString(text, ...)
    end
    self.txt:setVisible(#text > 0)
    self.txtPlaceholder:setVisible(#text == 0)
    self:_updateTextPos()
    return text
end

function CCEditBoxExt:EnableMultiLine(bEnbale)
    self._bEnableMultiline = bEnbale
    self:_updateTextPos()
end

function CCEditBoxExt:setFontColor(color)
    self.txt:setTextColor(color)
end

function CCEditBoxExt:setFontSize(fontSize)
    self._fontSize = fontSize
    self.txt:SetFontSize(fontSize)
end

function CCEditBoxExt:SetPlaceHolder(...)
    return self.txtPlaceholder:SetString(...)
end

function CCEditBoxExt:setPlaceholderFontColor(color)
    self.txtPlaceholder:setTextColor(color)
end

function CCEditBoxExt:setPlaceholderFontSize(fontSize)
    self.txtPlaceholder:SetFontSize(fontSize)
end

function CCEditBoxExt:setAlignment(hAlign, vAlign)
    self._hAlign = hAlign
    self._vAlign = vAlign
end

function CCEditBoxExt:_updateTextPos()
    local contentSize
    local sw, sh = self:GetContentSize()
    self.txtPlaceholder:setMaxLineWidth(sw)
    if self._bEnableMultiline then
        self.txt:setMaxLineWidth(sw)
        contentSize = CCSize(sw, math.max(sh, self.txt:getContentSize().height))
    else
        self.txt:setMaxLineWidth(0)
        contentSize = CCSize(sw, sh)
    end
    self:setContentSize(contentSize)
    self.nodeText:setContentSize(contentSize)
    self.btn:SetContentSize(sw, sh)
    self:ResetContentOffset()
    self:ScrollToTop()

    local pos = {x = '50%', y = '50%'}
    local anchor = {x = 0.5, y = 0.5}
    if self._hAlign == cc.TEXT_ALIGNMENT_LEFT then
        pos.x = 0
        anchor.x = 0
    elseif self._hAlign == cc.TEXT_ALIGNMENT_RIGHT then
        pos.x = '100%'
        anchor.x = 1
    else
        assert(self._hAlign == cc.TEXT_ALIGNMENT_CENTER)
    end

    if self._vAlign == cc.VERTICAL_TEXT_ALIGNMENT_BOTTOM then
        pos.y = 0
        anchor.y = 0
    elseif self._vAlign == cc.VERTICAL_TEXT_ALIGNMENT_TOP then
        pos.y = '100%'
        anchor.y = 1
    else
        assert(self._vAlign == cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    end

    if self._bEnableMultiline then
        self.txt:setHorizontalAlignment(self._hAlign)
    end

    self.txt:setAnchorPoint(anchor)
    self.txt:SetPosition(pos.x, pos.y)
    self.txtPlaceholder:setAnchorPoint(anchor)
    self.txtPlaceholder:SetPosition(pos.x, pos.y)
end

function CCEditBoxExt:setMaxLength(nMaxLength)
    self._nMaxLength = nMaxLength
end

function CCEditBoxExt:setReturnType(returnType)
    self._returnType = returnType
end

function CCEditBoxExt:setInputMode(inputMode)
    self._inputMode = inputMode
end

function CCEditBoxExt:setInputFlag(inputFlag)
    self._flag = inputFlag
end

function CCEditBoxExt:getText()
    return self._editText
end

function CCEditBoxExt:getPlaceHolder()
    return self.txtPlaceholder:getString()
end

function CCEditBoxExt:EnableRawText(isEnabled)
    self._isEnableRawText = isEnabled
    self.txt:enableRawText(isEnabled)
end

CCEditBoxExt.SetString = CCEditBoxExt.SetText
CCEditBoxExt.GetString = CCEditBoxExt.getText
