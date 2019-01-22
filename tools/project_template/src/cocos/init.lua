--[[

Copyright (c) 2011-2015 chukong-incc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

include('cocos2d/Cocos2d.lua')
include('cocos2d/Cocos2dConstants.lua')
-- include('cocos2d/functions.lua')

-- opengl
include('cocos2d/Opengl.lua')
include('cocos2d/OpenglConstants.lua')
-- audio
-- include('cocosdenshion/AudioEngine.lua')
-- cocosstudio
-- if nil ~= ccs then
--     include('cocostudio/CocoStudio.lua')
-- end
-- ui
if nil ~= ccui then
    include('ui/GuiConstants.lua')
    include('ui/experimentalUIConstants.lua')
end

-- extensions
include('extension/ExtensionConstants.lua')
-- network
include('network/NetworkConstants.lua')
-- Spine
if nil ~= sp then
    include('spine/SpineConstants.lua')
end

-- include('cocos2d/deprecated.lua')
include('cocos2d/DrawPrimitives.lua')

-- Lua extensions
include('cocos2d/bitExtend.lua')

-- CCLuaEngine
-- include('cocos2d/DeprecatedCocos2dClass.lua')
-- include('cocos2d/DeprecatedCocos2dEnum.lua')
-- include('cocos2d/DeprecatedCocos2dFunc.lua')
-- include('cocos2d/DeprecatedOpenglEnum.lua')

-- register_cocostudio_module
-- if nil ~= ccs then
--     include('cocostudio/DeprecatedCocoStudioClass.lua')
--     include('cocostudio/DeprecatedCocoStudioFunc.lua')
-- end


-- register_cocosbuilder_module
-- include('cocosbuilder/DeprecatedCocosBuilderClass.lua')

-- register_cocosdenshion_module
-- include('cocosdenshion/DeprecatedCocosDenshionClass.lua')
-- include('cocosdenshion/DeprecatedCocosDenshionFunc.lua')

-- register_extension_module
-- include('extension/DeprecatedExtensionClass.lua')
-- include('extension/DeprecatedExtensionEnum.lua')
-- include('extension/DeprecatedExtensionFunc.lua')

-- register_network_module
-- include('network/DeprecatedNetworkClass.lua')
-- include('network/DeprecatedNetworkEnum.lua')
-- include('network/DeprecatedNetworkFunc.lua')

-- register_ui_moudle
-- if nil ~= ccui then
--     include('ui/DeprecatedUIEnum.lua')
--     include('ui/DeprecatedUIFunc.lua')
-- end

-- cocosbuilder
-- include('cocosbuilder/CCBReaderLoad.lua')

-- physics3d
include('physics3d/physics3d-constants.lua')

-- if CC_USE_FRAMEWORK then
--     include('framework/init.lua')
-- end
