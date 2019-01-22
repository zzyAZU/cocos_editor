local constant_uisystem = g_constant_conf.constant_uisystem

local constant = g_constant_conf.constant_uisystem

--部位默认信息
--部位名字，部位幅度
local ALL_DEFAULT_PARTS_INFOS = {
    {constant.LIVE_2D_PARTS.PARAM_ANGLE_X, 30},
    {constant.LIVE_2D_PARTS.PARAM_ANGLE_Y, 30},
    {constant.LIVE_2D_PARTS.PARAM_BODY_X, 10},
    {constant.LIVE_2D_PARTS.PARAM_EYE_BALL_X, 0.3},
    {constant.LIVE_2D_PARTS.PARAM_EYE_BALL_Y, 0.3},
}

local DurationTime = 6

--解析model.json文件，live2d的描述文件
local function _parseModelConfig(modelPath)

    local ret_model_config = {}
    local fileStr = g_fileUtils:getStringFromFile(modelPath)
    if not is_valid_str(fileStr) then
        return false
    end
    local plistConf = luaext_json_dencode(fileStr)
    if not is_table(plistConf) then
        return false
    end
    local basePath, _ = string.match(modelPath, '(.*)/.*.json')
    local mocPath
    local texturePaths = {}
    if plistConf['textures'] and plistConf['model'] then
        local localModelPath = plistConf['model']
        mocPath = string.format('%s/%s', basePath, localModelPath)

        if not g_fileUtils:isFileExist(mocPath) then
            return false
        end

        for _, localTexturePath in ipairs(plistConf['textures']) do
            local texturePath = string.format("%s/%s", basePath, localTexturePath)
            if not g_fileUtils:isFileExist(texturePath) then
                return false
            end
            table.insert(texturePaths, texturePath)
        end
    else
        return false
    end
    ret_model_config.mocPath = mocPath
    ret_model_config.texturePaths = texturePaths
    ret_model_config.motions = {}
    local motionConfigs = plistConf.motions
    for motionName, motionFiles in pairs(motionConfigs or {}) do
        local files = {}
        for _, fileConfig in ipairs(motionFiles) do
            table.insert(files, string.format("%s/%s", basePath, fileConfig.file))
        end

        if #files > 0 and is_valid_str(motionName) then
            ret_model_config.motions[motionName] = files
        end
    end
    ret_model_config.modelPath = modelPath
    return true, ret_model_config
end

function cc.Live2DSprite:Create(modelPath, isAsyn)
    if isAsyn == nil then
        isAsyn = true
    end
    local is_valid, ret_model_config = _parseModelConfig(modelPath)
    if not is_valid then
        return nil
    end
    local ret = nil
    if isAsyn then
        ret = self:create(ret_model_config.mocPath):CastTo(self):_init()
        ret.model_config = ret_model_config
        ret:LoadTextureAsyn()
    else
        ret = self:create(ret_model_config.mocPath, ret_model_config.texturePaths):CastTo(self):_init()
        ret.model_config = ret_model_config
    end
    return ret
end

--异步设置纹理
function cc.Live2DSprite:LoadTextureAsyn(callback)
    if not self.model_config or not self.model_config.texturePaths or #self.model_config.texturePaths <= 0 then
        return
    end
    local loadedCount = 0
    local totalCount = #self.model_config.texturePaths
    for _, path in ipairs(self.model_config.texturePaths) do
        utils_add_image_async(path, function(tex)
            if self:IsValid()then
                loadedCount = loadedCount + 1
                if loadedCount == totalCount then
                    if callback then
                        callback()
                    end
                    self:SetTexturePaths(self.model_config.texturePaths)
                end
            end
        end)
    end
end

function cc.Live2DSprite:SetContentSize(w , h)
    cc.Node.SetContentSize(self, w, h)
    if self.touchLayer and not self._customSize then
        self.touchLayer:SetContentSize(w, h)
    end
end

