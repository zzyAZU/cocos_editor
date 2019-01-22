    --[[====================================
=
=           ui 控件注册
=
========================================]]
import('cocos_ext.cocos_ext')

-- 2d
local CCNode = cc.Node
local CCLayer = cc.Layer
local CCLayerColor = cc.LayerColor
local CCLayerGradient = cc.LayerGradient
local CCSprite = cc.Sprite
local CCLabel = cc.Label
local CCScrollView = cc.ScrollView
local CCRichLabel = cc.RichLabel
local CCButton = cc.CCButton
local CCCheckButton = cc.CCCheckButton
local CCEditBoxExt = cc.CCEditBoxExt
local CCAnimateSprite = cc.CCAnimateSprite
local CCContainer = cc.CCContainer
local AsyncContainer = cc.AsyncContainer
local SCrollList = cc.SCrollList
local SCrollPage = cc.SCrollPage
local AsyncList = cc.AsyncList
local TemplateNode = cc.TemplateNode
local CCCombobox = cc.CCCombobox
local CCTreeView = cc.CCTreeView
local CCRectangle = cc.CCRectangle
local CCSlider = cc.CCSlider
local CCLoadingBar = cc.CCLoadingBar

-- 3d
local CCCamera = cc.Camera
local CCSprite3D = cc.Sprite3D
-- local CCDrawNode3D = cc.



local constant = g_constant_conf.constant_uisystem

local s_winSize = g_director:getWinSize()



if g_application:getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
    local oldFun = cc.Node.SetPosition
    function cc.Node:SetPosition(x, y)
        self._x = x
        self._y = y
        return oldFun(self, x, y)
    end
    local listRecordContentSize = {
        cc.Node,
        cc.ScrollView,
        CCRectangle,
        CCButton,
        CCCombobox,
        CCEditBoxExt,
        cc.Live2DSprite,
        CCLoadingBar,
        CCSlider,
        SCrollList,
    }

    for _, cls in ipairs(listRecordContentSize) do
        local oldFun = cls.SetContentSize
        function cls:SetContentSize(w, h)
            self._w = w
            self._h = h
            return oldFun(self, w, h)
        end
    end

    function cc.Node:SetContentSizeAndReposChild(sw, sh, filterCallback)
        self:SetContentSize(sw, sh)
        local function _reorderSizeAndPosition(ctrl)
            if ctrl._x then
                ctrl:SetPosition(ctrl._x, ctrl._y)
            end

            if ctrl._w then
                ctrl:SetContentSize(ctrl._w, ctrl._h)
            end

            for _, child in ipairs(ctrl:getChildren()) do
                _reorderSizeAndPosition(child)
            end
        end
        for _, child in ipairs(self:getChildren()) do
            if filterCallback == nil or filterCallback(child) then
                _reorderSizeAndPosition(child)
            end
        end
    end
end


g_uisystem.RegisterControl('CCNode', nil, function(uicfg)
    --attr
    uicfg:RegAttr('name')
    uicfg:RegAttr('lock')
    uicfg:RegAttr('assign_root')
    uicfg:RegAttr('pos')
    uicfg:RegAttr('size')
    uicfg:RegAttr('anchor')
    uicfg:RegAttr('scale')
    uicfg:RegAttr('rotation')
    uicfg:RegAttr('skew')
    uicfg:RegAttr('hide')
    uicfg:RegAttr('zorder')
    uicfg:RegAttr('ani_data')
    uicfg:RegAttr('child_list')

    --reg create
    uicfg:RegCreate(function(parent, root)
        return CCNode:Create()
    end)

    --create order
    uicfg:InsertSetAttrOrder({'name', 'assign_root', 'zorder', 'pos', 'hide', 'anchor', 'rotation', 'skew', 'scale', 'size'})

    uicfg:RegSetAttr('name', function(obj, parent, root, name, assign_root, zorder, pos, hide, anchor, rotation, skew, scale, size)
    	if parent then
        	parent:addChild(obj, zorder)
        end

        if name ~= '' then
            if assign_root then
            	if root then
                	root[name] = obj
                end
            elseif parent then
                parent[name] = obj
            end
        end

        obj:SetPosition(pos.x, pos.y)
        obj:setVisible(not hide)
        obj:setIgnoreAnchorPointForPosition(false)
        obj:setAnchorPoint(anchor)
        obj:setRotation(rotation)
        obj:setSkewX(skew.x)
        obj:setSkewY(skew.y)
        obj:setScaleX(ccext_get_scale(scale.x))
        obj:setScaleY(ccext_get_scale(scale.y))

        obj:SetContentSize(size.width, size.height)

        -- debug
        -- obj.__name__ = name
    end)
end)

