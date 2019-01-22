-- 音频播放相关
if not ccexp.AudioEngine:lazyInit() then
    local function empty()
    end
    set_volume = empty
    preload_audio = empty
    stop_audio = empty
    play_audio = empty
    stop_music = empty
    play_music = empty
    is_music_playing = empty
    stop_all_aounds = empty
    destory = empty
    pause_all = empty
    resume_all = empty
    delay_call(0, function()
        if not g_native_conf['debug_control']['test_upload_audio_engine_init_failed_flag'] then
            g_logicEventHandler:AddCallback('logic_game_login_finished', function(tp, game)
                if 'GameType_HALL' == tp then
                    local info = {
                        uid = g_user_info.get_user_info().uid,
                        version = string.format('%d.%d', utils_game_get_engine_sub_version(), utils_get_sdk_version()),
                        channel = platform_get_app_channel_name(),
                        sdk_name = g_native_conf['sdk_name'],
                        device_id = platform_get_device_id(),
                        device_name = platform_get_device_name(),
                    }
                    utils_test_upload_log2server('error_audio_engine_init_failed', info)
                    g_conf_mgr.set_native_conf_k_v('debug_control', 'test_upload_audio_engine_init_failed_flag', true)
                end
            end)
        end
    end)
    return
end


local engine = ccexp.AudioEngine
local _audioLoadedInfo = {}
local _curVolume = 1  -- 当前音量

engine:setMaxAudioInstance(cc.EXT_NEW_AUDIO_ENGINE_MAX_PLAY_COUNT)


-- 设置音效
function set_volume(vol)
    if vol < 0 then
        vol = 0
    elseif vol > 1 then
        vol = 1
    end

    _curVolume = vol

    -- 设置当前正在播放的音量
    for _, audioIDs in pairs(_audioLoadedInfo) do
        for _, audioID in ipairs(audioIDs) do
            engine:setVolume(audioID, _curVolume)
        end
    end
end

-- 预加载
local _preloadList = {}
local _bLoading = false
local function _checkPreload()
    if _bLoading then
        return
    end

    if #_preloadList == 0 then
        return
    end

    -- 下载数组第一个
    local fileName, callbacks = unpack(_preloadList[1])

    if _audioLoadedInfo[fileName] then
        error_msg('[%s] already loaded', fileName)
    end

    _bLoading = true
    engine:preloadWithCallback(fileName, function(bSucceed)
        local _fileName, _callbacks = unpack(table.remove(_preloadList, 1))
        assert(_fileName == fileName and _callbacks == callbacks)
        if _audioLoadedInfo[fileName] then
            error_msg('[%s] already loaded', fileName)
        end

        _bLoading = false
        if bSucceed then
            _audioLoadedInfo[fileName] = {lastPlayTime = utils_get_tick()}
            for _, callback in ipairs(callbacks) do
                callback()
            end
        end

        _checkPreload()
    end)
end

function preload_audio(fileName, callback)
    if not g_fileUtils:isFileExist(fileName) then
        __G__TRACKBACK__(string.format('error!file name [%s] not exists, %s', fileName, debug.traceback()))
        return
    end

    if _audioLoadedInfo[fileName] then
        callback()
        return
    end

    local i, preloadInfo = table.find_if(_preloadList, function(_, v)
        return v[1] == fileName
    end)

    if preloadInfo then
        table.insert(preloadInfo[2], callback)
        if i > 2 then
            -- 调整下载优先级
            table.remove(_preloadList, i)
            table.insert(_preloadList, 2, preloadInfo)
        end
    else
        local loadInfo = {fileName, {callback}}

        if #_preloadList <= 1 then
            table.insert(_preloadList, loadInfo)
        else
            table.insert(_preloadList, 2, loadInfo)
        end
        _checkPreload()
    end
end