--换皮
function cc.Live2DSprite:SetModelPath(newModelPath, isAsyn)
    if not self.model_config or self.model_config.modelPath == newModelPath then
        return
    end

    if isAsyn == nil then
        isAsyn = true
    end

    local is_valid, ret_model_config = _parseModelConfig(newModelPath)
    if not is_valid then
        return nil
    end
    self.model_config = ret_model_config

    local originWidth, originHeight = self:GetContentSize()
    self:SetMocPath(self.model_config.mocPath)
    if isAsyn then
        self:LoadTextureAsyn()
    else
        self:SetTexturePaths(self.model_config.texturePaths)
    end
    self:SetContentSize(originWidth, originHeight)
end



--指定播放某个motion
--每个motion可以有多个动作描述文件
function cc.Live2DSprite:PlayMotion(motion, isLoop, isLoopFadeIn, offset, callback)
    if not self.model_config then
        return
    end

    local motionFiles = self.model_config.motions[motion]
    if not motionFiles then
        return
    end
    local motionIds = {}
    for _, motionFile in ipairs(motionFiles) do
        local motionId = self:PlayMotionByFile(motionFile, isLoop, isLoopFadeIn, offset)
        if motionId > 0 then
            table.insert(motionIds, motionId)
        end
    end
    self._currentMotionIds = motionIds

    if self._delayMotionCall then
        self._delayMotionCall()
        self._delayMotionCall = nil
    end

    if callback then
        self._delayMotionCall = self:DelayCall(1, function()
            if self:IsCurrMotionFinish() then
                callback()
                self._delayMotionCall = nil
                return nil
            end
            return 1
        end)
    end
    return motionIds
end

function cc.Live2DSprite:IsCurrMotionFinish()
    if not self._currentMotionIds then
        return true
    end
    for _, motionId in ipairs(self._currentMotionIds or {}) do
        if not self:IsMotionFinish(motionId) then
            return false
        end
    end
    return true
end

--指定播放某个动作描述文件
function cc.Live2DSprite:PlayMotionByFile(motionFile, isLoop, isLoopFadeIn, offset)
    if isLoop == nil then
        isLoop = true
    end
    if isLoopFadeIn == nil then
        isLoopFadeIn = false
    end
    if offset == nil then
        offset = 0
    end
    if not g_fileUtils:isFileExist(motionFile) then
        return -1
    end
    return self:RunMotion(motionFile, isLoop, isLoopFadeIn, offset)
end


--customPartInfos：{
-- [constant.LIVE_2D_PARTS.PARAM_EYE_BALL_X] = {0.1} --第一位是幅度
-- }
--_customSize:自定义触摸大小，默认为自己的大小
function cc.Live2DSprite:EnableDrag(customPartInfos, customSize)
    if not self.SetUpdateCallback then
        return
    end
    
    if self.touchLayer then
        return
    end
    self._customSize = customSize
    local layer = cc.Layer:Create()
    layer:HandleTouchMove(true, false, false, 0, false)
    self._isTouching = false
    self._isWaitingEnd = false
    layer.OnBegin = function(pos)
        if self._isTouching then
            return false
        end
        self._isWaitingEnd = false
        self._isTouching = true
        self:_facePoint(pos.x, pos.y, false)
        return true
    end

    layer.OnDrag = function(pos)
        self:_facePoint(pos.x, pos.y, false)
        return true
    end

    layer.OnEnd = function(pos)
        self._isTouching = false
        self._isWaitingEnd = true
        local posX, posY = self:GetPosition()
        self:_facePoint(posX, posY, true)
        return true
    end

    self:AddChild(nil, layer, 0)
    self.touchLayer = layer
    
    if self._customSize then
        self.touchLayer:setIgnoreAnchorPointForPosition(false)
        self.touchLayer:setAnchorPoint(ccp(0.5, 0.5))
        self.touchLayer:SetContentSize(self._customSize.width, self._customSize.height)
    else
        self.touchLayer:SetContentSize(self:GetContentSize())
    end

    self._allDeltaParamValues = {}
    self._allStartParamValues = {}
    self._allLastParamValues = {}
    self._allMaxParamValues = {}
    
    self._customPartInfos = customPartInfos
    self._currTime = 0
    self._updateHandler = self:SetUpdateCallback(function()
        if self._isTouching or (not self._isTouching and self._isWaitingEnd) then
            self:_updateDragCallback()
        end
    end)
