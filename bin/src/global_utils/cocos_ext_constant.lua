
-- 下载过程的几个状态
cc.EXT_DOWNLOAD_STATUS = {
    STATUS_ERROR = 1,
    STATUS_PROGRESS = 2,
    STATUS_SUCCEED = 3,
}

cc.EXT_NEW_AUDIO_ENGINE_INVALID_AUDIO_ID = -1
-- new audio engine 最多能够播放音效的数量
cc.EXT_NEW_AUDIO_ENGINE_MAX_PLAY_COUNT = 24
cc.EXT_NEW_AUDIO_ENGINE_MAX_PLAY_LOOP_COUNT = 4
cc.EXT_NEW_AUDIO_ENGINE_MAX_PLAY_NOLOOP_COUNT = cc.EXT_NEW_AUDIO_ENGINE_MAX_PLAY_COUNT - cc.EXT_NEW_AUDIO_ENGINE_MAX_PLAY_LOOP_COUNT


-- web socket 的几个网络状态
cc.EXT_CONNECT_STATUS = {
    CONNECTING = 0,
    OPEN = 1,
    CLOSING = 2,
    CLOSED = 3,
}

cc.EXT_BUGLY_CR_LOG_LEVEL = {
    Off = 0,
    Error = 1,
    Warning = 2,
    Info = 3,
    Debug = 4,
    Verbose = 5,
}

cc.EXT_BUGLY_LOG_LEVEL = {
    Off = -1,
    Verbose = 0,
    Debug = 1,
    Info = 2,
    Warning = 3,
    Error = 4,
}