function stop_audio(fileName, bUnload)
    if _audioLoadedInfo[fileName] == nil then
        return
    end

    for _, id in ipairs(_audioLoadedInfo[fileName]) do
        engine:stop(id)
    end

    if bUnload then
        engine:uncache(fileName)
        _audioLoadedInfo[fileName] = nil
    else
        _audioLoadedInfo[fileName] = {lastPlayTime = utils_get_tick()}
    end
end

local function _doPlayAudio(fileName, bLoop)
    -- 该音频一定是已经加载好的
    assert(_audioLoadedInfo[fileName])
    -- 最大音效播放数量限制
    if not bLoop and engine:getPlayingAudioCount() >= cc.EXT_NEW_AUDIO_ENGINE_MAX_PLAY_NOLOOP_COUNT then
        print('engine:getPlayingAudioCount() >= EXT_NEW_AUDIO_ENGINE_MAX_PLAY_NOLOOP_COUNT return')
        return
    end

    local audioID = engine:play2d(fileName, bLoop, _curVolume)
    if audioID == cc.EXT_NEW_AUDIO_ENGINE_INVALID_AUDIO_ID then
        __G__TRACKBACK__(string.format('error _doPlayAudio [%s] [%d] [%s]', fileName, engine:getPlayingAudioCount(), str(bLoop)))
    else
       table.insert(_audioLoadedInfo[fileName], audioID)
        if bLoop then
            _audioLoadedInfo[fileName].lastPlayTime = utils_get_tick() + 10000000
        else
            _audioLoadedInfo[fileName].lastPlayTime = utils_get_tick()
        end
    end
end

function play_audio(fileName, bLoop)
    if not g_fileUtils:isFileExist(fileName) then
        printf('error!file name [%s] not exists, %s', fileName, debug.traceback())
        return
    end

    if not g_native_conf['game_audio_info'].isCanPlaySound then
        return
    end

    local curTime = utils_get_tick()
    for k, v in pairs(_audioLoadedInfo) do
        if curTime - v.lastPlayTime >= 60 then
            stop_audio(k, true)
        elseif curTime - v.lastPlayTime >= 30 then
            stop_audio(k, false)
        end
    end

    if _audioLoadedInfo[fileName] == nil then
        preload_audio(fileName, function()
            _doPlayAudio(fileName, bLoop)
        end)
    else
        _doPlayAudio(fileName, bLoop)
    end
end


---------------------------------------------------------------------------- music
local _curPlayingMusic = nil  -- 当前播放的背景音乐

function stop_music(bUnload)
    if _curPlayingMusic then
        stop_audio(_curPlayingMusic, bUnload)
        _curPlayingMusic = nil
    end
end

-- 播放背景音乐
function play_music(fileName, bUnloadPre, bLoop)
    if not g_fileUtils:isFileExist(fileName) then
        __G__TRACKBACK__(string.format('error!file name [%s] not exists, %s', fileName, debug.traceback()))
        return
    end

    stop_music(bUnloadPre)

    if not g_native_conf['game_audio_info'].isCanPlayMusic then
        return
    end

    _curPlayingMusic = fileName

    if _audioLoadedInfo[fileName] == nil then
        preload_audio(fileName, function()
            if _curPlayingMusic == fileName then
                _doPlayAudio(fileName, bLoop)
            end
        end)
    else
        _doPlayAudio(fileName, bLoop)
    end
end

function is_music_playing()
    return _curPlayingMusic ~= nil
end

function stop_all_aounds(bUnload)
    for fileName, audioIDs in pairs(_audioLoadedInfo) do
        if fileName ~= _curPlayingMusic then
            stop_audio(fileName, bUnload)
        end
    end
end

-- 销毁操作
function destory()
    engine:stopAll()
    engine:uncacheAll()
    _audioLoadedInfo = {}
    _curPlayingMusic = nil
end

function pause_all()
    engine:pauseAll()
end

function resume_all()
    engine:resumeAll()
end
