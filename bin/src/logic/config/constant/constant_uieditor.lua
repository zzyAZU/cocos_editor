controls = {
    {
        text_name = "基础节点",
        list = {
            {
                text_name = "节点",
                name = "CCNode",
            },
            {
                text_name = "透明层",
                name = "CCLayer",
            },
            {
                text_name = "普通按钮",
                name = "CCButton",
                defConf = {
                    size = CCSize(100, 50),
                }
            },
            {
                text_name = "复选按钮",
                name = "CCCheckButton",
            },
        },
    },
    {
        text_name = "显示",
        list = {
            {
                text_name = "精灵",
                name = "CCSprite",
            },
            {
                text_name = "九宫格",
                name = "CCScale9Sprite",
            },
            {
                text_name = "循环纹理",
                name = "RepeatSprite",
            },
            {
                text_name = "缩放精灵",
                name = "CCSizeSprite",
            },
            {
                text_name = "彩色层",
                name = "CCLayerColor",
            },
            {
                text_name = "渐变层",
                name = "CCLayerGradient",
            },
            {
                text_name = "圆形渐变层",
                name = "LayerRadialGradient",
            },
            {
                text_name = "动画",
                name = "CCAnimateSprite",
            },
            {
                text_name = "粒子",
                name = "CCParticleSystemQuad",
            },
            {
                text_name = "spine动画",
                name = "CCSkeletonAnimation",
            },
            {
                text_name = "Live2DSprite",
                name = "Live2DSprite",
            },
            {
                text_name = "残影",
                name = "CCMotionMask",
            },
        },
    },
    {
        text_name = "文本",
        list = {
            {
                text_name = "富文本",
                name = "RichLabel",
                defConf = {
                    text = 'RichLabel'
                }
            },
            {
                text_name = "文本框",
                name = "TTFLabel",
                defConf = {
                    text = 'TTFLabel'
                }
            },
            {
                text_name = "系统文本",
                name = "SystemLabel",
                defConf = {
                    text = 'SystemLabel'
                }
            },
            {
                text_name = "图片文本框",
                name = "CCLabelAtlas",
                defConf = {
                    text = '0123'
                }
            },
            {
                text_name = "BMFont艺术文本框",
                name = "CCLabelBMFont",
                defConf = {
                    text = ''
                }
            },
            {
                text_name = "编辑框",
                name = "CCEditBoxExt",
            },
        },
    },
    {
        text_name = "3D",
        list = {
            {
                text_name = "PerspectiveCamera",
                name = "PerspectiveCamera",
            },
            {
                text_name = "Sprite3D",
                name = "Sprite3D",
            },
            {
                text_name = "PU粒子3d动画",
                name = "CCPUParticleSystem3D",
            },
        },
    },
    {
        text_name = "容器",
        list = {
            {
                text_name = "CCBFile",
                name = "CCBFile",
            },
            {
                text_name = "ScrollView",
                name = "CCScrollView",
            },
            {
                text_name = "水平容器",
                name = "CCHorzContainer",
                defConf = {
                    initCount = 1,
                }
            },
            {
                text_name = "垂直容器",
                name = "CCVerContainer",
                defConf = {
                    initCount = 1,
                }
            },
            {
                text_name = "水平滚动容器",
                name = "CCHorzTemplateList",
                defConf = {
                    initCount = 1,
                }
            },
            {
                text_name = "垂直滚动容器",
                name = "CCVerTemplateList",
                defConf = {
                    initCount = 1,
                }
            },
            {
                text_name = "水平滚动页",
                name = "CCHorzScrollPage",
                defConf = {
                    initCount = 1,
                }
            },
            {
                text_name = "水平异步容器",
                name = "CCAsyncHorzContainer",
                defConf = {
                    initCount = 1,
                }
            },
            {
                text_name = "垂直异步容器",
                name = "CCAsyncVerContainer",
                defConf = {
                    initCount = 1,
                }
            },
            {
                text_name = "水平异步滚动容器",
                name = "CCHorzAsyncList",
                defConf = {
                    initCount = 1,
                }
            },
            {
                text_name = "垂直异步滚动容器",
                name = "CCVerAsyncList",
                defConf = {
                    initCount = 1,
                }
            },
        },
    },
    {
        text_name = "功能",
        list = {
            {
                text_name = "ProgressTimer",
                name = "CCProgressTimer",
            },
            {
                text_name = "LoadingBar",
                name = "CCLoadingBar",
            },
            {
                text_name = "Slider",
                name = "CCSlider",
            },
            {
                text_name = "矩形线框",
                name = "CCRectBorder",
            },
            {
                text_name = "CCClippingNode",
                name = "CCClippingNode",
            },
            {
                text_name = "Clipping矩形节点",
                name = "ClippingRectangleNode",
            },
            {
                text_name = "CCWebView",
                name = "CCWebView",
            },
        },
    },
    {
        text_name = "TOOLS",
        list = {
            {
                text_name = "CCCombobox",
                name = "CCCombobox",
            },
            {
                text_name = "CCTreeView",
                name = "CCTreeView",
            },
        },
    },
}

pos_quick_setting = {
    text_name = '位置转换',
    list = {
        {
            text_name = 'x值转换               0',
            att_type = 1,
            op_type = 1,
        },
        {
            text_name = 'x百分比转换           0%',
            att_type = 1,
            op_type = 2,
        },
        {
            text_name = 'x倒数转换             i0',
            att_type = 1,
            op_type = 3,
        },
        {
            text_name = 'y值转换               0',
            att_type = 2,
            op_type = 1,
        },
        {
            text_name = 'y百分比转换           0%',
            att_type = 2,
            op_type = 2,
        },
        {
            text_name = 'y倒数转换             i0',
            att_type = 2,
            op_type = 3,
        },
    }
}

size_quick_setting = {
    text_name = '大小转换',
    list = {
        {
            text_name = 'width值转换             0',
            att_type = 1,
            op_type = 1,
        },
        {
            text_name = 'width百分比转换         0%',
            att_type = 1,
            op_type = 2,
        },
        {
            text_name = 'width倒数转换           i0',
            att_type = 1,
            op_type = 3,
        },
        {
            text_name = 'height值转换            0',
            att_type = 2,
            op_type = 1,
        },
        {
            text_name = 'height百分比转换        0%',
            att_type = 2,
            op_type = 2,
        },
        {
            text_name = 'height倒数转换          i0',
            att_type = 2,
            op_type = 3,
        },
    }
}

-- 显示历史打开模板的数量最大数
max_recent_open_files = 20

-- 动态模板属性不可设置的属性名称
dynamic_template_ignor_attrs = table.to_value_set({
    'name',
    'lock',
    'assign_root',
    'ani_data',
    'child_list',
    'template_info',
    'customize_info',
})

ALIGN_TYPE = table.reverse_key_value({
    'TOP',
    'HCENTER',
    'BOTTOM',
    'LEFT',
    'VCENTER',
    'RIGHT',
    'H_EQUIDISTANCE',
    'V_EQUIDISTANCE',
    'H_ADD_SPACE',
    'H_SUB_SPACE',
    'V_ADD_SPACE',
    'V_SUB_SPACE',
    'SAME_WIDTH',
    'SAME_HEIGHT',
    'SAME_SIZE',
})


-- 设置对齐间距的按键距离控制
align_ctrl_move_len = 5
align_alt_move_len = 20
align_shift_move_len = 50


-- 方向键移动的按键距离控制
arrow_move_len = 1
arrow_ctrl_move_len = 5
arrow_alt_move_len = 25
arrow_shift_move_len = 50



-- 空间编辑相关配置
--refresh policy

--只同步基础属性 pos anchor ignorAnchor scale rotation hide size && update uicontrol item
local function editcallback_refresh(controlItem, value)
    controlItem:RefreshItemControl(false, false)
end

local function editcallback_refresh_load(controlItem, value)
    controlItem:RefreshItemControl(false, true)
end

local function editcallback_refresh_size(controlItem, value)
    controlItem:RefreshItemControl(true, false)
end

local function editcallback_refresh_all(controlItem, value)
    controlItem:RefreshItemControl(true, true)
end

-- 一些设置属改变性会影响其他属性
local function editcallback_refresh_all_and_conf_and_reload_edit(controlItem, value)
    controlItem:RefreshItemControl(true, true)
    controlItem:RefreshItemConfig(false, false)
    controlItem._panel:RefreshSelItemPropertyConf()
    return true