g_uisystem.RegisterControl('CCLayer', 'CCNode', function(uicfg)
    uicfg:RegAttr('touchEnabled')
    uicfg:RegAttr('swallow')
    uicfg:RegAttr('noEventAfterMove')
    uicfg:RegAttr('move_dist')
    uicfg:RegAttr('forceHandleTouch')

    uicfg:RegCreate('touchEnabled', 'swallow', 'noEventAfterMove', 'move_dist', 'forceHandleTouch', 
        function(parent, root, touchEnabled, swallow, noEventAfterMove, move_dist, forceHandleTouch)
            local obj = CCLayer:Create()
            obj:HandleTouchMove(touchEnabled, swallow, noEventAfterMove, move_dist, forceHandleTouch)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCLayerColor', 'CCNode', function(uicfg)
    uicfg:RegAttr('color')
    uicfg:RegAttr('opacity')

    uicfg:RegCreate('color', 'opacity', 
        function(parent, root, color, opacity)
            return CCLayerColor:Create(ccc4aFromHex(color + bit.lshift(opacity, 24)), 0, 0)
        end)
end)

g_uisystem.RegisterControl('CCLayerGradient', 'CCNode', function(uicfg)
    uicfg:RegAttr('startColor')
    uicfg:RegAttr('endColor')
    uicfg:RegAttr('startOpacity')
    uicfg:RegAttr('endOpacity')
    uicfg:RegAttr('vector')

    uicfg:RegCreate('startColor', 'endColor', 'startOpacity', 'endOpacity', 'vector',
        function(parent, root, sc, ec, so, eo, v)
            return CCLayerGradient:Create(ccc4aFromHex(sc + bit.lshift(so, 24)), ccc4aFromHex(ec + bit.lshift(eo, 24)), v)
        end)
end)

g_uisystem.RegisterControl('LayerRadialGradient', 'CCNode', function(uicfg)
    uicfg:RegAttr('startColor')
    uicfg:RegAttr('endColor')
    uicfg:RegAttr('startOpacity')
    uicfg:RegAttr('endOpacity')
    uicfg:RegAttr('radius')
    uicfg:RegAttr('center')
    uicfg:RegAttr('expand')

    uicfg:RegCreate('startColor', 'endColor', 'startOpacity', 'endOpacity', 'radius', 'center', 'expand',
        function(parent, root, sc, ec, so, eo, radius, center, expand)
            return cc.LayerRadialGradient:Create(ccc4aFromHex(sc + bit.lshift(so, 24)), ccc4aFromHex(ec + bit.lshift(eo, 24)), radius, center, expand)
        end)
end)

g_uisystem.RegisterControl('CCSprite', 'CCNode', function(uicfg)
    uicfg:RegAttr('displayFrame')
    uicfg:RegAttr('color')
    uicfg:RegAttr('opacity')
    uicfg:RegAttr('blendFun')

    uicfg:RegCreate('displayFrame', 'color', 'opacity', 'blendFun', 
        function(parent, root, displayFrame, color, opacity, blendFun)
            local obj = CCSprite:Create(displayFrame.plist, displayFrame.path)
            obj:setStretchEnabled(false)
            obj:setColor(ccc3FromHex(color))
            obj:setOpacity(opacity)
            obj:setBlendFunc(blendFun)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCScale9Sprite', 'CCNode', function(uicfg)
    uicfg:RegAttr('spriteFrame')
    uicfg:RegAttr('capInsets')
    uicfg:RegAttr('color')
    uicfg:RegAttr('opacity')
    uicfg:RegAttr('blendFun')

    uicfg:RegCreate('spriteFrame', 'capInsets', 'color', 'opacity', 'blendFun',
        function(parent, root, spriteFrame, capInsets, color, opacity, blendFun)
            local obj = CCSprite:Create(spriteFrame.plist, spriteFrame.path)
            obj:setStretchEnabled(true)
            obj:setCenterRect(capInsets)
            obj:setColor(ccc3FromHex(color))
            obj:setOpacity(opacity)
            obj:setBlendFunc(blendFun)
            return obj
        end)
end)

g_uisystem.RegisterControl('RepeatSprite', 'CCNode', function(uicfg)
    uicfg:RegAttr('img')
    uicfg:RegAttr('color')
    uicfg:RegAttr('opacity')
    uicfg:RegAttr('blendFun')
    uicfg:RegAttr('addressMode')

    uicfg:RegCreate('img', 'color', 'opacity', 'blendFun', 'addressMode',
        function(parent, root, img, color, opacity, blendFun, addressMode)
            if cc.RepeatSprite then
                local obj = cc.RepeatSprite:create(img)
                obj:setAddressMode(addressMode)
                obj:setColor(ccc3FromHex(color))
                obj:setOpacity(opacity)
                obj:setBlendFunc(blendFun)
                return obj
            else
                return CCNode:create()
            end
        end)
end)

g_uisystem.RegisterControl('RichLabel', 'CCNode', function(uicfg)
    uicfg:RegAttr('font_size')
    uicfg:RegAttr('max_width')
    uicfg:RegAttr('h_align')
    uicfg:RegAttr('text')
    uicfg:RegAttr('color')
    uicfg:RegAttr('spacing')

    -- 老的编辑器的label默认转成 rich label
    uicfg:RegCheckConf(function(conf)
        local dimensions = conf['dimensions']
        if dimensions then
            conf['max_width'] = dimensions.width
        end
    end)

    uicfg:RegAttrAlias('font_size', 'fontSize')
    uicfg:RegAttrAlias('h_align', 'hAlign')

    uicfg:RegCreate('font_size', 'h_align', 'text', 'color', 'max_width', 'scale', 'spacing',
        function(parent, root, font_size, h_align, text, color, max_width, scale, spacing)
            local width = parent and parent:GetContentSize() or s_winSize.width

            local maxw = ccext_calc_pos(max_width, width, ccext_get_scale(scale.x))

            local obj = CCRichLabel:Create(text, font_size, maxw, h_align)
            obj:setTextColor(ccc3FromHex(color))
            obj:setLineSpacing(spacing)
            obj:updateContent()

            return obj
        end)
end)

g_uisystem.RegisterControl('_commonCCLabel', 'CCNode', function(uicfg)
    uicfg:RegAttr('fontSize')
    uicfg:RegAttr('dimensions')
    uicfg:RegAttr('hAlign')
    uicfg:RegAttr('vAlign')
    uicfg:RegAttr('text')
    uicfg:RegAttr('color')
    uicfg:RegAttr('opacity')
    uicfg:RegAttr('spacing')

    uicfg:RegAttr('bEnableOutline')
    uicfg:RegAttr('shadowColor')
    uicfg:RegAttr('shadowWidth')

    uicfg:RegAttr('bEnableShadow')
    uicfg:RegAttr('shadowColor1')
    uicfg:RegAttr('shadowOffset')
end)

g_uisystem.RegisterControl('TTFLabel', '_commonCCLabel', function(uicfg)
    uicfg:RegAttr('fontName')
    uicfg:RegAttr('bEnableGlow')
    uicfg:RegAttr('glowColor')

    uicfg:RegCreate('fontName', 'fontSize', 'dimensions', 'hAlign', 'vAlign', 'text', 'color', 'opacity', 'bEnableOutline', 'shadowColor', 'shadowWidth', 'bEnableShadow', 'shadowColor1', 'shadowOffset', 'scale', 'spacing', 'bEnableGlow', 'glowColor',
        function(parent, root, fontName, fontSize, dimensions, hAlign, vAlign, text, color, opacity, bEnableOutline, shadowColor, shadowWidth, bEnableShadow, shadowColor1, shadowOffset, scale, spacing, bEnableGlow, glowColor)
            local width, height = parent:GetContentSize()
            local w = ccext_calc_pos(dimensions.width, width, ccext_get_scale(scale.x))
            local h = ccext_calc_pos(dimensions.height, height, ccext_get_scale(scale.y))

            local obj = CCLabel:Create('', fontName, fontSize, CCSize(w, h), hAlign, vAlign)

            obj:setColor(ccc3FromHex(color))
            obj:setOpacity(opacity)
            obj:setLineSpacing(spacing)

            if bEnableOutline then
                obj:enableOutline(ccc4aFromHex(0xff000000 + shadowColor), shadowWidth)
            end

            if bEnableShadow then
                obj:enableShadow(ccc4aFromHex(0xff000000 + shadowColor1), shadowOffset, 0)
            end

            if bEnableGlow then
                obj:enableGlow(ccc4aFromHex(0xff000000 + glowColor))
            end

            -- setLineBreakWithoutSpace
            -- setClipMarginEnabled
            -- setTextColor
            -- disableEffect

            obj:SetString(text)

            return obj
        end)
end)

g_uisystem.RegisterControl('SystemLabel', '_commonCCLabel', function(uicfg)
    uicfg:RegCreate('fontSize', 'dimensions', 'hAlign', 'vAlign', 'text', 'color', 'opacity', 'bEnableOutline', 'shadowColor', 'shadowWidth', 'bEnableShadow', 'shadowColor1', 'shadowOffset', 'scale', 'spacing',
        function(parent, root, fontSize, dimensions, hAlign, vAlign, text, color, opacity, bEnableOutline, shadowColor, shadowWidth, bEnableShadow, shadowColor1, shadowOffset, scale, spacing)
            local width, height = parent:GetContentSize()
            local w = ccext_calc_pos(dimensions.width, width, ccext_get_scale(scale.x))
            local h = ccext_calc_pos(dimensions.height, height, ccext_get_scale(scale.y))

            local obj = CCLabel:Create('', '', fontSize, CCSize(w, h), hAlign, vAlign)

            obj:setColor(ccc3FromHex(color))
            obj:setOpacity(opacity)
            obj:setLineSpacing(spacing)

            if bEnableOutline then
                obj:enableOutline(ccc4aFromHex(0xff000000 + shadowColor), shadowWidth)
            end

            if bEnableShadow then
                obj:enableShadow(ccc4aFromHex(0xff000000 + shadowColor1), shadowOffset, 0)
            end

            obj:SetString(text)

            return obj
        end)
end)

g_uisystem.RegisterControl('CCLabelAtlas', 'CCNode', function(uicfg)
    uicfg:RegAttr('fntFile')
    uicfg:RegAttr('text')
    uicfg:RegAttr('color')
    uicfg:RegAttr('opacity')

    uicfg:RegCreate('fntFile', 'text', 'color', 'opacity', 
        function(parent, root, fntFile, text, color, opacity)
            local obj
            if fntFile == '' then
                obj = CCLabel:Create()
            else
                obj = CCLabel:CreateWithCharMap(fntFile)
            end
            
            obj:SetString(text)
            obj:setColor(ccc3FromHex(color))
            obj:setOpacity(opacity)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCLabelBMFont', 'CCLabelAtlas', function(uicfg)
    uicfg:RegAttr('hAlignment')
    uicfg:RegAttr('maxLineWidth')
    uicfg:RegAttr('imageOffset')

    uicfg:RegCreate('fntFile', 'text', 'color', 'opacity', 'hAlignment', 'maxLineWidth', 'imageOffset',
        function(parent, root, fntFile, text, color, opacity, hAlignment, maxLineWidth, imageOffset)
            local obj
            if fntFile == '' then
                obj = CCLabel:Create()
            else
                obj = CCLabel:CreateWithBMFont(fntFile, '', hAlignment, maxLineWidth, imageOffset)
            end
            obj:SetString(text)
            obj:setColor(ccc3FromHex(color))
            obj:setOpacity(opacity)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCRectBorder', 'CCNode', function(uicfg)
    uicfg:RegAttr('line_weight')
    uicfg:RegAttr('line_color')

    uicfg:RegCreate('line_weight', 'line_color', 
        function(parent, root, line_weight, line_color)
            return CCRectangle:Create(line_weight, line_color)
        end)
end)

g_uisystem.RegisterControl('CCWebView', 'CCNode', function(uicfg)
    uicfg:RegAttr('url')
    uicfg:RegAttr('scale_page')

    uicfg:RegCreate('scale_page', 'url', 
        function(parent, root, scale_page, url)
            if g_application:getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
                local webviewButton = CCButton:Create()
                local function initWebviewButton(curButton, curUrl)
                    local content = string.format( "ClickMe:%s", str(curUrl))
                    curButton:SetEnableText(true)
                    curButton:SetText(content, 24, 0xeeeeee, 0xaaaaaa, 0xdddddd)
                    curButton._text:setMaxLineWidth(parent:getContentSize().width - 50)
                    curButton._text:setAlignment(cc.TEXT_ALIGNMENT_CENTER, cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
                    curButton.OnClick = function()
                        g_application:openURL(curUrl)
                    end
                end
                initWebviewButton(webviewButton, url)
                webviewButton.loadURL = function(node, newUrl)
                    initWebviewButton(webviewButton, newUrl)
                end
                local function emptyFunc()
                    message("there is no webview support on windows!")
                end
                webviewButton.setOnShouldStartLoading = emptyFunc
                webviewButton.setOnDidFinishLoading = emptyFunc
                webviewButton.setOnDidFailLoading = emptyFunc
                webviewButton.evaluateJS = emptyFunc
                webviewButton.setScalesPageToFit = emptyFunc
                webviewButton.reload = emptyFunc
                webviewButton.goForward = emptyFunc
                webviewButton.goBack = emptyFunc
                webviewButton.loadFile = emptyFunc
                webviewButton.loadHTMLString = emptyFunc
                return webviewButton
            else
                return ccexp.WebView:Create(scale_page, url)
            end
        end)
end)

g_uisystem.RegisterControl('_commonButton', 'CCNode', function(uicfg)
    uicfg:RegAttr('9sprite')
    uicfg:RegAttr('capInsets')
    uicfg:RegAttr('plist')
    uicfg:RegAttr('frame1')
    uicfg:RegAttr('frame2')
    uicfg:RegAttr('frame3')
    uicfg:RegAttr('enableText')
    uicfg:RegAttr('text')
    uicfg:RegAttr('fontSize')
    uicfg:RegAttr('textColor1')
    uicfg:RegAttr('textColor2')
    uicfg:RegAttr('textColor3')
    uicfg:RegAttr('textOffset')
    uicfg:RegAttr('isEnabled')
    uicfg:RegAttr('zoomScale')
    uicfg:RegAttr('swallow')
    uicfg:RegAttr('noEventAfterMove')
    uicfg:RegAttr('move_dist')
    uicfg:RegAttr('tips')

    uicfg:InsertSetAttrOrder({'9sprite', 'capInsets', 'plist', 'frame1', 'frame2', 'frame3', 'enableText', 'text', 'fontSize', 'textColor1', 'textColor2', 'textColor3', 'textOffset', 'isEnabled', 'zoomScale', 'swallow', 'noEventAfterMove', 'move_dist', 'tips'}, 1)
    uicfg:RegSetAttr('9sprite', function(obj, parent, root, b9sprite, capInsets, plist, frame1, frame2, frame3, enableText, text, fontSize, textColor1, textColor2, textColor3, textOffset, isEnabled, zoomScale, swallow, noEventAfterMove, move_dist, tips)
    	obj:SetFrames(plist, {frame1, frame2, frame3}, b9sprite, capInsets)
        obj:SetEnableText(enableText)
        if enableText then
	        obj:SetText(text, fontSize, textColor1, textColor2, textColor3)
	        obj:SetTextOffset(textOffset)
	    end

	    obj:SetEnable(isEnabled)
    	obj:SetZoomScale(zoomScale)
        obj:setSwallowsTouches(swallow)
        obj:SetNoEventAfterMove(noEventAfterMove, move_dist)
        obj:_updateCurState()
        obj:_updateTipsContent(tips)
    end)
end)

g_uisystem.RegisterControl('CCButton', '_commonButton', function(uicfg)
    uicfg:RegCreate(
        function(parent, root)
            local obj = CCButton:Create()
            return obj
        end)
end)

g_uisystem.RegisterControl('CCCheckButton', '_commonButton', function(uicfg)
    uicfg:RegAttr('check')

    uicfg:RegCreate('check',
        function(parent, root, check)
            local obj = CCCheckButton:Create()
            obj:SetCheck(check)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCEditBoxExt', 'CCNode', function(uicfg)
    uicfg:RegAttr('text')
    uicfg:RegAttr('colText')
    uicfg:RegAttr('placeHolder')
    uicfg:RegAttr('colPlaceHolder')
    uicfg:RegAttr('fontSize')
    uicfg:RegAttr('nMaxLength')
    uicfg:RegAttr('inputMode')
    uicfg:RegAttr('inputFlag')
    uicfg:RegAttr('returnType')

    uicfg:RegCreate('text', 'colText', 'placeHolder', 'colPlaceHolder', 'nMaxLength', 'inputMode', 'inputFlag', 'returnType', 'fontSize',
        function(parent, root, text, colText, placeHolder, colPlaceHolder, nMaxLength, inputMode, inputFlag, returnType, fontSize)
            local obj = CCEditBoxExt:Create()
            obj:SetPlaceHolder(placeHolder)
            obj:setFontColor(ccc3FromHex(colText))
            obj:setPlaceholderFontColor(ccc3FromHex(colPlaceHolder))
            obj:setPlaceholderFontSize(fontSize)
            obj:setFontSize(fontSize)

            obj:setMaxLength(nMaxLength)
            obj:setReturnType(returnType)
            obj:setInputMode(inputMode)
            obj:setInputFlag(inputFlag)

            obj:SetText(text)

            return obj
        end)
end)

g_uisystem.RegisterControl('CCAnimateSprite', 'CCNode', function(uicfg)
    uicfg:RegAttr('plist')
    uicfg:RegAttr('frameDelay')
    uicfg:RegAttr('repeatCount')
    uicfg:RegAttr('isPlay')
    uicfg:RegAttr('blendFun')
    uicfg:RegAttr('action')

    uicfg:RegCreate('plist', 'frameDelay', 'repeatCount', 'isPlay', 'blendFun', 'action',
        function(parent, root, plist, frameDelay, repeatCount, isPlay, blendFun, action)
            local obj = CCAnimateSprite:Create()
            obj:SetFrameDelay(frameDelay)
            if is_valid_str(plist) then
                obj:SetAniSptDisplayFrameByPath(plist, nil, true)
            end
            obj:setBlendFunc(blendFun)

            if isPlay then
                obj:Play(repeatCount, true, action)
            end

            return obj
        end)
end)

g_uisystem.RegisterControl('CCProgressTimer', 'CCNode', function(uicfg)
    uicfg:RegAttr('displayFrame')
    uicfg:RegAttr('midPoint')
    uicfg:RegAttr('type')
    uicfg:RegAttr('percentage')
    uicfg:RegAttr('barChangeRate')
    uicfg:RegAttr('reverse')

    uicfg:RegCreate('displayFrame', 'midPoint', 'type', 'percentage', 'barChangeRate', 'reverse',
        function(parent, root, displayFrame, midPoint, type, percentage, barChangeRate, reverse)
            local obj = cc.ProgressTimer:Create(displayFrame.plist, displayFrame.path)
            obj:setType(type)
            obj:setBarChangeRate(barChangeRate)
            obj:setMidpoint(midPoint)
            obj:setReverseDirection(reverse)
            obj:setPercentage(percentage)

            return obj
        end)
end)

g_uisystem.RegisterControl('CCLoadingBar', 'CCNode', function(uicfg)
    uicfg:RegAttr('9sprite')
    uicfg:RegAttr('capInsets')
    uicfg:RegAttr('displayFrame')
    uicfg:RegAttr('direction')
    uicfg:RegAttr('percentage')

    uicfg:RegCreate('displayFrame', 'direction', 'percentage', '9sprite', 'capInsets',
        function(parent, root, displayFrame, direction,  percentage, b9sprite, capInsets)
            local obj = CCLoadingBar:Create()
            obj:loadTexture(displayFrame.path)
            obj:setScale9Enabled(b9sprite)
            obj:setCapInsets(capInsets)
            obj:setDirection(direction)
            obj:setPercent(percentage)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCSlider', 'CCNode', function(uicfg)
    uicfg:RegAttr('percentage')
    uicfg:RegAttr('path')

    uicfg:RegCreate('percentage', 'path',
        function(parent, root, percentage, path)
            if path == '' then
                return CCNode:Create()
            end
            local obj = CCSlider:Create(path)
            obj:setPercent(percentage)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCParticleSystemQuad', 'CCNode', function(uicfg)
    uicfg:RegAttr('particleFile')
    uicfg:RegAttr('posType')
    uicfg:RegAttr('stop')

    uicfg:RegCreate('particleFile', 'posType', 'stop',
        function(parent, root, particleFile, posType, stop)
            if particleFile == '' then
                return CCNode:Create()
            end
            local obj = cc.ParticleSystemQuad:Create(particleFile)
            obj:setPositionType(posType)
            if stop then
                obj:stopSystem()
            end

            return obj
        end)
end)

g_uisystem.RegisterControl('CCClippingNode', 'CCNode', function(uicfg)
    uicfg:RegAttr('displayFrame')
    uicfg:RegAttr('alphaThreshold')
    uicfg:RegAttr('inverted')

    uicfg:RegCreate('displayFrame', 'alphaThreshold', 'inverted', 
        function(parent, root, displayFrame, alphaThreshold, inverted)
            local obj = cc.ClippingNode:Create()
            local spt = CCSprite:Create(displayFrame.plist, displayFrame.path)
            obj:SetStencil(spt)
            obj:setAlphaThreshold(alphaThreshold)
            obj:setInverted(inverted)
            return obj
        end)
end)

g_uisystem.RegisterControl('ClippingRectangleNode', 'CCNode', function(uicfg)
    uicfg:RegCreate('size',
        function(parent, root, size)
            local obj = cc.ClippingRectangleNode:Create()
            local sz = obj:CalcSize(size.width, size.height)
            local clippingRegion = CCRect(0, 0, sz.width, sz.height)
            obj:setClippingRegion(clippingRegion)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCSizeSprite', 'CCNode', function(uicfg)
    uicfg:RegAttr('displayFrame')

    uicfg:RegCreate('displayFrame',
        function(parent, root, displayFrame)
            local obj = CCSprite:Create(displayFrame.plist, displayFrame.path)
            obj:setStretchEnabled(true)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCCombobox', 'CCNode', function(uicfg)
    uicfg:RegAttr('popup_item_width')
    uicfg:RegAttr('text')
    uicfg:RegAttr('combobox_template')
    uicfg:RegAttr('combobox_popup_layer_template')

    uicfg:RegCreate('popup_item_width', 'text','combobox_template', 'combobox_popup_layer_template',
        function(parent, root, popup_item_width, text, combobox_template, combobox_popup_layer_template)
            local obj = CCCombobox:Create(combobox_template, combobox_popup_layer_template)
            obj:SetPopupFrameWidth(popup_item_width)
            obj:SetString(text)
            return obj
        end)
end)

-- template
g_uisystem.RegisterControl('CCBFile', 'CCNode', function(uicfg)
    uicfg:RegAttr('ccbFile')
    uicfg:RegAttr('template_info')
    uicfg:RegAttr('async')

    uicfg:RegCreate('ccbFile', 'template_info',
        function(parent, root, ccbFile, template_info)
            return TemplateNode:Create()
        end)


    uicfg:InsertSetAttrOrder({'ccbFile', 'template_info', 'async'})
    uicfg:RegSetAttr('ccbFile', function(obj, parent, root, ccbFile, template_info)
        obj:SetTemplate(ccbFile, template_info)
        obj:DoLoad(async)
    end)
end)

g_uisystem.RegisterControl('CCScrollView', 'CCNode', function(uicfg)
    uicfg:RegAttr('container')
    uicfg:RegAttr('direction')
    uicfg:RegAttr('bounces')

    uicfg:RegCreate('container', 'direction', 'bounces',
        function(parent, root, container, direction, bounces)
            local obj = CCScrollView:Create()
            if container ~= '' then
                local container = g_uisystem.load_template_create(container)
                obj:SetContainer(container)
            end
            obj:setDirection(direction)
            obj:setBounceable(bounces)
            return obj
        end)
end)

g_uisystem.RegisterControl('_commonContainer', 'CCNode', function(uicfg)
    uicfg:RegAttr('numPerUnit')
    uicfg:RegAttr('horzBorder')
    uicfg:RegAttr('vertBorder')
    uicfg:RegAttr('horzIndent')
    uicfg:RegAttr('vertIndent')
    uicfg:RegAttr('template')
    uicfg:RegAttr('template_info')
    uicfg:RegAttr('initCount')
    uicfg:RegAttr('customize_info')
    uicfg:RegAttr('left2rightOrder')

    uicfg:InsertSetAttrOrder({'numPerUnit', 'horzBorder', 'vertBorder', 'horzIndent', 'vertIndent', 'template', 'template_info', 'initCount', 'customize_info', 'left2rightOrder'})
    uicfg:RegSetAttr('numPerUnit', function(obj, parent, root, numPerUnit, horzBorder, vertBorder, horzIndent, vertIndent, template, template_info, initCount, customize_info, left2rightOrder)
        obj:SetLeft2RightOrder(left2rightOrder)
        obj:SetNumPerUnit(numPerUnit)
        obj:SetHorzBorder(horzBorder)
        obj:SetVertBorder(vertBorder)
        obj:SetHorzIndent(horzIndent)
        obj:SetVertIndent(vertIndent)
        obj:SetTemplate(template, template_info, customize_info)
        obj:SetInitCount(initCount)
    end)
end)

g_uisystem.RegisterControl('CCHorzContainer', '_commonContainer', function(uicfg)
    uicfg:RegCreate(
        function(parent, root)
            local obj = CCContainer:Create()
            obj:SetHorzDirection(true)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCVerContainer', '_commonContainer', function(uicfg)
    uicfg:RegCreate(
        function(parent, root)
            local obj = CCContainer:Create()
            obj:SetHorzDirection(false)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCAsyncHorzContainer', '_commonContainer', function(uicfg)
    uicfg:RegCreate(
        function(parent, root)
            local obj = AsyncContainer:Create()
            obj:SetHorzDirection(true)
            obj:AsyncLoad()
            return obj
        end)
end)

g_uisystem.RegisterControl('CCAsyncVerContainer', '_commonContainer', function(uicfg)
    uicfg:RegCreate(
        function(parent, root)
            local obj = AsyncContainer:Create()
            obj:SetHorzDirection(false)
            obj:AsyncLoad()
            return obj
        end)
end)

g_uisystem.RegisterControl('_commonTemplateList', '_commonContainer', function(uicfg)
    uicfg:RegAttr('bounces')
    uicfg:RegAttr('notAutoHideLen')
end)

g_uisystem.RegisterControl('CCHorzTemplateList', '_commonTemplateList', function(uicfg)
    uicfg:RegCreate('bounces', 'notAutoHideLen',
        function(parent, root, bounces, notAutoHideLen)
            local obj = SCrollList:Create()
            obj:SetHorzDirection(true)
            obj:setBounceable(bounces)
            obj:SetNotAutoHideLen(notAutoHideLen)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCVerTemplateList', '_commonTemplateList', function(uicfg)
    uicfg:RegCreate('bounces', 'notAutoHideLen',
        function(parent, root, bounces, notAutoHideLen)
            local obj = SCrollList:Create()
            obj:SetHorzDirection(false)
            obj:setBounceable(bounces)
            obj:SetNotAutoHideLen(notAutoHideLen)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCHorzScrollPage', '_commonTemplateList', function(uicfg)
    uicfg:RegCreate('bounces', 'notAutoHideLen',
        function(parent, root, bounces, notAutoHideLen)
            local obj = SCrollPage:Create()
            obj:SetHorzDirection(true)
            obj:setBounceable(bounces)
            obj:SetNotAutoHideLen(notAutoHideLen)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCHorzAsyncList', '_commonTemplateList', function(uicfg)
    uicfg:RegAttr('singleItemReverseLoadOrder')

    uicfg:RegCreate('bounces', 'singleItemReverseLoadOrder', 'notAutoHideLen',
        function(parent, root, bounces, singleItemReverseLoadOrder, notAutoHideLen)
            local obj = AsyncList:Create()
            obj:SetHorzDirection(true)
            obj:setBounceable(bounces)
            obj:SetReverseLoadOrder(singleItemReverseLoadOrder)
            obj:SetNotAutoHideLen(notAutoHideLen)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCVerAsyncList', '_commonTemplateList', function(uicfg)
    uicfg:RegAttr('singleItemReverseLoadOrder')

    uicfg:RegCreate('bounces', 'singleItemReverseLoadOrder', 'notAutoHideLen',
        function(parent, root, bounces, singleItemReverseLoadOrder, notAutoHideLen)
            local obj = AsyncList:Create()
            obj:SetHorzDirection(false)
            obj:setBounceable(bounces)
            obj:SetReverseLoadOrder(singleItemReverseLoadOrder)
            obj:SetNotAutoHideLen(notAutoHideLen)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCTreeView', 'CCNode', function(uicfg)
    uicfg:RegAttr('template')

    uicfg:RegCreate('template', 
        function(parent, root, template)
            local obj = CCTreeView:Create()
            obj:SetElemTemplateName(template)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCSkeletonAnimation', 'CCNode', function(uicfg)
    uicfg:RegAttr('animation_data')
    uicfg:RegAttr('isPlay')
    uicfg:RegAttr('isLoop')

    uicfg:RegCreate('animation_data', 'isPlay', 'isLoop',
        function(parent, root, animation_data, isPlay, isLoop)
            if sp and sp.SkeletonAnimation then
                return sp.SkeletonAnimation:Create(animation_data.jsonPath, animation_data.action, isPlay, isLoop)
            end
            return CCNode:Create()
        end)
end)

g_uisystem.RegisterControl('CCMotionMask', 'CCNode', function(uicfg)
    uicfg:RegAttr('path')
    uicfg:RegAttr('fade')
    uicfg:RegAttr('minSeg')
    uicfg:RegAttr('stroke')
    uicfg:RegAttr('color')

    uicfg:RegCreate('path', 'fade', 'minSeg', 'stroke', 'color',
        function(parent, root, path, fade, minSeg, stroke, color)
            local node = cc.MotionStreak:create(fade, minSeg, stroke, ccc4aFromHex(color), path)
            return node
        end)
end)

g_uisystem.RegisterControl('Live2DSprite', 'CCNode', function(uicfg)
    uicfg:RegAttr('live2d_data')
    uicfg:RegAttr('is_play')
    uicfg:RegAttr('is_loop')
    uicfg:RegAttr('is_asyn')

    uicfg:RegCreate('live2d_data', 'is_play', 'is_loop', 'is_asyn',
        function(parent, root, live2d_data, is_play, is_loop, is_asyn)
            if cc.Live2DSprite and jsonPath ~= '' then
                local jsonPath = live2d_data.jsonPath
                local motion = live2d_data.motion

                local obj = cc.Live2DSprite:Create(jsonPath, is_asyn)
                if not obj then
                    return cc.Node:Create()
                end
                if is_play then
                    obj:PlayMotion(motion, is_loop)
                end
                return obj 
            else
                return cc.Node:Create()
            end
        end)
end)

g_uisystem.RegisterControl('Node3D', 'CCNode', function(uicfg)
    uicfg:RegAttr('pos_z')
    uicfg:RegAttr('scale_z')
    uicfg:RegAttr('globalZorder')
    uicfg:RegAttr('cameraMask')

    uicfg:InsertSetAttrOrder({'pos_z', 'scale_z', 'globalZorder', 'cameraMask'})
    uicfg:RegSetAttr('pos_z', function(obj, parent, root, pos_z, scale_z, globalZorder, cameraMask)
        obj:setPositionZ(pos_z)
        obj:setScaleZ(scale_z)
        obj:setGlobalZOrder(globalZorder)
        obj:setCameraMask(cameraMask)
    end)
end)

g_uisystem.RegisterControl('PerspectiveCamera', 'Node3D', function(uicfg)
    uicfg:RegAttr('fieldOfView')
    uicfg:RegAttr('aspectRatio')
    uicfg:RegAttr('nearPlane')
    uicfg:RegAttr('farPlane')
    uicfg:RegAttr('target')
    uicfg:RegAttr('up')
    uicfg:RegAttr('cameraFlag')
    uicfg:RegAttr('cameraDepth')

    uicfg:RegCreate('fieldOfView', 'aspectRatio', 'nearPlane', 'farPlane', 'target', 'up', 'cameraFlag', 'cameraDepth',
        function(parent, root, fieldOfView, aspectRatio, nearPlane, farPlane, target, up, cameraFlag, cameraDepth)
            local obj = CCCamera:createPerspective(fieldOfView, aspectRatio, nearPlane, farPlane)
            obj:setCameraFlag(cameraFlag)
            obj:lookAt(target, up)
            obj:setDepth(cameraDepth)
            return obj
        end)
end)

g_uisystem.RegisterControl('Sprite3D', 'Node3D', function(uicfg)
    uicfg:RegAttr('modelPath')

    uicfg:RegCreate('modelPath',
        function(parent, root, modelPath)
            local obj = CCSprite3D:create(modelPath)
            return obj
        end)
end)

g_uisystem.RegisterControl('CCPUParticleSystem3D', 'Node3D', function(uicfg)
    uicfg:RegAttr('pu_path')
    uicfg:RegAttr('material_path')

    uicfg:RegCreate('pu_path', 'material_path',
        function(parent, root, pu_path, material_path)
            if pu_path ~= '' and material_path ~= '' then
                local particle3D = cc.PUParticleSystem3D:create(pu_path, material_path)
                delay_call(0, function()
                    print('start ~~~')
                    particle3D:startParticleSystem()
                end)
                
                return particle3D
            else
                return CCNode:create()
            end
        end)
end)

local _ctrlCfg = g_uisystem.get_control_config()
_ctrlCfg['Label'] = _ctrlCfg['RichLabel']
_ctrlCfg['CCLabel'] = _ctrlCfg['RichLabel']
_ctrlCfg['SysLabel'] = _ctrlCfg['RichLabel']
