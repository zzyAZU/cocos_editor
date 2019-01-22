-- cocos ext
CCSize = cc.size
CCRect = cc.rect
ccp = cc.p
ccp3 = cc.vec3

-- lua 不支持 argb 这么长位数的
function ccc4aFromHex(argb)
    local a = bit.band(bit.rshift(argb, 24), 0xff)
    local r = bit.band(bit.rshift(argb, 16), 0xff)
    local g = bit.band(bit.rshift(argb, 8), 0xff)
    local b = bit.band(argb, 0xff)
    return cc.c4b(r, g, b, a)
end

function ccc4fFromHex(argb)
    local a = bit.band(bit.rshift(argb, 24), 0xff) / 255
    local r = bit.band(bit.rshift(argb, 16), 0xff) / 255
    local g = bit.band(bit.rshift(argb, 8), 0xff) / 255
    local b = bit.band(argb, 0xff) / 255
    return cc.c4f(r, g, b, a)
end

function get_sprite_frame(path, plist)
    if not is_valid_str(path) then
        return
    end

    local frameCache = cc.SpriteFrameCache:getInstance()
    if is_valid_str(plist) then
        frameCache:addSpriteFrames(plist)
        return frameCache:getSpriteFrame(path)
    else
        local texture = g_director:getTextureCache():addImage(path)
        if texture then
            local size = texture:getContentSize()
            return cc.SpriteFrame:createWithTexture(texture, CCRect(0, 0, size.width, size.height))
        end
    end
end

function get_sprite_frame_safe(path, plist)
    local ret = get_sprite_frame(path, plist)
    if not ret then
        printf("spriteframe [%s] [%s] not found \n%s", plist, path, debug.traceback())
        ret = get_sprite_frame(g_constant_conf.constant_uisystem.default_missing_img_path)
    end
    return ret
end

local function _set_content_size(self, sw, sh)
    return CCSize(self:GetContentSize())
end

function cc_utils_SetContentSizeReadOnly(cls)
    assert(tolua_is_class_t(cls))
    -- assert_msg(cls.SetContentSize == cc.Node.SetContentSize, '~~~~~~~~~[%s] SetContentSize not equal to cc.Node:[%s]', tolua_get_class_name(cls), str(cls.SetContentSize))
    cls.SetContentSize = _set_content_size
end

-- @desc:
--  判断节点的size是否为只读
function cc_utils_IsContentSizeReadOnly(cls)
    return cls.SetContentSize == _set_content_size
end

local _frameW, _frameH, _designW, _designH

function update_design_resolution(frameW, frameH, designW, designH)
    _frameW = frameW or g_director:getWinSize().width
    _frameH = frameH or g_director:getWinSize().height
    _designW = designW
    _designH = designH
    ccext_update_design_resolution(_frameW, _frameH, _designW, _designH)
end

function get_design_resolution()
    return _frameW, _frameH, _designW, _designH
end

-- 当脚本层控制 retain release 的时机存在不确定因素导致不能成对调用的时候可以用这种方法
local _managedRefs = nil
function retain_ref(ref)
    if _managedRefs == nil then
        _managedRefs = {}
        g_logicEventHandler:AddCallback('logic_event_restart_app', function()
            for r, count in pairs(_managedRefs) do
                for i = 1, count do
                    r:release()
                end
            end
        end)
    end
end

function release_ref(ref)
    local refCount = _managedRefs[ref]
    if refCount then
        ref:release()
        refCount = refCount - 1

        if refCount == 0 then
            _managedRefs[ref] = nil
        else
            _managedRefs[ref] = refCount
        end
    end
end

function cc_utils_add_program(vert_path, frag_path, key)
    if not cc_utils_is_support_sprite_ext_effect() then
        return
    end
    local program = cc.GLProgramCache:getInstance():getGLProgram(key)
    if program then
        return program
    end
    if not g_fileUtils:isFileExist(vert_path) or not g_fileUtils:isFileExist(frag_path) then
        print('no file exist %s %s', vert_path, frag_path)
        return
    end

    program = cc.GLProgram:createWithFilenames(vert_path, frag_path)
    cc.GLProgramCache:getInstance():addGLProgram(program, key)
    return program
end

function cc_utils_get_blur_screen()
    if not cc_utils_is_support_sprite_ext_effect() then
        return
    end

    --采用RenderTexture的方式
    local win_size_width = g_director:getWinSize().width
    local win_size_height = g_director:getWinSize().height

    --先生成截屏
    local renderTexture = cc.RenderTexture:create(win_size_width, win_size_height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888, gl.DEPTH24_STENCIL8_OES)
    renderTexture:retain()
    renderTexture:begin()
    local scene = g_director:getRunningScene()
    scene:visit()
    renderTexture:endToLua()

    local texture = renderTexture:getSprite():getTexture()
    local blurSprite = cc.Sprite:createWithTexture(texture)
    blurSprite:EnableBlurEffect(10)    
    blurSprite:setAnchorPoint(ccp(0, 0))

    --用模糊的精灵生成一个新的模糊纹理
    local renderTexture_blur = cc.RenderTexture:create(win_size_width, win_size_height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888, gl.DEPTH24_STENCIL8_OES)
    renderTexture_blur:retain()
    renderTexture_blur:begin()
   
    blurSprite:visit()
    renderTexture_blur:endToLua()

    local blur_texture = renderTexture_blur:getSprite():getTexture()
    local newSprite = cc.Sprite:createWithTexture(blur_texture)

    renderTexture:release()
    renderTexture_blur:release()

    return newSprite

    -- local _capture_file_path = g_fileUtils:getWritablePath()..'/__temp_capture_file__.png'
    -- cc.utils:captureScreen(function(succeed)
    --     if succeed then
    --         local sp = cc.Sprite:Create(nil, _capture_file_path)
    --         if callback then
    --             callback(sp)
    --         end
    --     else
    --         if callback then
    --             callback(nil)
    --         end
    --     end
    -- end, _capture_file_path)
end

function cc_utils_is_support_sprite_ext_effect()
    return cc.GLProgramCache ~= nil
end