end

local type_name_info = {}
for _, info in ipairs(controls) do
    local sub_group = {}
    for _, info1 in ipairs(info.list) do
        table.insert(sub_group, {info1.name, info1.name})
    end
    table.insert(type_name_info, {sub_group=sub_group, sub_group_name=info.text_name})
end

local var_assign_info = {
    {'root', true},
    {'parent', false},
}

local blend_info = {
    {'ZERO', gl.ZERO,},
    {'ONE', gl.ONE,},
    {'SRC_ALPHA', gl.SRC_ALPHA,},
    {'ONE_MINUS_SRC_ALPHA', gl.ONE_MINUS_SRC_ALPHA,},
    {'DST_ALPHA', gl.DST_ALPHA,},
    {'ONE_MINUS_DST_ALPHA', gl.ONE_MINUS_DST_ALPHA,},
    {'SRC_COLOR', gl.SRC_COLOR,},
    {'ONE_MINUS_SRC_COLOR', gl.ONE_MINUS_SRC_COLOR,},
    {'DST_COLOR', gl.DST_COLOR,},   
    {'ONE_MINUS_DST_COLOR', gl.ONE_MINUS_DST_COLOR,},
    {'SRC_ALPHA_SATURATE', gl.SRC_ALPHA_SATURATE,},
}

local h_align_info = {
    {'left', cc.TEXT_ALIGNMENT_LEFT},
    {'center', cc.TEXT_ALIGNMENT_CENTER},
    {'right', cc.TEXT_ALIGNMENT_RIGHT},
}

local v_align_info = {
    {'top', cc.VERTICAL_TEXT_ALIGNMENT_TOP},
    {'center', cc.VERTICAL_TEXT_ALIGNMENT_CENTER},
    {'bottom', cc.VERTICAL_TEXT_ALIGNMENT_BOTTOM},
}

local progress_bar_type_info = {
    {'TYPE_BAR', cc.PROGRESS_TIMER_TYPE_BAR},
    {'TYPE_RADIAL', cc.PROGRESS_TIMER_TYPE_RADIAL},
}

local scroll_direction_info = {
    {'NONE', cc.SCROLLVIEW_DIRECTION_NONE},
    {'HORZ', cc.SCROLLVIEW_DIRECTION_HORIZONTAL},
    {'VERT', cc.SCROLLVIEW_DIRECTION_VERTICAL},
    {'BOTH', cc.SCROLLVIEW_DIRECTION_BOTH},
}

local container_dir_info = {
    {'horizontal', true},
    {'vertical', false},
}

local loading_bar_direction_info = {
    {'LEFT', ccui.LoadingBarDirection.LEFT},
    {'RIGHT', ccui.LoadingBarDirection.RIGHT},
}

local address_mode_info = {
    {'ADDRESS_WRAP', 1},
    {'ADDRESS_MIRROR', 2},
    {'ADDRESS_CLAMP', 3},
    {'ADDRESS_BORDER', 4},
}

local particle_pos_type_info = {
    {'POSITION_TYPE_FREE', cc.POSITION_TYPE_FREE},
    {'POSITION_TYPE_GROUPED', cc.POSITION_TYPE_GROUPED},
    {'POSITION_TYPE_RELATIVE', cc.POSITION_TYPE_RELATIVE},
}

local camera_flag_info = {
    {'DEFAULT', cc.CameraFlag.DEFAULT},
    {'USER1', cc.CameraFlag.USER1},
    {'USER2', cc.CameraFlag.USER2},
    {'USER3', cc.CameraFlag.USER3},
    {'USER4', cc.CameraFlag.USER4},
    {'USER5', cc.CameraFlag.USER5},
    {'USER6', cc.CameraFlag.USER6},
    {'USER7', cc.CameraFlag.USER7},
    {'USER8', cc.CameraFlag.USER8},
}

local repeat_sprite_addres_info = {
    {'GL_REPEAT', 0x2901},
    {'GL_MIRRORED_REPEAT', 0x8370},
}

editor_template_code = [[
-- dialog code generated at %s

Panel = g_panel_mgr.new_panel_class('__TEMPLATE__')

-- override
function Panel:init_panel(...)

end
]]


-- 不能够设置大小的类型节点在这里声明
control_size_can_not_change = table.to_value_set({
    'CCSprite', 
    'RichLabel',
    'TTFLabel',
    'SystemLabel',
    'CCLabelAtlas',
    'CCAnimateSprite',
    'CCProgressTimer',
    'CCParticleSystemQuad',
    'CCHorzContainer',
    'CCVerContainer',
    'CCAsyncHorzContainer',
    'CCAsyncVerContainer',
})


