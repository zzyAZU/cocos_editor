local curPlatform = g_application:getTargetPlatform()
local bIsIosAndUseSimpleAudioEngine = false
if curPlatform == cc.PLATFORM_OS_IPHONE or curPlatform == cc.PLATFORM_OS_IPAD then
    include('global_utils/ios_utils.lua')
    bIsIosAndUseSimpleAudioEngine = platform_ios_is_use_simple_audio_engine()
end

-- 音频播放相关
if not bIsIosAndUseSimpleAudioEngine and utils_is_game_cpp_interface_available and utils_is_game_cpp_interface_available('new_audio_engine') then
    print('use audio engine')
    local audio_engine_mgr = import('audio_engine_mgr')

    playMusic = function(filename, isLoop)
        audio_engine_mgr.play_music(filename, true, isLoop == true)
    end

    stopMusic = audio_engine_mgr.stop_music

    isMusicPlaying = audio_engine_mgr.is_music_playing

    playSound = audio_engine_mgr.play_audio

    unloadSound = function(filename)
        audio_engine_mgr.stop_audio(filename, true)
    end

    stopAllSounds = audio_engine_mgr.stop_all_aounds

    destory = audio_engine_mgr.destory

    g_eventHandler:AddCallback('event_applicationDidEnterBackground', function()
        audio_engine_mgr.pause_all()
    end)

    g_eventHandler:AddCallback('event_applicationWillEnterForeground', function()
        audio_engine_mgr.resume_all()
    end)
else

print('use simple audio engine')
local engine = cc.SimpleAudioEngine:getInstance()
local curPlatform = g_application:getTargetPlatform()

-- 预加载music
preloadMusic = function(filename)
    assert(filename, "audio.preloadMusic() - invalid filename")
    engine:preloadMusic(filename)
end

-- 播放music
playMusic = function(filename, isLoop)
    assert(filename, "audio.playMusic() - invalid filename")
    local audio_config = g_native_conf.game_audio_info
    if not audio_config.isCanPlayMusic then return end
    if type(isLoop) ~= "boolean" then isLoop = true end
    stopMusic(true)
    if curPlatform == cc.PLATFORM_OS_IPHONE or curPlatform == cc.PLATFORM_OS_IPAD then
        -- iOS 11 BUG 第一次播放不了 尝试预加载
        engine:preloadMusic(filename)
    end
    engine:playMusic(filename, isLoop)
end

-- 停止music
stopMusic = function(isReleaseData)
    if type(isReleaseData) ~= "boolean" then
        isReleaseData = true
    end
    engine:stopMusic(isReleaseData)
end

-- 当前是否有music在播放
isMusicPlaying = function()
    local ret = cc.SimpleAudioEngine:getInstance():isMusicPlaying()
    return ret
end

-- 预加载sound
preloadSound = function(filename)
    if not filename then
        return
    end
    engine:preloadEffect(filename)
end

-- 播放sound
playSound = function(filename, isLoop)
    if not filename then
        return
    end
    if curPlatform == cc.PLATFORM_OS_IPHONE or curPlatform == cc.PLATFORM_OS_IPAD then
    end
    if not g_fileUtils:isFileExist(filename) then
        printf('error!file name [%s] not exists, %s', filename, debug.traceback())
        return
    end
    local audio_config = g_native_conf.game_audio_info
    if not audio_config.isCanPlaySound then return end
    if type(isLoop) ~= "boolean" then isLoop = false end
    return engine:playEffect(filename, isLoop)
end

-- 取消预加载的sound
unloadSound = function(filename)
    if not filename then
        return
    end
    engine:unloadEffect(filename)
end

-- 停止所有的sound
stopAllSounds = function()
    engine:stopAllEffects()
end

-- 停止sound
stopSound = function(handle)
    if not handle then
        return
    end
    engine:stopEffect(handle)
end

-- 销毁音效相关资源等
destory = function()
    cc.SimpleAudioEngine:destroyInstance()
end

g_eventHandler:AddCallback('event_applicationDidEnterBackground', function()
    engine:pauseMusic()
    engine:pauseAllEffects()
end)

g_eventHandler:AddCallback('event_applicationWillEnterForeground', function()
    engine:resumeMusic()
    engine:resumeAllEffects()
end)


end