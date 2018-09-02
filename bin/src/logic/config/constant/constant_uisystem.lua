
-- 资源目录下template 配置存放的路径
template_path = 'gui/template/'
ani_template_path = 'gui/ani_template/'

-- 设计分辨率
design_resolution_size = {
    width = 1280,
    height = 720,
}

-- rich label 所使用的最大字体
rich_label_font_size = math.min(g_director:getWinSize().width / design_resolution_size.width * 40, 50)

-- 字体
RichLabelFontType = {
    CHINESE = {
        tp = 0,
        font = 'gui/default/default_font_cn.ttf'
    },
    ARABIC = {
        tp = 1,
        font = 'gui/default/default_font_arabic.ttf'
    },
    RUSSIAN = {
        tp = 2,
        font = 'gui/default/default_font_russian.ttf'
    },
}

-- 语言配置以后在这添加配置
all_lang = {
    cn = {
        font = 'CHINESE',
        ascii = 'CHINESE',
    },
    wy = {
        font = 'ARABIC',
        ascii = 'ARABIC',
    },
    hy = {
        font = 'ARABIC',
        ascii = 'ARABIC',
    },
    kz = {
        font = 'RUSSIAN',
        ascii = 'RUSSIAN',
    },
    ru = {
        font = 'RUSSIAN',
        ascii = 'RUSSIAN',
    },
    irn = {
        font = 'ARABIC',
        ascii = 'ARABIC',
    },
}

-- 默认的语言版本
default_lang = 'cn'

-- 阅读顺序从左到右的语言
left2right_lang = table.to_value_set({'cn', 'kz', 'ru'})

local curLang = g_native_conf['cur_multilang_index']
default_font_ascii_type = RichLabelFontType[all_lang[curLang]['ascii']].tp
default_font_name = RichLabelFontType[all_lang[curLang]['font']].font

-- validate lang
xpcall(function()
    -- all_lang
    for _, info in pairs(all_lang) do
        assert(RichLabelFontType[info.font] ~= nil)
        assert(RichLabelFontType[info.ascii] ~= nil)
    end

    -- curLang
    assert(all_lang[curLang])

    -- default_lang
    assert(all_lang[default_lang] ~= nil)

    -- left2right_lang
    for l, _ in pairs(left2right_lang) do
        assert(all_lang[l] ~= nil)
    end

    -- default_font_name
    assert(g_fileUtils:isFileExist(default_font_name), default_font_name)

    -- default_font_ascii_name
    local default_font_ascii_name = RichLabelFontType[all_lang[curLang]['ascii']].font
    assert(g_fileUtils:isFileExist(default_font_ascii_name), default_font_ascii_name)
end, __G__TRACKBACK__)



--------------------------------------------------
local gl = {
    ONE = 1,
    ONE_MINUS_SRC_ALPHA = 0x0303,
}

MouseButton = {
  BUTTON_UNSET   = -1,
  BUTTON_LEFT    =  0,
  BUTTON_RIGHT   =  1,
  BUTTON_MIDDLE  =  2,
  BUTTON_4       =  3,
  BUTTON_5       =  4,
  BUTTON_6       =  5,
  BUTTON_7       =  6,
  BUTTON_8       =  7
}

BUTTON_STATE = {
    STATE_NORMAL = 1,
    STATE_SELECTED = 2,
    STATE_DISABLED = 3,
}

BUTTON_STATE_NODE_NAME = {
    [BUTTON_STATE.STATE_NORMAL] = '__state_normal__',
    [BUTTON_STATE.STATE_SELECTED] = '__state_selected__',
    [BUTTON_STATE.STATE_DISABLED] = '__state_disabled__',
}

LOADING_BAR_DIRECTION = {
    LEFT = 0,
    RIGHT = 1
}


LIVE_2D_PARTS = {
    PARAM_ANGLE_X = 'PARAM_ANGLE_X',
    PARAM_ANGLE_Y = 'PARAM_ANGLE_Y',
    PARAM_BODY_X = 'PARAM_BODY_X',
    PARAM_EYE_BALL_X = 'PARAM_EYE_BALL_X',
    PARAM_EYE_BALL_Y = 'PARAM_EYE_BALL_Y',
}

-- 透明图片路径 SetPath 为空的时候也会设置这个图
default_transparent_img_path = 'gui/default/empty.png'

-- 设置看不见的图片默认使用的路径
default_missing_img_path = 'gui/default/missing.png'

-- 没有设置图片路径默认用这个图片路径填充
default_img_path = 'gui/default/default_img.png'

default_check_on_img_path = 'gui/default/check_on.png'
default_check_off_img_path = 'gui/default/check_off.png'

default_sprite_frame = {
    plist = '',
    path = default_img_path,
}

EMOJ_FORMAT_PATH = 'gui/badam_ui/common_emoj/%s.png' --emoj路径

-- default template
default_template_path = 'default/ccbfile_default'

-- default ani template
default_ani_template_name = 'default/default_ani'

default_empty_template_conf = {['type_name'] = 'CCNode'}

default_empty_ani_template_conf = {['type_name'] = 'DelayTime', ['t'] = 0}




