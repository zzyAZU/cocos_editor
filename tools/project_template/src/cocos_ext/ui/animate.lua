--[[====================================
=
=           帧动画 CCAnimateSprite 扩展
=
========================================]]
local config_animate_sprite_tag = 10000

local CCAnimateSprite, Super = tolua_get_class('CCAnimateSprite')

function CCAnimateSprite:Create()
	local ret = cc.Sprite:create():CastTo(self):_init()
	ret:setStretchEnabled(false)
	return ret
end

-- override
function CCAnimateSprite:_init()
	Super._init(self)

	self._plist = nil
	self._path = nil
	self._aniFilePath = nil
	self._frame_paths = {}
	self._frameDelay = 0.1

	self._playing = false
	self._playIndex = 0
	self._action2framepaths = {}
	self.arrayFrameCount = 1
	return self
end

-- override
function CCAnimateSprite:_registerInnerEvent()
	Super._registerInnerEvent(self)
	self:_regInnerEvent('OnPlayAniEnd')
	self:_regInnerEvent('OnAsyncLoadCompelete')
end

-- 设置每帧延时
function CCAnimateSprite:SetFrameDelay(frameDelay)
	self._frameDelay = frameDelay
end


local _aniInfo = {}
function _getAniInfo(plist)
	local ret = _aniInfo[plist]
	if ret then
		return ret
	end

	local plistConf = utils_get_plist_conf(plist)
	if not is_table(plistConf) then
		print('plistConf', plistConf)
		return
	end

	local frames = plistConf['frames']
	if not is_table(frames) then
		print('frames', frames)
		return
	end

	local metadata = plistConf['metadata']
	if not is_table(metadata) then
		print('metadata', metadata)
		return
	end

	local aniImgPath = g_fileUtils:fullPathFromRelativeFile(metadata['realTextureFileName'] or metadata['textureFileName'], plist)
	if not g_fileUtils:isFileExist(aniImgPath) then
		print('aniImgPath', aniImgPath)
		return
	end

	local action2framepaths = {}
	local aniFrames = {}
	for frameName, _ in sorted_pairs(frames) do
		local startIdx, endIdx = string.find(frameName, "|")
		if startIdx then
			local action = string.sub(frameName, 1, endIdx - 1)
			local actions = action2framepaths[action]
			if not actions then
				actions = {}
				action2framepaths[action] = actions
			end
			table.insert(actions, frameName)
		else
			table.insert(aniFrames, frameName)
		end
	end

	ret = {}
	_aniInfo[plist] = ret
	ret['aniImgPath'] = aniImgPath
	ret['action2framepaths'] = action2framepaths
	ret['aniFrames'] = aniFrames

	return ret
end

-- 设置动画精灵的资源路径
function CCAnimateSprite:SetAniSptDisplayFrameByPath(plist, path, bAsyncLoad)
	if self._plist ~= plist then
		local aniInfo = _getAniInfo(plist)
		if not aniInfo then
			printf('CCAnimateSprite:SetAniSptDisplayFrameByPath failed:%s', str(plist))
			return
		end

		self._plist = plist
		self._frame_paths = aniInfo['aniFrames']
		self._action2framepaths = aniInfo['action2framepaths']
		self._aniFilePath = aniInfo['aniImgPath']

		self._path = table.find_v(self._frame_paths, path) and path or self._frame_paths[1]
	else
		self._path = path
	end

	self._playIndex = self._playIndex + 1
	if bAsyncLoad then
		local curIndex = self._playIndex
		local curAniFilePath = self._aniFilePath
		utils_add_image_async(curAniFilePath, function()
			if self:IsValid() and not self._playing and self._playIndex == curIndex and self._aniFilePath == curAniFilePath then
				self:SetPath(self._plist, self._path)
			end
		end)
	else
		self:SetPath(self._plist, self._path)
	end
end


function CCAnimateSprite:_doPlay(nCount, startTime, action)
	cc.SpriteFrameCache:getInstance():addSpriteFrames(self._plist)

	local arrayFrame = {}
	local action_frame_paths
	if action and self._action2framepaths[action] then
		action_frame_paths = self._action2framepaths[action]
	else
		action_frame_paths = self._frame_paths
	end


	for _, v in ipairs(action_frame_paths) do
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(v)
		if not tolua_is_obj(frame) then
			printf('ani frame [%s] not found', v)
			break
		end
		table.insert(arrayFrame, frame)
	end

	if table.is_empty(arrayFrame) then
		print('CCAnimateSprite:_doPlay arrayFrame is empty')
		return
	end
	
	local ani
	if nCount > 0 then
		local loadTime = utils_get_tick() - startTime
		local frameDelay = loadTime > 0.1 and (self:GetPlayDuration(action) - loadTime / nCount) / self:GetFrameCount(action) or self._frameDelay
		local animation = cc.Animation:createWithSpriteFrames(arrayFrame, frameDelay)
		ani = cc.Repeat:create(cc.Animate:create(animation), nCount)
	else
		local animation = cc.Animation:createWithSpriteFrames(arrayFrame, self._frameDelay)
		ani = cc.Repeat:create(cc.Animate:create(animation), 2000000000)
	end
	self.arrayFrameCount = #arrayFrame

	-- 如果有结束时回调函数
	ani = cc.Sequence:create(ani, cc.CallFunc:create(function()
		self.eventHandler:Trigger('OnPlayAniEnd')
		self._playing = false
	end))

	ani:setTag(config_animate_sprite_tag)
	
	self:runAction(ani)
end

-- 播放

function CCAnimateSprite:Play(nCount, bAsyncLoad, action)
	assert(is_number(nCount))

	if self:GetFrameCount(action) == 0 or self._playing then
		return
	end
	
	self._playing = true
	self._playIndex = self._playIndex + 1
	
	local startTime = utils_get_tick()
	if bAsyncLoad then
		local curIndex = self._playIndex
		local curAniFilePath = self._aniFilePath
		utils_add_image_async(curAniFilePath, function()
			if self:IsValid() and self._playing and self._playIndex == curIndex and self._aniFilePath == curAniFilePath then
				self:_doPlay(nCount, startTime,action)
				self.eventHandler:Trigger('OnAsyncLoadCompelete')
			end
		end)
	else
		self:_doPlay(nCount, startTime,action)
	end
end

-- 停止
function CCAnimateSprite:Stop()
	if self._playing then
		self:stopActionByTag(config_animate_sprite_tag)
		self._playing = false
		return true
	end
end

-- 重新开始播放

function CCAnimateSprite:ReStart(nCount, bAsyncLoad,action)
	self:Stop()
	self:Play(nCount, bAsyncLoad,action)
end

-- 设置当前帧数

function CCAnimateSprite:SetCurFrame(index, bAsyncLoad)
	local fn = self._frame_paths[index]

	if not fn then
		return
	end

	self:SetAniSptDisplayFrameByPath(self._plist, fn, bAsyncLoad)
end

-- 获取总帧数
function CCAnimateSprite:GetFrameCount(action)
	if is_valid_str(action) then
		local action_frame_paths = self._action2framepaths[action]
		if action_frame_paths then
			return #action_frame_paths
		end
		return 0
	end
	return #self._frame_paths
end

-- 获取总播放时长
function CCAnimateSprite:GetPlayDuration(action)
	return self:GetFrameCount(action) * self._frameDelay
end