end

function cc.Live2DSprite:DisableDrag()

    if self.touchLayer then
        self:removeChild(self.touchLayer, true)
        self.touchLayer = nil
    end

    if self._updateHandler then
        self:RemoveUpdateCallback(self._updateHandler)
        self._updateHandler = nil
    end
    
    self._customSize = nil
end

function cc.Live2DSprite:_facePoint(x, y, isStop)

    local localPos = self:convertToNodeSpaceAR(ccp(x, y))
    local width ,height = self:GetContentSize()

    if localPos.x > 0 then
        localPos.x = math.min(localPos.x, width/2)
    else
        localPos.x = math.max(localPos.x, -1 * width/2)
    end

    if localPos.y > 0 then
        localPos.y = math.min(localPos.y, height/2)
    else
        localPos.y = math.max(localPos.y, -1 * height/2)
    end

    local maxTargetRateX = localPos.x * 2 / width
    local maxTargetRateY = localPos.y * 2 / height

    
    for index = 1, #ALL_DEFAULT_PARTS_INFOS do
        local partName = ALL_DEFAULT_PARTS_INFOS[index][1]
        local currParamValue = self:GetParamFloat(partName)
        local maxPartParamValue = ALL_DEFAULT_PARTS_INFOS[index][2]
        if self._customPartInfos and self._customPartInfos[partName] then
            maxPartParamValue = self._customPartInfos[partName][1]
        end
        local isX = string.find(partName,'_X')
        local isY = string.find(partName,'_Y')
        if isX then
            local maxTargetParamValue = maxPartParamValue * maxTargetRateX
            self._allDeltaParamValues[partName] = (maxTargetParamValue - currParamValue) / DurationTime
        elseif isY then
            local maxTargetParamValue = maxPartParamValue * maxTargetRateY
            self._allDeltaParamValues[partName] = (maxTargetParamValue - currParamValue) / DurationTime
        else
            self._allDeltaParamValues[partName] = 0
        end
        
        self._allStartParamValues[partName] = currParamValue
        self._allLastParamValues[partName] = currParamValue
        self._allMaxParamValues[partName] = maxPartParamValue

    end

    self._currTime = 0
    self._isStop = isStop

    
end

function cc.Live2DSprite:_updateDragCallback()

    self._currTime = self._currTime + 1
    if self._currTime > DurationTime and self._isStop then
        self._isWaitingEnd = false
        return
    end
    self._currTime = math.min(self._currTime, DurationTime)
    for index = 1, #ALL_DEFAULT_PARTS_INFOS do
        local partName = ALL_DEFAULT_PARTS_INFOS[index][1]
        local currParamValue = self:GetParamFloat(partName)
        if currParamValue == self._allLastParamValues[partName] then
            self:AddToParamFloat(partName, self._allDeltaParamValues[partName] or 0)
         else
            local targetParamValue = self._allDeltaParamValues[partName] * self._currTime + self._allStartParamValues[partName] + currParamValue
            self:SetParamFloat(partName, targetParamValue)
        end
        currParamValue = self:GetParamFloat(partName)
        if currParamValue > 0 then
            currParamValue = math.min(currParamValue, self._allMaxParamValues[partName])
        else
            currParamValue = math.max(currParamValue, -1 * self._allMaxParamValues[partName])
        end

        self:SetParamFloat(partName, currParamValue)
        self._allLastParamValues[partName] = currParamValue
    end
end
