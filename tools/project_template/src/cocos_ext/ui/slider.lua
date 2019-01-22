--[[
    CCSlider
]]
local constant_uisystem = g_constant_conf.constant_uisystem

local CCSlider, Super = tolua_get_class('CCSlider')

-- override
function CCSlider:Create(template_path)
    return g_uisystem.load_template_create(template_path):CastTo(self):_init()
end

-- override
function CCSlider:_init()
    Super._init(self)

    self._current_percentage = 0              -- 当前进度 默认0  范围是0 - 100

    self:_updateCurrentSlider()
    return self
end

--override
function CCSlider:_registerInnerEvent()
    Super._registerInnerEvent(self)
    
    self.OnBegin = function(pt)
        self:_updatePercentageByMove(pt)
        return true
    end

    self.OnEnd = function(pt)
        self:_updatePercentageByMove(pt)
    end

    self.OnDrag = function(pt)
        self:_updatePercentageByMove(pt)
    end
end

function CCSlider:SetContentSize(sw, sh)
    local size = Super.SetContentSize(self, sw, sh)
    if self['_spriteBg_'] then
        self['_spriteBg_']:SetContentSize(size.width, size.height)
        self['_spriteBg_']:SetPosition('50%', '50%')
    end

    if self['_spriteProgress_'] then
        self['_spriteProgress_']:SetPosition('0', '50%')
    end

    if self['_buttonSlider_'] then
        self['_buttonSlider_']:SetPosition('100%', '50%')
    end

    self:_updateCurrentSlider()
    return size
end

-- 设置当前百分比
function CCSlider:setPercent(percentage)
    self._current_percentage = percentage
    self:_updateCurrentSlider()
end

-- 刷新当前的slider
function CCSlider:_updateCurrentSlider()

    self:_updateRoolBallPosition()
end

-- 更新当前百分比
function CCSlider:_updatePercentageByMove(pt)

    local width, height = self:GetContentSize()
    local point = self:convertToNodeSpace(pt)
    local percentage = math.floor(point.x/width * 100)
    if percentage < 0 then
        percentage = 0
    end
    if percentage > 100 then
        percentage = 100
    end
    self._current_percentage = percentage
    self:_updateRoolBallPosition()
end

-- 更新滚动小球的位置
function CCSlider:_updateRoolBallPosition()

    local width, height = self:GetContentSize()
    local widthNew = self._current_percentage * width / 100
    if self['_spriteProgress_'] then
        self['_spriteProgress_']:SetContentSize(widthNew, height)
    end
    if self['_buttonSlider_'] then
        self['_buttonSlider_']:SetPosition(widthNew, '50%')
    end
end