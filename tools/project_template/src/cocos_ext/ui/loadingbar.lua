local constant_uisystem = g_constant_conf.constant_uisystem

local config_loadingbar_ani_delt = 0.05
local config_loadingbar_ani_tag = 10001
local CCLoadingBar, Super = tolua_get_class('CCLoadingBar')

function CCLoadingBar:Create()
    return cc.Node:create():CastTo(self):_init()
end

function CCLoadingBar:_init()
	Super._init(self)

	self._percent = 0
	self._direction = constant_uisystem.LOADING_BAR_DIRECTION.LEFT

	return self
end

function CCLoadingBar:loadTexture(texturePath)
	if self._texturePath == texturePath then
		return
	end
	self._texturePath = texturePath
	if not self._barRenderer then
		self._barRenderer = cc.Sprite:Create(nil, texturePath)
		self:AddChild("", self._barRenderer, 1)
	else
		self._barRenderer:SetPath(nil, texturePath, true)
	end
	
	self._barRenderer:setAnchorPoint(ccp(0, 0.5))
	self._barRendererTextureWidth, self._barRendererTextureHeight = self._barRenderer:GetContentSize()
end

function CCLoadingBar:setScale9Enabled(scale9Enabled)
	if self._scale9Enabled == scale9Enabled then
		return
	end
	self._scale9Enabled = scale9Enabled
	self._barRenderer:setStretchEnabled(self._scale9Enabled)

end

function CCLoadingBar:setCapInsets(capInsets)
	self._capInsets = capInsets
	self._barRenderer:setCenterRect(capInsets)
end

function CCLoadingBar:setDirection(direction)
	if self._direction == direction then
		return
	end
	self._direction = direction

	if self._direction == constant_uisystem.LOADING_BAR_DIRECTION.LEFT then
		self._barRenderer:setAnchorPoint(ccp(0, 0.5))
	else
		self._barRenderer:setAnchorPoint(ccp(1, 0.5))
	end

	self:_adjustPosition()
	self:_handleFlip()
end

function CCLoadingBar:SetPercentage(target_percent, time, finish_cb, tick_cb)
	if time == nil or time <= 0 then
        self:setPercent(target_percent)
        return
    end

    local cur_percent = self:getPercent()
    local startTime = utils_get_tick()

    local function _update()
        local lastTime = utils_get_tick() - startTime
        if lastTime < time then
            local percent = cur_percent + (target_percent - cur_percent) * lastTime / time
            self:setPercent(percent, false)
            if tick_cb then
                tick_cb(percent, lastTime)
            end
            return config_loadingbar_ani_delt
        else
            self:setPercent(target_percent, false)
            if finish_cb then
                finish_cb()
            end
        end
    end

    self:stopActionByTag(config_loadingbar_ani_tag)
    self:DelayCallWithTag(config_loadingbar_ani_delt, config_loadingbar_ani_tag, _update)
end

function CCLoadingBar:setPercent(percent, isstop)

	if isstop == nil then
		isstop = true
	end

	if percent > 100 then
		percent = 100
	elseif percent <= 0 then
		percent = 0
	end

	if self._percent == percent then
		return
	end

	if isstop then
		self:stopActionByTag(config_loadingbar_ani_tag)
	end
	self._percent = percent

	self:_updateProgressBar()
end


--这里和引擎有点不一样
function CCLoadingBar:SetContentSize(sw, sh)
	local size = Super.SetContentSize(self, sw, sh)
	self:_updateProgressBar()
    return size
end

function CCLoadingBar:getPercent()
	return self._percent
end


function CCLoadingBar:_adjustSizeWithScale(targetWidth, targeteHeight)
	if self._barRendererTextureWidth == 0 or self._barRendererTextureHeight == 0 then
    	self._barRenderer:setScale(1)
	else
		local scaleX = targetWidth / self._barRendererTextureWidth
		local scaleY = targeteHeight / self._barRendererTextureHeight
		self._barRenderer:setScaleX(scaleX)
		self._barRenderer:setScaleY(scaleY)
    end
end

function CCLoadingBar:_adjustSizeWithOutScale(targetWidth, targeteHeight)
	self._barRenderer:setScale(1)
    self._barRenderer:SetContentSize(targetWidth, targeteHeight);
end

function CCLoadingBar:_adjustPosition()
	local selfWidth, selfHeight = self:GetContentSize()
	if self._direction == constant_uisystem.LOADING_BAR_DIRECTION.LEFT then
		self._barRenderer:SetPosition(0, selfHeight / 2)
	else
		self._barRenderer:SetPosition(selfWidth, selfHeight / 2)
	end
end

function CCLoadingBar:_handleFlip()
	if self._direction == constant_uisystem.LOADING_BAR_DIRECTION.LEFT then
		self._barRenderer:setFlippedX(false)
	else
		self._barRenderer:setFlippedX(true)
	end
end

function CCLoadingBar:_updateProgressBar()
	local selfWidth, selfHeight = self:GetContentSize()
    if self._scale9Enabled then
    	local barWidth = selfWidth * self._percent / 100

    	local rect = self._barRenderer:getTextureRect();
    	rect.width = self._barRendererTextureWidth;
    	self._barRenderer:setTextureRect(rect, false, cc.size(rect.width, rect.height));

    	if self._capInsets and (self._capInsets.x ~= 0 or self._capInsets.width ~= 0) then
    		local cap_width = self._capInsets.width
    		local cap_left_right = self._barRendererTextureWidth - cap_width
    		if cap_left_right > barWidth then
    			self:_adjustSizeWithScale(barWidth, selfHeight)
    		else
    			self:_adjustSizeWithOutScale(barWidth, selfHeight)
    		end
    	else
    		self:_adjustSizeWithOutScale(barWidth, selfHeight)
    	end
    	
    else
		local rect = self._barRenderer:getTextureRect();
    	rect.width = self._barRendererTextureWidth * self._percent / 100;

    	self._barRenderer:setTextureRect(rect, false, cc.size(rect.width, rect.height));

    	self:_adjustSizeWithScale(selfWidth, selfHeight)
    end

    self:_adjustPosition()
end