-- 编辑属性可以覆盖基类的
control_edit_info = {
    ['CCNode'] = {
        {
            attr = 'type_name',
            tp = 'edit_type_combo',
            parm = {
                name = '类型',
                list = type_name_info,
            },
            refresPolicy = function(controlItem)
                -- 这样会重新merge 配置 祛除无用字段 以及新增没有的字段
                controlItem:GetCfg().__checked__ = nil
                controlItem:RefreshItemControl(true, true)
                controlItem._panel:RefreshSelItemPropertyConf()
            end,
        },
        {
            attr = 'name',
            tp = 'edit_type_string',
            parm = {
                name = '名称',
                re_pattern = '|[_a-zA-Z ]+[a-zA-Z_0-9]*',
            },
            refresPolicy = editcallback_refresh,
        },
        {
            attr = 'assign_root',
            tp = 'edit_type_combo',
            parm = {
                name = 'assign_root',
                list = var_assign_info,
            },
            refresPolicy = editcallback_refresh,
        },
        {
            attr = 'pos',
            tp = 'edit_type_pos',
            parm = {
                name = '位置',
            },
            refresPolicy = editcallback_refresh,
        },
        {
            attr = 'size',
            tp = 'edit_type_size',
            parm = {
                name = '大小',
            },
            refresPolicy = editcallback_refresh_size,
        },
        {
            attr = 'anchor',
            tp = 'edit_type_number2',
            parm = {
                name = '锚点',
                target = {'x', 'y'},
                precision = 3,
            },
            refresPolicy = editcallback_refresh,
        },
        {
            attr = 'scale',
            tp = 'edit_type_scale',
            parm = {
                name = '缩放',
            },
            refresPolicy = editcallback_refresh,
        },
        {
            attr = 'rotation',
            tp = 'edit_type_number',
            parm = {
                name = '旋转',
                precision = 2,
                min = -360,
                max = 360,
            },
            refresPolicy = editcallback_refresh,
        },
        {
            attr = 'skew',
            tp = 'edit_type_number2',
            parm = {
                name = '倾斜',
                target = {'x', 'y'},
                precision = 3,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'hide',
            tp = 'edit_type_bool',
            parm = {
                name = '隐藏',
            },
            refresPolicy = editcallback_refresh,
        },
        {
            attr = 'zorder',
            tp = 'edit_type_number',
            parm = {
                name = 'Z次序',
                precision = 0,
            },
            refresPolicy = editcallback_refresh_load,
        }
    },
    ['CCLayer'] = {
        {
            attr = 'touchEnabled',
            tp = 'edit_type_bool',
            parm = {
                name = '触摸',
            },
            refresPolicy = editcallback_refresh_all_and_conf_and_reload_edit,
        },
        {
            attr = 'forceHandleTouch',
            rely_on = 'touchEnabled',
            tp = 'edit_type_bool',
            parm = {
                name = '强制触摸',
            },
            refresPolicy = nil,
        },
        {
            attr = 'swallow',
            rely_on = 'touchEnabled',
            tp = 'edit_type_bool',
            parm = {
                name = '吞噬触摸',
            },
            refresPolicy = nil,
        },
        {
            attr = 'noEventAfterMove',
            rely_on = 'touchEnabled',
            tp = 'edit_type_bool',
            parm = {
                name = '移动取消触摸',
            },
            refresPolicy = editcallback_refresh_all_and_conf_and_reload_edit,
        },
        {
            attr = 'move_dist',
            rely_on = 'noEventAfterMove',
            tp = 'edit_type_scale_1',
            parm = {
                name = '移动距离',
            },
            refresPolicy = nil,
        },
    },
    ['CCLayerColor'] = {
        {
            attr = 'color',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'opacity',
            tp = 'edit_type_number',
            parm = {
                name = '透明度',
                precision = 0,
                min = 0,
                max = 255,
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCLayerGradient'] = {
        {
            attr = 'startColor',
            tp = 'edit_type_select_color',
            parm = {
                name = '起始颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'endColor',
            tp = 'edit_type_select_color',
            parm = {
                name = '结束颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'startOpacity',
            tp = 'edit_type_number',
            parm = {
                name = '起始透明度',
                precision = 0,
                min = 0,
                max = 255,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'endOpacity',
            tp = 'edit_type_number',
            parm = {
                name = '结束透明度',
                precision = 0,
                min = 0,
                max = 255,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'vector',
            tp = 'edit_type_number2',
            parm = {
                name = '向量',
                target = {'x', 'y'},
                precision = 3,
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['LayerRadialGradient'] = {
        {
            attr = 'startColor',
            tp = 'edit_type_select_color',
            parm = {
                name = '起始颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'endColor',
            tp = 'edit_type_select_color',
            parm = {
                name = '结束颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'startOpacity',
            tp = 'edit_type_number',
            parm = {
                name = '起始透明度',
                precision = 0,
                min = 0,
                max = 255,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'endOpacity',
            tp = 'edit_type_number',
            parm = {
                name = '结束透明度',
                precision = 0,
                min = 0,
                max = 255,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'radius',
            tp = 'edit_type_number',
            parm = {
                name = '半径',
                precision = 0,
                min = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'center',
            tp = 'edit_type_number2',
            parm = {
                name = '中心',
                target = {'x', 'y'},
                precision = 3,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'expand',
            tp = 'edit_type_number',
            parm = {
                name = 'expand',
                precision = 3,
                min = 0,
                max = 1,
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCSprite'] = {
        {
            attr = 'displayFrame',
            tp = 'edit_type_select_sprite_frame',
            parm = {
                name = '图像',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'color',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'opacity',
            tp = 'edit_type_number',
            parm = {
                name = '透明度',
                precision = 0,
                min = 0,
                max = 255,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'blendFun',
            tp = 'edit_type_combo2',
            parm = {
                name1 = 'src混合',
                name2 = 'dst混合',
                target = {'src', 'dst'},
                list = blend_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCScale9Sprite'] = {
        {
            attr = 'spriteFrame',
            tp = 'edit_type_select_sprite_frame',
            parm = {
                name = '图像',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'capInsets',
            tp = 'edit_type_select_capinsets',
            parm = {
                name = '九宫格',
                edit_sprite_frame = 'spriteFrame',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'color',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'opacity',
            tp = 'edit_type_number',
            parm = {
                name = '透明度',
                precision = 0,
                min = 0,
                max = 255,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'blendFun',
            tp = 'edit_type_combo2',
            parm = {
                name1 = 'src混合',
                name2 = 'dst混合',
                target = {'src', 'dst'},
                list1 = blend_info,
                list2 = blend_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['RepeatSprite'] = {
        {
            attr = 'img',
            tp = 'edit_type_select_file',
            parm = {
                name = '图片',
                file_ext = '*.png|*.jpg',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'color',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'opacity',
            tp = 'edit_type_number',
            parm = {
                name = '透明度',
                precision = 0,
                min = 0,
                max = 255,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'blendFun',
            tp = 'edit_type_combo2',
            parm = {
                name1 = 'src混合',
                name2 = 'dst混合',
                target = {'src', 'dst'},
                list1 = blend_info,
                list2 = blend_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'addressMode',
            tp = 'edit_type_combo',
            parm = {
                name = '纹理循环',
                list = repeat_sprite_addres_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['RichLabel'] = {
        {
            attr = 'text',
            tp = 'edit_type_select_multilang',
            parm = {
                name = '内容',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'font_size',
            tp = 'edit_type_number',
            parm = {
                name = '字体大小',
                precision = 0,
                min = 1,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'max_width',
            tp = 'edit_type_number',
            parm = {
                name = '最大宽度',
                precision = 0,
                min = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'h_align',
            tp = 'edit_type_combo',
            parm = {
                name = '水平对齐',
                list = h_align_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'color',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'spacing',
            tp = 'edit_type_number',
            parm = {
                name = '行间距',
                precision = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['_commonCCLabel'] = {
        {
            attr = 'text',
            tp = 'edit_type_select_multilang',
            parm = {
                name = '内容',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'fontSize',
            tp = 'edit_type_number',
            parm = {
                name = '字体大小',
                precision = 0,
                min = 1,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'dimensions',
            tp = 'edit_type_size',
            parm = {
                name = 'dimensions',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'hAlign',
            tp = 'edit_type_combo',
            parm = {
                name = '水平对齐',
                list = h_align_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'vAlign',
            tp = 'edit_type_combo',
            parm = {
                name = '垂直对齐',
                list = v_align_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'color',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'opacity',
            tp = 'edit_type_number',
            parm = {
                name = '透明度',
                precision = 0,
                min = 0,
                max = 255,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'spacing',
            tp = 'edit_type_number',
            parm = {
                name = '行间距',
                precision = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'bEnableOutline',
            tp = 'edit_type_bool',
            parm = {
                name = '描边',
            },
            refresPolicy = editcallback_refresh_all_and_conf_and_reload_edit,
        },
        {
            attr = 'shadowColor',
            rely_on = 'bEnableOutline',
            tp = 'edit_type_select_color',
            parm = {
                name = '描边颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'shadowWidth',
            rely_on = 'bEnableOutline',
            tp = 'edit_type_number',
            parm = {
                name = '描边宽度',
                precision = 0,
                min = 1,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'bEnableShadow',
            tp = 'edit_type_bool',
            parm = {
                name = '阴影',
            },
            refresPolicy = editcallback_refresh_all_and_conf_and_reload_edit,
        },
        {
            attr = 'shadowColor1',
            rely_on = 'bEnableShadow',
            tp = 'edit_type_select_color',
            parm = {
                name = '阴影颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'shadowOffset',
            rely_on = 'bEnableShadow',
            tp = 'edit_type_number2',
            parm = {
                name = '阴影偏移值',
                target = {'width', 'height'},
                precision = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['TTFLabel'] = {
        {
            attr = 'bEnableGlow',
            tp = 'edit_type_bool',
            parm = {
                name = '发光',
            },
            refresPolicy = editcallback_refresh_all_and_conf_and_reload_edit,
        },
        {
            attr = 'glowColor',
            rely_on = 'bEnableGlow',
            tp = 'edit_type_select_color',
            parm = {
                name = '发光颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['SystemLabel'] = {
    },
    ['CCLabelAtlas'] = {
        {
            attr = 'fntFile',
            tp = 'edit_type_select_file',
            parm = {
                name = '字体配置',
                file_ext = '*.plist',
                file_type_name = '字体配置',
                validate_file = editor_utils_is_valid_font_atlas_plist,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'text',
            tp = 'edit_type_string',
            parm = {
                name = '内容',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'color',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'opacity',
            tp = 'edit_type_number',
            parm = {
                name = '透明度',
                precision = 0,
                min = 0,
                max = 255,
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCLabelBMFont'] = {
        {
            attr = 'fntFile',
            tp = 'edit_type_select_file',
            parm = {
                name = '字体配置',
                file_ext = '*.fnt',
                file_type_name = '字体配置',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'text',
            tp = 'edit_type_string',
            parm = {
                name = '内容',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'color',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'opacity',
            tp = 'edit_type_number',
            parm = {
                name = '透明度',
                precision = 0,
                min = 0,
                max = 255,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'hAlignment',
            tp = 'edit_type_combo',
            parm = {
                name = '水平对齐',
                list = h_align_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'maxLineWidth',
            tp = 'edit_type_number',
            parm = {
                name = '行宽度',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'imageOffset',
            tp = 'edit_type_pos',
            parm = {
                name = '偏移',
            },
            refresPolicy = editcallback_refresh_load,
        },
        
    },
    ['CCRectBorder'] = {
        {
            attr = 'line_weight',
            tp = 'edit_type_number',
            parm = {
                name = '宽度',
                precision = 0,
                min = 1,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'line_color',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCWebView'] = {
        {
            attr = 'url',
            tp = 'edit_type_string',
            parm = {
                name = 'url',
            },
            refresPolicy = nil,
        },
        {
            attr = 'scale_page',
            tp = 'edit_type_bool',
            parm = {
                name = 'scale_page',
            },
            refresPolicy = nil,
        },
    },
    ['_commonButton'] = {
        {
            attr = '9sprite',
            tp = 'edit_type_bool',
            parm = {
                name = '九宫格',
            },
            refresPolicy = editcallback_refresh_all_and_conf_and_reload_edit,
        },
        {
            attr = 'capInsets',
            rely_on = '9sprite',
            tp = 'edit_type_select_capinsets',
            parm = {
                name = '九宫格',
                edit_sprite_frame = {'plist', 'frame1'},
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'plist',
            tp = 'edit_type_select_file',
            parm = {
                name = '图集',
                file_ext = '*.plist',
                file_type_name = '图集',
                validate_file = function(path)
                    return path == '' or editor_utils_is_valid_sprite_plist(path)
                end,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'frame1',
            tp = 'edit_type_select_sprite_frame_name',
            parm = {
                name = 'frame1',
                plist = 'plist',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'frame2',
            tp = 'edit_type_select_sprite_frame_name',
            parm = {
                name = 'frame2',
                plist = 'plist',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'frame3',
            tp = 'edit_type_select_sprite_frame_name',
            parm = {
                name = 'frame3',
                plist = 'plist',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'enableText',
            tp = 'edit_type_bool',
            parm = {
                name = '文本',
            },
            refresPolicy = editcallback_refresh_all_and_conf_and_reload_edit,
        },
        {
            attr = 'text',
            rely_on = 'enableText',
            tp = 'edit_type_select_multilang',
            parm = {
                name = '内容',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'fontSize',
            rely_on = 'enableText',
            tp = 'edit_type_number',
            parm = {
                name = '字体大小',
                precision = 0,
                min = 1,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'textColor1',
            rely_on = 'enableText',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色1',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'textColor2',
            rely_on = 'enableText',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色2',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'textColor3',
            rely_on = 'enableText',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色3',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'textOffset',
            rely_on = 'enableText',
            tp = 'edit_type_pos',
            parm = {
                name = '文本位置',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'isEnabled',
            tp = 'edit_type_bool',
            parm = {
                name = '有效',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'zoomScale',
            tp = 'edit_type_number',
            parm = {
                name = 'zoomScale',
                precision = 3,
                min = 0,
            },
            refresPolicy = nil,
        },
        {
            attr = 'swallow',
            tp = 'edit_type_bool',
            parm = {
                name = 'swallow',
            },
            refresPolicy = nil,
        },
        {
            attr = 'noEventAfterMove',
            tp = 'edit_type_bool',
            parm = {
                name = 'noEventAfterMove',
            },
            refresPolicy = editcallback_refresh_all_and_conf_and_reload_edit,
        },
        {
            attr = 'move_dist',
            rely_on = 'noEventAfterMove',
            tp = 'edit_type_scale_1',
            parm = {
                name = '移动距离',
            },
            refresPolicy = nil,
        },
        {
            attr = 'tips',
            tp = 'edit_type_string',
            parm = {
                name = '按钮提示',
            },
            refresPolicy = editcallback_refresh_load,
        }
    },
    ['CCButton'] = {
    },
    ['CCCheckButton'] = {
        {
            attr = 'check',
            tp = 'edit_type_bool',
            parm = {
                name = 'check',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCEditBoxExt'] = {
        {
            attr = 'text',
            tp = 'edit_type_select_multilang',
            parm = {
                name = '内容',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'colText',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'placeHolder',
            tp = 'edit_type_select_multilang',
            parm = {
                name = 'placeHolder',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'colPlaceHolder',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'fontSize',
            tp = 'edit_type_number',
            parm = {
                name = '字体大小',
                precision = 0,
                min = 1,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'nMaxLength',
            tp = 'edit_type_number',
            parm = {
                name = 'nMaxLength',
                precision = 0,
                min = 0,
            },
            refresPolicy = nil,
        },
    },
    ['CCAnimateSprite'] = {
        {
            attr = 'plist',
            tp = 'edit_type_select_file',
            parm = {
                name = '动画配置',
                file_ext = '*.plist',
                file_type_name = '动画配置',
                validate_file = editor_utils_is_valid_sprite_plist,
            },
            refresPolicy = editcallback_refresh_all_and_conf_and_reload_edit,
        },
        {
            attr = 'frameDelay',
            tp = 'edit_type_number',
            parm = {
                name = '帧间隔',
                precision = 6,
                min = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'repeatCount',
            tp = 'edit_type_number',
            parm = {
                name = '重复次数',
                precision = 0,
                min = -1,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'isPlay',
            tp = 'edit_type_bool',
            parm = {
                name = '播放',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'blendFun',
            tp = 'edit_type_combo2',
            parm = {
                name1 = 'src混合',
                name2 = 'dst混合',
                target = {'src', 'dst'},
                list1 = blend_info,
                list2 = blend_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'action',
            tp = 'edit_type_animate_sprite_combo',
            parm = {
                name = '动作',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCProgressTimer'] = {
        {
            attr = 'displayFrame',
            tp = 'edit_type_select_sprite_frame',
            parm = {
                name = '图像',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'midPoint',
            tp = 'edit_type_number2',
            parm = {
                name = 'midPoint',
                target = {'x', 'y'},
                precision = 6,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'type',
            tp = 'edit_type_combo',
            parm = {
                name = '类型',
                list = progress_bar_type_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'percentage',
            tp = 'edit_type_number',
            parm = {
                name = '百分比',
                precision = 1,
                min = 0,
                max = 100,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'barChangeRate',
            tp = 'edit_type_number2',
            parm = {
                name = 'changeRate',
                target = {'x', 'y'},
                precision = 6,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'reverse',
            tp = 'edit_type_bool',
            parm = {
                name = '反转',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCLoadingBar'] = {
        {
            attr = '9sprite',
            tp = 'edit_type_bool',
            parm = {
                name = '九宫格',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'capInsets',
            tp = 'edit_type_select_capinsets',
            parm = {
                name = '九宫格',
                edit_sprite_frame = 'displayFrame',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'displayFrame',
            tp = 'edit_type_select_sprite_frame',
            parm = {
                name = '图像',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'direction',
            tp = 'edit_type_combo',
            parm = {
                name = '类型',
                list = loading_bar_direction_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'percentage',
            tp = 'edit_type_number',
            parm = {
                name = '百分比',
                precision = 1,
                min = 0,
                max = 100,
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCSlider'] = {
        {
            attr = 'percentage',
            tp = 'edit_type_number',
            parm = {
                name = '百分比',
                precision = 1,
                min = 0,
                max = 100,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'path',
            tp = 'edit_type_select_template',
            parm = {
                name = 'template',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCParticleSystemQuad'] = {
        {
            attr = 'particleFile',
            tp = 'edit_type_select_file',
            parm = {
                name = '粒子配置',
                file_ext = '*.plist',
                file_type_name = '粒子配置',
                validate_file = editor_utils_is_valid_particle_plist,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'posType',
            tp = 'edit_type_combo',
            parm = {
                name = 'posType',
                list = particle_pos_type_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'stop',
            tp = 'edit_type_bool',
            parm = {
                name = 'stop',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCClippingNode'] = {
        {
            attr = 'displayFrame',
            tp = 'edit_type_select_sprite_frame',
            parm = {
                name = '图像',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'alphaThreshold',
            tp = 'edit_type_number',
            parm = {
                name = 'alphaThreshold',
                precision = 3,
                min = 0,
                max = 1
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'inverted',
            tp = 'edit_type_bool',
            parm = {
                name = 'inverted',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['ClippingRectangleNode'] = {
        {
            attr = 'size',
            tp = 'edit_type_size',
            parm = {
                name = '大小',
            },
            refresPolicy = editcallback_refresh_all,
        },
    },
    ['CCSizeSprite'] = {
        {
            attr = 'displayFrame',
            tp = 'edit_type_select_sprite_frame',
            parm = {
                name = '图像',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCCombobox'] = {
        {
            attr = 'popup_item_width',
            tp = 'edit_type_number',
            parm = {
                name = '下拉框宽',
                precision = 0,
                min = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'text',
            tp = 'edit_type_string',
            parm = {
                name = '内容',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'combobox_template',
            tp = 'edit_type_select_template',
            parm = {
                name = 'template',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'combobox_popup_layer_template',
            tp = 'edit_type_select_template',
            parm = {
                name = 'layer_temp',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCBFile'] = {
        {
            attr = 'size',
            tp = 'edit_type_size',
            parm = {
                name = '大小',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'ccbFile',
            tp = 'edit_type_select_template',
            parm = {
                name = 'template',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'template_info',
            tp = 'edit_type_template_info',
            parm = {
                name = '动态属性',
                edit_template = 'ccbFile',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'async',
            tp = 'edit_type_bool',
            parm = {
                name = '异步加载',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCScrollView'] = {
        {
            attr = 'container',
            tp = 'edit_type_select_template',
            parm = {
                name = 'container',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'direction',
            tp = 'edit_type_combo',
            parm = {
                name = 'direction',
                list = scroll_direction_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'bounces',
            tp = 'edit_type_bool',
            parm = {
                name = 'bounces',
            },
            refresPolicy = nil,
        },
    },
    ['_commonContainer'] = {
        {
            attr = 'numPerUnit',
            tp = 'edit_type_number',
            parm = {
                name = 'numPerUnit',
                precision = 0,
                min = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'horzBorder',
            tp = 'edit_type_number',
            parm = {
                name = 'horzBorder',
                precision = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'vertBorder',
            tp = 'edit_type_number',
            parm = {
                name = 'vertBorder',
                precision = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'horzIndent',
            tp = 'edit_type_number',
            parm = {
                name = 'horzIndent',
                precision = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'vertIndent',
            tp = 'edit_type_number',
            parm = {
                name = 'vertIndent',
                precision = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'template',
            tp = 'edit_type_select_template',
            parm = {
                name = 'template',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'initCount',
            tp = 'edit_type_number',
            parm = {
                name = 'initCount',
                precision = 0,
                min = 0,
                max = 10000,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'template_info',
            tp = 'edit_type_template_info',
            parm = {
                name = '动态属性',
                edit_template = 'template',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'customize_info',
            tp = 'edit_type_container_template_info',
            parm = {
                name = '容器属性',
                default_template = 'template',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'left2rightOrder',
            tp = 'edit_type_bool',
            parm = {
                name = 'L2ROrder',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['_commonTemplateList'] = {
        {
            attr = 'bounces',
            tp = 'edit_type_bool',
            parm = {
                name = 'bounces',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'notAutoHideLen',
            tp = 'edit_type_number',
            parm = {
                name = 'notAutoHideLen',
                precision = 0,
                min = 0,
            },
        },
    },
    ['CCHorzAsyncList'] = {
        {
            attr = 'singleItemReverseLoadOrder',
            tp = 'edit_type_bool',
            parm = {
                name = '反序加载',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCVerAsyncList'] = {
        {
            attr = 'singleItemReverseLoadOrder',
            tp = 'edit_type_bool',
            parm = {
                name = '反序加载',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCTreeView'] = {
        {
            attr = 'template',
            tp = 'edit_type_select_template',
            parm = {
                name = 'template',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCSkeletonAnimation'] = {
        {
            attr = 'animation_data',
            tp = 'edit_type_select_spine_file',
            parm = {
                name = '动画配置',
                file_ext = '*.json',
                file_type_name = 'spine动画',
                validate_file = editor_utils_is_valid_spine_json,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'isPlay',
            tp = 'edit_type_bool',
            parm = {
                name = '是否播放',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'isLoop',
            tp = 'edit_type_bool',
            parm = {
                name = '是否循环',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCMotionMask'] = {
        {
            attr = 'path',
            tp = 'edit_type_select_sprite_frame_name',
            parm = {
                name = '图像',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'color',
            tp = 'edit_type_select_color',
            parm = {
                name = '颜色',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'fade',
            tp = 'edit_type_number',
            parm = {
                name = '残留时间',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'minSeg',
            tp = 'edit_type_number',
            parm = {
                name = '段间隔',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'stroke',
            tp = 'edit_type_number',
            parm = {
                name = '残影宽度',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['Live2DSprite'] = {
        {
            attr = 'live2d_data',
            tp = 'edit_type_select_live2d_file',
            parm = {
                name = 'live2d配置',
                file_ext = '*.json',
                file_type_name = 'live2d配置',
                validate_file = editor_utils_is_valid_live2d_json,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'is_play',
            tp = 'edit_type_bool',
            parm = {
                name = '是否播放',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'is_loop',
            tp = 'edit_type_bool',
            parm = {
                name = '是否循环',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'is_asyn',
            tp = 'edit_type_bool',
            parm = {
                name = '是否异步',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['Node3D'] = {
        {
            attr = 'pos_z',
            tp = 'edit_type_number',
            parm = {
                name = 'pos_z',
                precision = 3,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'scale_z',
            tp = 'edit_type_number',
            parm = {
                name = 'scale_z',
                precision = 3,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'globalZorder',
            tp = 'edit_type_number',
            parm = {
                name = 'globalZorder',
                precision = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'cameraMask',
            tp = 'edit_type_combo',
            parm = {
                name = 'cameraMask',
                list = camera_flag_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['PerspectiveCamera'] = {
        {
            attr = 'fieldOfView',
            tp = 'edit_type_number',
            parm = {
                name = 'fieldOfView',
                precision = 0,
                min = 0,
                max = 180,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'nearPlane',
            tp = 'edit_type_number',
            parm = {
                name = 'nearPlane',
                precision = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'farPlane',
            tp = 'edit_type_number',
            parm = {
                name = 'farPlane',
                precision = 0,
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'cameraFlag',
            tp = 'edit_type_combo',
            parm = {
                name = 'cameraFlag',
                list = camera_flag_info,
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['Sprite3D'] = {
        {
            attr = 'modelPath',
            tp = 'edit_type_select_file',
            parm = {
                name = '3d模型配置',
                file_ext = '*.c3b',
                file_type_name = '3d模型配置',
                validate_file = editor_utils_is_valid_3dmodel_file,
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
    ['CCPUParticleSystem3D'] = {
        {
            attr = 'pu_path',
            tp = 'edit_type_select_file',
            parm = {
                name = '动画pu配置',
                file_ext = '*.pu',
                file_type_name = 'pu文件',
            },
            refresPolicy = editcallback_refresh_load,
        },
        {
            attr = 'material_path',
            tp = 'edit_type_select_file',
            parm = {
                name = '动画material配置',
                file_ext = '*.material',
                file_type_name = 'material文件',
            },
            refresPolicy = editcallback_refresh_load,
        },
    },
}

ani_edit_types = {
    {
        name = '辅助序列动画',
        list = {
            {'Sequence','顺序执行Sequence'},
            {'Spawn','同时执行Spawn'},
        },
    },
    {
        name = '基本动画',
        list = {
            {
                name = '位置',
                list = {
                    {'MoveTo','直线移动到MoveTo'},
                    {'MoveBy','直线移动一定距离MoveBy'},
                    {'BezierTo','曲线移动到BezierTo'},
                    {'BezierBy','曲线移动一定距离BezierBy'},
                    {'CardinalSplineBy','曲线平滑移动距离CardinalSplineBy'},
                    {'JumpTo','跳跃到一个位置JumpTo'},
                    {'JumpBy','跳跃一定距离JumpBy'},
                    {'Place','瞬间移动到Place'},
                }
            },
            {
                name = '旋转',
                list = {
                    {'RotateTo','旋转到一个角度RotateTo'},
                    {'RotateBy','旋转一定角度RotateBy'},
                }
            },
            {
                name = '缩放',
                list = {
                    {'ScaleTo','缩放到ScaleTo'},
                    {'ScaleBy','缩放一定大小ScaleBy'},
                    {'SkewTo','反转到一个角度SkewTo'},
                    {'SkewBy','反转一定角度SkewBy'},
                }
            },
            {
                name = '颜色',
                list = {
                    {'TintTo','渐变到一定颜色TintTo'},
                    {'FadeTo','渐变到一定透明度FadeTo'},
                    {'FadeIn','渐变到完全显示FadeIn'},
                    {'FadeOut','渐变到完全消失FadeOut'},
                }
            },
            {
                name = '显示',
                list = {
                    {'Show','瞬间显示Show'},
                    {'Hide','瞬间隐藏Hide'},
                    {'ToggleVisibility','切换隐藏，显示ToggleVisibility'},
                    {'Blink','闪烁Blink'},
                }
            },
            {'DelayTime','延时动作DelayTime'},
            {'TemplateAction', '模板动画'},
            {'PlayAudio', '音效播放'},
            {'PlayMusic', '音乐播放'},
            {'RemoveSelf','移除自己RemoveSelf'},
            {'CallFunc','回调函数CallFunc'},
            {'PlaySkeletonAnimation','Spine骨骼动画'},
            {'PlayParticleAnimation','粒子动画'},
        },
    },
    {
        name = '修饰动画',
        list = {
            {'Repeat','循环一定次数Repeat'},
            {'RepeatForever','无限重复RepeatForever'},
            {'Speed','人工设定速度Speed'},
            {'EaseIn',},
            {'EaseOut',},
            {'EaseInOut',},
            {'EaseSineIn',},
            {'EaseSineOut',},
            {'EaseSineInOut',},
            {'EaseQuadraticActionIn',},
            {'EaseQuadraticActionOut',},
            {'EaseQuadraticActionInOut',},
            {'EaseCubicActionIn',},
            {'EaseCubicActionOut',},
            {'EaseCubicActionInOut',},
            {'EaseQuarticActionIn',},
            {'EaseQuarticActionOut',},
            {'EaseQuarticActionInOut',},
            {'EaseQuinticActionIn',},
            {'EaseQuinticActionOut',},
            {'EaseQuinticActionInOut',},
            {'EaseExponentialIn',},
            {'EaseExponentialOut',},
            {'EaseExponentialInOut',},
            {'EaseCircleActionIn',},
            {'EaseCircleActionOut',},
            {'EaseCircleActionInOut',},
            {'EaseElasticIn',},
            {'EaseElasticOut',},
            {'EaseElasticInOut',},
            {'EaseBackIn',},
            {'EaseBackOut',},
            {'EaseBackInOut',},
            {'EaseBounceIn',},
            {'EaseBounceOut',},
            {'EaseBounceInOut',},
        },
    }
}

local function _vertify_ani_edit_types(infoList)
    if infoList['name'] then
        _vertify_ani_edit_types(infoList.list)
    else
        for _, typeInfo in ipairs(infoList) do
            if typeInfo['name'] then
                _vertify_ani_edit_types(typeInfo.list)
            else
                return assert(is_table(typeInfo))
            end
        end
    end
end

_vertify_ani_edit_types(ani_edit_types)

-- 动画类型转换信息
ani_edit_types_convert_info = {}

local function _replaceAniTypeName(info)
    local new_t = {}
    for k, v in pairs(info) do
        local t = nil
        local key = k
        if is_table(v) then
            t = _replaceAniTypeName(v)
        else
            t = v
        end
        if k == 'name' then
            key = 'sub_group_name'
        end
        if k == 'list' then
            key = 'sub_group'
        end
        new_t[key] = t
    end
    return new_t
end

local function _solveAniTypeNameInfo(info)
    if info.sub_group_name then
        _solveAniTypeNameInfo(info.sub_group)
        return
    end
    for k, typeInfo in pairs(info) do
        if typeInfo.sub_group_name then
            _solveAniTypeNameInfo(typeInfo.sub_group)
            for key, v in pairs(typeInfo) do
                if key ~= 'sub_group_name' and key ~= 'sub_group' then
                    if v.sub_group_name then
                        _solveAniTypeNameInfo(v)
                    else
                        typeInfo[key] = {v[1], v[1]}
                    end
                end
            end
        else
            info[k] = {typeInfo[1], typeInfo[1]}
        end
    end
end

for _, typeInfo in pairs(ani_edit_types) do
    if not ani_edit_types_convert_info[typeInfo.name] then
        local info = _replaceAniTypeName(table.deepcopy(typeInfo.list))
        _solveAniTypeNameInfo(info)
        ani_edit_types_convert_info[typeInfo.name] = info
    end
end

spect_ani_edit_types = {
    name = '特殊节点动画',
    list = {
        {
            name = 'CCProgressTimer',
            list = {
                {'ProgressTo','进度条移动到ProgressTo'},
            },
        },
        {
            name = 'CCAnimateSprite',
            list = {
                {'FrameAnimation','内嵌动画FrameAnimation'},
            },
        },
    },
}

common_ani_edit_info = {
    def = {
        name = '',
    },
    edit_attrs = {
        {
            attr = 'name',
            tp = 'edit_type_string',
            parm = {
                name = '名称',
                re_pattern = '|[_a-z]+[a-zA-Z_0-9]*',
            },
        }
    }
}

ani_edit_info = {
    ['Sequence'] = {},
    ['Spawn'] = {},
    ['DelayTime'] = {
        def = {
            t = 0,
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
        },
    },
    ['MoveTo'] = {
        def = {
            t = 0,
            p = ccp(0, 0),
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'p',
                tp = 'edit_type_pos',
                parm = {
                    name = '位置',
                },
            },
        },
    },
    ['MoveBy'] = {
        def = {
            t = 0,
            p = ccp(0, 0),
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'p',
                tp = 'edit_type_pos',
                parm = {
                    name = '位置',
                },
            },
        },
    },
    ['BezierTo'] = {
        def = {
            t = 0,
            p = ccp(0, 0),
            p1 = ccp(0, 0),
            p2 = ccp(0, 0),
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'p',
                tp = 'edit_type_pos',
                parm = {
                    name = '位置',
                },
            },
            {
                attr = 'p1',
                tp = 'edit_type_pos',
                parm = {
                    name = '控制点1',
                },
            },
            {
                attr = 'p2',
                tp = 'edit_type_pos',
                parm = {
                    name = '控制点2',
                },
            },
        },
    },
    ['BezierBy'] = {
        def = {
            t = 0,
            p = ccp(0, 0),
            p1 = ccp(0, 0),
            p2 = ccp(0, 0),
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'p',
                tp = 'edit_type_pos',
                parm = {
                    name = '位置',
                },
            },
            {
                attr = 'p1',
                tp = 'edit_type_pos',
                parm = {
                    name = '控制点1',
                },
            },
            {
                attr = 'p2',
                tp = 'edit_type_pos',
                parm = {
                    name = '控制点2',
                },
            },
        },
    },
    ['CardinalSplineBy'] = {
        def = {
            t = 0,
            tension = 0.1,
            p_list = {
                ccp(0, 0),
                ccp(0, 0)
            }
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'tension',
                tp = 'edit_type_number',
                parm = {
                    name = '张力',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'p_list',
                tp = 'edit_type_list_pos',
                parm = {
                    name = '位置列表'
                }
            }
        }
    },
    ['ScaleTo'] = {
        def = {
            t = 0,
            s = ccp(0, 0),
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 's',
                tp = 'edit_type_scale',
                parm = {
                    name = '缩放',
                },
            },
        },
    },
    ['ScaleBy'] = {
        def = {
            t = 0,
            s = ccp(0, 0),
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 's',
                tp = 'edit_type_scale',
                parm = {
                    name = '缩放',
                },
            },
        },
    },
    ['RotateTo'] = {
        def = {
            t = 0,
            r = 0,
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'r',
                tp = 'edit_type_number',
                parm = {
                    name = '旋转',
                    precision = 2,
                    min = -360,
                    max = 360,
                },
            },
        },
    },
    ['RotateBy'] = {
        def = {
            t = 0,
            r = 0,
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'r',
                tp = 'edit_type_number',
                parm = {
                    name = '旋转',
                    precision = 2,
                    min = -360,
                    max = 360,
                },
            },
        },
    },
    ['SkewTo'] = {
        def = {
            t = 0,
            s = ccp(0, 0),
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 's',
                tp = 'edit_type_number2',
                parm = {
                    name = '倾斜',
                    target = {'x', 'y'},
                    precision = 3,
                },
            },
        },
    },
    ['SkewBy'] = {
        def = {
            t = 0,
            s = ccp(0, 0),
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 's',
                tp = 'edit_type_number2',
                parm = {
                    name = '倾斜',
                    target = {'x', 'y'},
                    precision = 3,
                },
            },
        },
    },
    ['JumpTo'] = {
        def = {
            t = 0,
            p = ccp(0, 0),
            h = 0,
            j = 0,
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'p',
                tp = 'edit_type_pos',
                parm = {
                    name = '位置',
                },
            },
            {
                attr = 'h',
                tp = 'edit_type_number',
                parm = {
                    name = '高度',
                    precision = 3,
                },
            },
            {
                attr = 'j',
                tp = 'edit_type_number',
                parm = {
                    name = '跳的次数',
                    precision = 0,
                },
            },
        },
    },
    ['JumpBy'] = {
        def = {
            t = 0,
            p = ccp(0, 0),
            h = 0,
            j = 0,
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'p',
                tp = 'edit_type_pos',
                parm = {
                    name = '位置',
                },
            },
            {
                attr = 'h',
                tp = 'edit_type_number',
                parm = {
                    name = '高度',
                    precision = 3,
                },
            },
            {
                attr = 'j',
                tp = 'edit_type_number',
                parm = {
                    name = '跳的次数',
                    precision = 0,
                },
            },
        },
    },
    ['Blink'] = {
        def = {
            t = 0,
            n = 1,
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'n',
                tp = 'edit_type_number',
                parm = {
                    name = '跳的次数',
                    precision = 0,
                },
            },
        },
    },
    ['TintTo'] = {
        def = {
            t = 0,
            color = 0xffffff,
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'color',
                tp = 'edit_type_select_color',
                parm = {
                    name = '颜色',
                },
            },
        },
    },
    ['FadeTo'] = {
        def = {
            t = 0,
            o = 0,
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'o',
                tp = 'edit_type_number',
                parm = {
                    name = '透明度',
                    precision = 0,
                    min = 0,
                    max = 255,
                },
            },
        },
    },
    ['FadeIn'] = {
        def = {
            t = 0,
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
        },
    },
    ['FadeOut'] = {
        def = {
            t = 0,
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
        },
    },
    ['Show'] = {},
    ['Hide'] = {},
    ['ToggleVisibility'] = {},
    ['RemoveSelf'] = {},
    ['Place'] = {
        def = {
            p = ccp(0, 0),
        },
        edit_attrs = {
            {
                attr = 'p',
                tp = 'edit_type_pos',
                parm = {
                    name = '位置',
                },
            },
        },
    },
    ['CallFunc'] = {
        def = {
            n = '',
            p = '',
        },
        edit_attrs = {
            {
                attr = 'n',
                tp = 'edit_type_string',
                parm = {
                    name = '名称',
                    re_pattern = '[_a-z]*[a-zA-Z_0-9]*',
                },
            },
            {
                attr = 'p',
                tp = 'edit_type_string',
                parm = {
                    name = '参数',
                    re_pattern = '[_a-z]*[a-zA-Z_0-9]*',
                },
            },
        },
    },

    ['ProgressTo'] = {
        def = {
            t = 0,
            p = 0,
        },
        edit_attrs = {
            {
                attr = 't',
                tp = 'edit_type_number',
                parm = {
                    name = '时间',
                    precision = 3,
                    min = 0,
                },
            },
            {
                attr = 'p',
                tp = 'edit_type_number',
                parm = {
                    name = '进度',
                    precision = 0,
                    min = 0,
                    max = 100,
                },
            },
        },
    },
    ['FrameAnimation'] = {
        def = {
            p = '',
            c = -1,
        },
        edit_attrs = {
            {
                attr = 'p',
                tp = 'edit_type_select_file',
                parm = {
                    name = '动画配置',
                    file_ext = '*.plist',
                    file_type_name = '动画',
                    validate_file = editor_utils_is_valid_sprite_plist,
                },
            },
            {
                attr = 'c',
                tp = 'edit_type_number',
                parm = {
                    name = '重复次数',
                    precision = 0,
                    min = -1,
                },
            },
        },
    },
    ['PlayParticleAnimation'] = {
        def = {
            particleFile = '',
            posType = cc.POSITION_TYPE_FREE,
        },
        edit_attrs = {
            {
                attr = 'particleFile',
                tp = 'edit_type_select_file',
                parm = {
                    name = '粒子配置',
                    file_ext = '*.plist',
                    file_type_name = '粒子配置',
                    validate_file = editor_utils_is_valid_particle_plist,
                },
            },
            {
                attr = 'posType',
                tp = 'edit_type_combo',
                parm = {
                    name = 'posType',
                    list = particle_pos_type_info,
                },
            },
        },
    },
    ['PlaySkeletonAnimation'] = {
        def = {
            animation_data = {
                jsonPath = '',
                action = '',
            },
            isLoop = true,
        },
        edit_attrs = {
            {
                attr = 'animation_data',
                tp = 'edit_type_select_spine_file',
                parm = {
                    name = '动画配置',
                    file_ext = '*.json',
                    file_type_name = 'spine动画',
                    validate_file = editor_utils_is_valid_spine_json,
                },
            },
            {
                attr = 'isLoop',
                tp = 'edit_type_bool',
                parm = {
                    name = '是否循环',
                },
            },
        },
    },

    ['Repeat'] = {
        def = {
            n = 1,
        },
        edit_attrs = {
            {
                attr = 'n',
                tp = 'edit_type_number',
                parm = {
                    name = '重复次数',
                    precision = 0,
                    min = 1,
                },
            },
        },
    },
    ['EaseIn'] = {
        def = {
            p = 0,
        },
        edit_attrs = {
            {
                attr = 'p',
                tp = 'edit_type_number',
                parm = {
                    name = 'rate',
                    precision = 6,
                },
            },
        },
    },
    ['EaseOut'] = {
        def = {
            p = 0,
        },
        edit_attrs = {
            {
                attr = 'p',
                tp = 'edit_type_number',
                parm = {
                    name = 'rate',
                    precision = 6,
                },
            },
        },
    },
    ['EaseInOut'] = {
        def = {
            p = 0,
        },
        edit_attrs = {
            {
                attr = 'p',
                tp = 'edit_type_number',
                parm = {
                    name = 'rate',
                    precision = 6,
                },
            },
        },
    },
    ['Speed'] = {
        def = {
            speed = 1,
        },
        edit_attrs = {
            {
                attr = 'speed',
                tp = 'edit_type_number',
                parm = {
                    name = 'speed',
                    precision = 6,
                    min_b = 0,
                },
            },
        },
    },

    ['EaseSineIn'] = {},
    ['EaseSineOut'] = {},
    ['EaseSineInOut'] = {},
    ['EaseQuadraticActionIn'] = {},
    ['EaseQuadraticActionOut'] = {},
    ['EaseQuadraticActionInOut'] = {},
    ['EaseCubicActionIn'] = {},
    ['EaseCubicActionOut'] = {},
    ['EaseCubicActionInOut'] = {},
    ['EaseQuarticActionIn'] = {},
    ['EaseQuarticActionOut'] = {},
    ['EaseQuarticActionInOut'] = {},
    ['EaseQuinticActionIn'] = {},
    ['EaseQuinticActionOut'] = {},
    ['EaseQuinticActionInOut'] = {},
    ['EaseExponentialIn'] = {},
    ['EaseExponentialOut'] = {},
    ['EaseExponentialInOut'] = {},
    ['EaseCircleActionIn'] = {},
    ['EaseCircleActionOut'] = {},
    ['EaseCircleActionInOut'] = {},
    ['EaseElasticIn'] = {},
    ['EaseElasticOut'] = {},
    ['EaseElasticInOut'] = {},
    ['EaseBackIn'] = {},
    ['EaseBackOut'] = {},
    ['EaseBackInOut'] = {},
    ['EaseBounceIn'] = {},
    ['EaseBounceOut'] = {},
    ['EaseBounceInOut'] = {},
    ['RepeatForever'] = {},

    ['PlayAudio'] = {
        def = {
            p = '',
        },
        edit_attrs = {
            {
                attr = 'p',
                tp = 'edit_type_select_file',
                parm = {
                    name = '音效路径',
                    file_ext = '*.mp3',
                    file_type_name = '音效',
                    validate_file = editor_utils_is_valid_mp3_file,
                },
            }
        },
    },
    ['PlayMusic'] = {
        def = {
            p = '',
        },
        edit_attrs = {
            {
                attr = 'p',
                tp = 'edit_type_select_file',
                parm = {
                    name = '音乐路径',
                    file_ext = '*.mp3',
                    file_type_name = '音乐',
                    validate_file = editor_utils_is_valid_mp3_file,
                },
            }
        },
    },
    ['TemplateAction'] = {
        def = {
            p = '',
            n = '',
        },
        edit_attrs = {
            {
                attr = 'p',
                tp = 'edit_type_select_template',
                parm = {
                    name = 'template路径',
                    is_reload = true
                },
            },
            {
                attr = 'n',
                tp = 'edit_type_combo',
                parm = {
                    name = '动画名',
                    list = function(self)
                        local templatePath = self._editConf['p']
                        local animationName = self._editConf['n']
                        local l = {{'未选择', ''}, }

                        if not g_uisystem.is_template_valid(templatePath) then
                            self:UpdateData('')
                            return l
                        end

                        local bExist = false
                        -- to opt
                        for animationName, v in pairs(g_uisystem.load_template_create(templatePath)._aniConf) do
                            table.insert(l, {animationName, animationName})
                            if self._data == animationName then
                                bExist = true
                            end
                        end
                        if self._data ~= '' and not bExist then
                            self:UpdateData('')
                        end
                        return l
                    end,
                },
            },
        },
        
    }
}

-- verify
for _, info in ipairs(spect_ani_edit_types.list) do
    for _, v in ipairs(info.list) do
        assert(is_table(ani_edit_info[v[1]]))
    end
end

-- merge common edit info
for animation_name, animation_conf in pairs(ani_edit_info) do
    if not animation_conf.def then
        animation_conf.def = {}
    end
    table.merge(animation_conf.def, common_ani_edit_info.def)

    if not animation_conf.edit_attrs then
        animation_conf.edit_attrs = {}
    end
    table.arr_insert(animation_conf.edit_attrs, 1, common_ani_edit_info.edit_attrs)
end


common_ani_has_children = table.to_value_set({
    'Spawn',
    'Sequence',
})

show_demon_anctions = {
    'EaseSineIn', 
    'EaseSineOut', 
    'EaseSineInOut', 
    'EaseQuadraticActionIn', 
    'EaseQuadraticActionOut', 
    'EaseQuadraticActionInOut', 
    'EaseCubicActionIn', 
    'EaseCubicActionOut', 
    'EaseCubicActionInOut', 
    'EaseQuarticActionIn', 
    'EaseQuarticActionOut', 
    'EaseQuarticActionInOut', 
    'EaseQuinticActionIn', 
    'EaseQuinticActionOut', 
    'EaseQuinticActionInOut', 
    'EaseExponentialIn', 
    'EaseExponentialOut', 
    'EaseExponentialInOut', 
    'EaseCircleActionIn', 
    'EaseCircleActionOut', 
    'EaseCircleActionInOut', 
    'EaseElasticIn', 
    'EaseElasticOut', 
    'EaseElasticInOut', 
    'EaseBackIn', 
    'EaseBackOut', 
    'EaseBackInOut', 
    'EaseBounceIn', 
    'EaseBounceOut', 
    'EaseBounceInOut', 
}

need_custome_edit_actions = {
    ['BezierTo'] = {
        file = 'uieditor.edit_action.dlg_edit_bezier_action_panel',
        edit_name = '编辑曲线'
    },
    ['BezierBy'] = {
        file = 'uieditor.edit_action.dlg_edit_bezier_action_panel',
        edit_name = '编辑曲线'
    },
    ['CardinalSplineBy'] = {
        file = 'uieditor.edit_action.dlg_edit_cardinalspline_action_panel',
        edit_name = '编辑曲线'
    },
}

--返回资源是否有效，子类型（如果没有字类型，返回主类型即文件后缀）
local function check_plist_file_res(plistPath)
    local plistConf = utils_get_plist_conf(plistPath)
    if not is_table(plistConf) then
        return false
    end
    if plistConf['frames'] and plistConf['metadata'] then
        local metadata = plistConf['metadata']
        local aniImgPath = g_fileUtils:fullPathFromRelativeFile(metadata['realTextureFileName'] or metadata['textureFileName'], plistPath)
        if not g_fileUtils:isFileExist(aniImgPath) then
            print('aniImgPath', aniImgPath)
            return
        end
        return true, 'animate'
    end

    if plistConf['version'] and plistConf['textureFilename'] and plistConf['firstChar'] then
        local textureFilename = plistConf['textureFilename']
        local textureImgPath = g_fileUtils:fullPathFromRelativeFile(textureFilename, plistPath)
        if not g_fileUtils:isFileExist(textureImgPath) then
            print('textureImgPath', textureImgPath)
            return
        end
        return true, 'label_atlas'
    end

    if plistConf['textureFileName'] and plistConf['maxParticles'] then
        local textureFileName = plistConf['textureFileName']
        local textureImgPath = g_fileUtils:fullPathFromRelativeFile(textureFileName, plistPath)
        if not g_fileUtils:isFileExist(textureImgPath) then
            print('paticle textureImgPath', textureImgPath)
            return
        end
        return true, 'particle_system_quad'
    end
end

local function check_fnt_file_res(fntPath)
    local fntImagePath = string.gsub(fntPath, '.fnt', '.png')
    if not g_fileUtils:isFileExist(fntImagePath) then
        print('fntImagePath', fntImagePath)
        return false
    end
    return true, 'fnt'
end

local function check_json_file_res(jsonPath)

    local fileStr = g_fileUtils:getStringFromFile(jsonPath)
    if not is_valid_str(fileStr) then
        return false
    end

    local plistConf = luaext_json_dencode(fileStr)

    if not is_table(plistConf) then
        return false
    end

    if plistConf['model'] and plistConf['textures'] then
        if not editor_utils_is_valid_live2d_json(jsonPath) then
            return false
        end
        return true, 'live2d'
    end

    if plistConf['skeleton'] and plistConf['slots'] then
        local pngPath = string.gsub(jsonPath, '.json', '.png')
        local atlasPath = string.gsub(jsonPath, '.json', '.atlas')
        if not g_fileUtils:isFileExist(pngPath) then
            print('spine pngPath', pngPath)
            return false
        end

        if not g_fileUtils:isFileExist(atlasPath) then
            print('spine atlasPath', atlasPath)
            return false
        end
        return true, 'spine'
    end

    if plistConf['type_name'] then
        return true, 'ui_template'
    end

    if plistConf[1] and plistConf[1]['type_name'] then
        return true, 'anim_template'
    end
end

local function check_live_2d_file_moc_res(mocPath)
    local jsonPath = string.gsub(mocPath, '.moc', '.json')
    local is_valid = check_json_file_res(jsonPath)
    return is_valid, 'moc'
end

local function handle_change_param(mocPath)
    local jsonPath = string.gsub(mocPath, '.moc', '.json')
    return jsonPath
end

-- 拖拽配置文件到编辑器视图生成的节点类型规则约束
file_suffix_to_node = {
    ['png'] = {
        type_name = 'CCSprite',
        params = {
            {
                file_key_path = 'displayFrame.path'
            }
        }
    },
    ['plist'] = {
        ['animate'] = {
            type_name = 'CCAnimateSprite',
            params = {
                {
                    file_key_path = 'plist'
                }
            }
        },
        ['label_atlas'] = {
            type_name = 'CCLabelAtlas',
            params = {
                {
                    file_key_path = 'fntFile'
                }
            }
        },
        ['particle_system_quad'] = {
            type_name = 'CCParticleSystemQuad',
            params = {
                {
                    file_key_path = 'particleFile'
                }
            }
        },
        check_sub_type_policy = check_plist_file_res
    },
    ['fnt'] = {
        type_name = 'CCLabelBMFont',
        params = {
            {
                file_key_path = 'fntFile'
            }
        },
        check_sub_type_policy = check_fnt_file_res
    },
    ['json'] = {
        ['live2d'] = {
            type_name = 'Live2DSprite',
            params = {
                {
                    file_key_path = 'live2d_data.jsonPath'
                }
            }
        },
        ['spine'] = {
            type_name = 'CCSkeletonAnimation',
            params = {
                {
                    file_key_path = 'animation_data.jsonPath'
                }
            }
        },
        check_sub_type_policy = check_json_file_res
    },
    ['moc'] = {
        type_name = 'Live2DSprite',
        params = {
            {
                file_key_path = 'live2d_data.jsonPath',
                change_param = handle_change_param
            }
        },
        check_sub_type_policy = check_live_2d_file_moc_res
    }
}