-- 默认 scrollview 鼠标滑动的倍率
default_mouse_scroll_rate = 70

-- treeview parms
default_treeview_horz_indent = 20
default_treeview_vert_indent = 0
default_treeview_min_drag_len = ccext_get_scale('10w')







local winSize = g_director:getWinSize()


default_control_value = {
    ['CCNode'] = {
        ['name'] = '',
        ['lock'] = false,
        ['assign_root'] = true,
        ['pos'] = {x = 0, y = 0},
        ['size'] = {width = '100%', height = '100%'},
        ['anchor'] = {x = 0.5, y = 0.5},
        ['scale'] = {x = 1, y = 1},
        ['rotation'] = 0,
        ['skew'] = {x = 0, y = 0},
        ['hide'] = false,
        ['zorder'] = 0,
        ['ani_data'] = {},
        ['child_list'] = {},
    },
    ['CCLayer'] = {
        ['touchEnabled'] = false,
        ['swallow'] = true,
        ['noEventAfterMove'] = false,
        ['move_dist'] = '10w',
        ['forceHandleTouch'] = false,
    },
    ['CCLayerColor'] = {
        ['color'] = 0xff0000,
        ['opacity'] = 255,
    },
    ['CCLayerGradient'] = {
        ['startColor'] = 0xff0000,
        ['endColor'] = 0x00ff00,
        ['startOpacity'] = 255,
        ['endOpacity'] = 255,
        ['vector'] = {x = 1, y = 0},
    },
    ['CCSprite'] = {
        ['displayFrame'] = default_sprite_frame,
        ['color'] = 0xffffff,
        ['opacity'] = 255,
        ['blendFun'] = cc.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA),
    },
    ['CCScale9Sprite'] = {
        ['spriteFrame'] = default_sprite_frame,
        ['capInsets'] = {x=0, y=0, width=0, height=0},
        ['color'] = 0xffffff,
        ['opacity'] = 255,
        ['blendFun'] = cc.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA),
    },
    ['RichLabel'] = {
        ['font_size'] = 24,
        ['max_width'] = 0,
        ['h_align'] = cc.TEXT_ALIGNMENT_LEFT,
        ['text'] = '',
        ['color'] = 0xffffff,
        ['spacing'] = 0,
    },
    ['_commonCCLabel'] = {
        ['fontSize'] = 24,
        ['dimensions'] = CCSize(0, 0),
        ['hAlign'] = cc.TEXT_ALIGNMENT_LEFT,
        ['vAlign'] = cc.VERTICAL_TEXT_ALIGNMENT_TOP,
        ['text'] = '',
        ['color'] = 0xffffff,
        ['opacity'] = 255,
        ['spacing'] = 0,

        ['bEnableOutline'] = false,
        ['shadowColor'] = 0x000000,
        ['shadowWidth'] = 2,

        ['bEnableShadow'] = false,
        ['shadowColor1'] = 0x000000,
        ['shadowOffset'] = CCSize(2, -2),
    },
    ['TTFLabel'] = {
        ['fontName'] = default_font_name,
        ['bEnableGlow'] = false,
        ['glowColor'] = 0x000000,
    },
    ['SystemLabel'] = {
    },
    ['CCLabelAtlas'] = {
        ['fntFile'] = '',
        ['text'] = '',
        ['color'] = 0xffffff,
        ['opacity'] = 255,
    },
    ['CCLabelBMFont'] = {
        ['fntFile'] = '',
        ['hAlignment'] = cc.TEXT_ALIGNMENT_LEFT,
        ['maxLineWidth'] = 0,
        ['imageOffset'] = {x = 0, y = 0},
    },
    ['CCRectBorder'] = {
        ['line_weight'] = 2,
        ['line_color'] = 0xff0000,
    },
    ['CCWebView'] = {
        ['url'] = '',
        ['scale_page'] = false,
    },
    ['_commonButton'] = {
        ['9sprite'] = true,
        ['capInsets'] = {x=0, y=0, width=0, height=0},
        ['plist'] = '',
        ['frame1'] = '',
        ['frame2'] = '',
        ['frame3'] = '',
        ['enableText'] = true,
        ['text'] = '',
        ['fontSize'] = 24,
        ['textColor1'] = 0xffffff,
        ['textColor2'] = 0xffffff,
        ['textColor3'] = 0xffffff,
        ['textOffset'] = {x='50%', y='50%'},
        ['isEnabled'] = true,
        ['zoomScale'] = 0.85,
        ['swallow'] = true,
        ['noEventAfterMove'] = false,
        ['move_dist'] = '10w',
    },
    ['CCButton'] = {
        ['plist'] = '',
        ['frame1'] = default_img_path,
        ['frame2'] = '',
        ['frame3'] = '',
    },
    ['CCCheckButton'] = {
        ['9sprite'] = false,
        ['check'] = false,
        ['plist'] = '',
        ['frame1'] = default_check_off_img_path,
        ['frame2'] = default_check_on_img_path,
        ['frame3'] = '',
    },
    ['CCEditBoxExt'] = {
        ['text'] = '',
        ['colText'] = 0xffffff,
        ['placeHolder'] = '',
        ['colPlaceHolder'] = 0xfeffff,
        ['fontSize'] = 24,
        ['nMaxLength'] = 500,
        ['inputMode'] = cc.EDITBOX_INPUT_MODE_SINGLELINE,
        ['inputFlag'] = cc.EDITBOX_INPUT_FLAG_SENSITIVE,
        ['returnType'] = cc.KEYBOARD_RETURNTYPE_DEFAULT,
    },
    ['CCAnimateSprite'] = {
        ['plist'] = '',
        ['frameDelay'] = 0.1,
        ['repeatCount'] = -1,
        ['isPlay'] = true,
        ['blendFun'] = cc.blendFunc(gl.ONE, gl.ONE_MINUS_SRC_ALPHA),
    },
    ['CCProgressTimer'] = {
        ['displayFrame'] = default_sprite_frame,
        ['midPoint'] = {x = 0.00, y = 0.50},
        ['type'] = cc.PROGRESS_TIMER_TYPE_BAR,
        ['percentage'] = 100,
        ['barChangeRate'] = {x = 1.00, y = 0.00},
        ['reverse'] = false,
    },
    ['CCLoadingBar'] = {
        ['9sprite'] = true,
        ['capInsets'] = {x=0, y=0, width=0, height=0},
        ['displayFrame'] = default_sprite_frame,
        ['direction'] = ccui.LoadingBarDirection.LEFT,
        ['percentage'] = 100,
    },
    ['CCSlider'] = {
        ['percentage'] = 0,
        ['path'] = '',
    },
    ['CCParticleSystemQuad'] = {
        ['particleFile'] = '',
        ['posType'] = cc.POSITION_TYPE_FREE,
        ['stop'] = false,
    },
    ['CCClippingNode'] = {
        ['displayFrame'] = default_sprite_frame,
        ['alphaThreshold'] = 0.9,
        ['inverted'] = false,
    },
    ['ClippingRectangleNode'] = {
    },
    ['CCSizeSprite'] = {
        ['displayFrame'] = default_sprite_frame,
    },
    ['CCCombobox'] = {
        ['popup_item_width'] = 250,
        ['text'] = 'combobox',
    },
    ['CCBFile'] = {
        ['ccbFile'] = default_template_path,
        ['template_info'] = {},
        ['async'] = false,
    },
    ['CCScrollView'] = {
        ['container'] = default_template_path,
        ['direction'] = cc.SCROLLVIEW_DIRECTION_BOTH,
        ['bounces'] = true,
    },
    ['_commonContainer'] = {
        ['numPerUnit'] = 1,
        ['horzBorder'] = 0,
        ['vertBorder'] = 0,
        ['horzIndent'] = 0,
        ['vertIndent'] = 0,
        ['template'] = default_template_path,
        ['template_info'] = {},
        ['initCount'] = 0,
        ['customize_info'] = {},
    },
    ['_commonTemplateList'] = {
        ['bounces'] = true,
    },
    ['CCTreeView'] = {
        ['template'] = 'default/tree_view_item',
    },
    ['CCSkeletonAnimation'] = {
        ['animation_data'] = {jsonPath = '', action = ''},
        ['isPlay'] = false,
        ['isLoop'] = false,
    },
    ['CCPUParticleSystem3D'] = {
        ['pu_path'] = '',
        ['material_path'] = '',
    },
    ['CCMotionMask'] = {
        ['path'] = default_img_path,
        ['fade'] = 2,
        ['minSeg'] = -1,
        ['stroke'] = 10,
        ['color'] = 0x808080
    },
    ['Live2DSprite'] = {
        ['live2d_data'] = {jsonPath = '', motion = ''},
        ['is_play'] = true,
        ['is_loop'] = true,
        ['is_asyn'] = true
    },
    ['PerspectiveCamera'] = {
        ['fieldOfView'] = 60,
        ['aspectRatio'] = winSize.width / winSize.height,
        ['nearPlane'] = 1,
        ['farPlane'] = 1000,
        ['cameraFlag'] = cc.CameraFlag.USER1,
    },
    ['Sprite3D'] = {
        ['modelPath'] = 'gui/default/test/Sprite3DTest/girl.c3b',
        ['forceDepthWrite'] = false,
        ['force2dQueue'] = true,
    },
}

local function _check_file_path(path)
    if not g_fileUtils:isFileExist(path) then
        error_msg('file path [%s] not exists!', path)
    end
end

local function _check_template_path(templatePath)
    _check_file_path(string.format('%s%s.json', template_path, templatePath))
end

local function _check_ani_template_path(templatePath)
    _check_file_path(string.format('%s%s.json', ani_template_path, templatePath))
end


-- validate res
xpcall(function()
    _check_file_path(default_transparent_img_path)
    _check_file_path(default_missing_img_path)
    _check_file_path(default_img_path)
    _check_file_path(default_check_on_img_path)
    _check_file_path(default_check_off_img_path)

    _check_template_path(default_template_path)

    _check_ani_template_path(default_ani_template_name)
end, __G__TRACKBACK__)



