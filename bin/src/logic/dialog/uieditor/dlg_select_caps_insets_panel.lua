--[[
    ui编辑器9宫格选取界面
]]
Panel = g_panel_mgr.new_panel_class('editor/dialog/select_caps_inset_panel')

-- overwrite
function Panel:init_panel(plist, path, capsinsets, callback)
    self:add_key_event_callback('KEY_ESCAPE', function()
        self:close_panel()
    end)

    self._layer.OnClick = function()
        self:close_panel()
    end

    self._plist = plist
    self._path = path
    self._capsinsets = capsinsets
    self._callback = callback

    self.spt:SetPath(self._plist, self._path)


    self._sptW, self._sptH = self.spt:GetContentSize()
    _, self._layerH = self.layerColor:GetContentSize()
    self._scale = self._layerH / self._sptH
    self._layerW = self._sptW * self._scale

    self.spt:setScale(self._scale)
    self.layerColor:SetContentSize(self._layerW, self._layerH)
    self.lineH1:SetContentSize('100%', 0)
    self.lineH2:SetContentSize('100%', 0)
    self.spt:SetPosition('50%', '50%')
    self.lSize:SetString('图像大小:'..self._sptW..' '..self._sptH)
    self:_updateData()

    self.btnHorz1.OnDrag = function(pos)
        y1 = self.layerColor:convertToNodeSpace(pos).y
        _, y2 = self.lineH2:getPosition()

        y1 = y1 < 0 and 0 or y1 > y2 and y2 or y1
        y1 = math.floor(y1 / self._scale + 0.5)
        y2 = math.floor(y2 / self._scale + 0.5)
        self._capsinsets.height = y2 - y1
        self._capsinsets.y = self._sptH - y2
        self:_updateData()
    end

    self.btnHorz2.OnDrag = function(pos)
        y2 = self.layerColor:convertToNodeSpace(pos).y
        _, y1 = self.lineH1:getPosition()

        y2 = y2 < y1 and y1 or y2 > self._layerH and self._layerH or y2
        y1 = math.floor(y1 / self._scale + 0.5)
        y2 = math.floor(y2 / self._scale + 0.5)
        self._capsinsets.height = y2 - y1
        self._capsinsets.y = self._sptH - y2
        self:_updateData()
    end

    self.btnVert1.OnDrag = function(pos)
        x1 = self.layerColor:convertToNodeSpace(pos).x
        x2 = self.lineV2:getPosition()

        x1 = x1 < 0 and 0 or x1 > x2 and x2 or x1
        x1 = math.floor(x1 / self._scale + 0.5)
        x2 = math.floor(x2 / self._scale + 0.5)
        self._capsinsets.width = x2 - x1
        self._capsinsets.x = x1
        self:_updateData()
    end

    self.btnVert2.OnDrag = function(pos)
        x2 = self.layerColor:convertToNodeSpace(pos).x
        x1 = self.lineV1:getPosition()

        x2 = x2 < x1 and x1 or x2 > self._layerW and self._layerW or x2
        x1 = math.floor(x1 / self._scale + 0.5)
        x2 = math.floor(x2 / self._scale + 0.5)
        self._capsinsets.width = x2 - x1
        self._capsinsets.x = x1
        self:_updateData()
    end

    self.btnOK.OnClick = function()
        self._callback(self._capsinsets)
        self:close_panel()
    end
end

function Panel:_updateData()
    if self._capsinsets.x == 0 and
        self._capsinsets.y == 0 and
        self._capsinsets.width == 0 and
        self._capsinsets.height == 0 then
        self._capsinsets.x, self._capsinsets.y, self._capsinsets.width, self._capsinsets.height = math.floor(self._sptW / 3 + 0.5), math.floor(self._sptH / 3 + 0.5), math.floor(self._sptW / 3 + 0.5), math.floor(self._sptH / 3 + 0.5)
    end
    self.lCapsInsets:SetString(self._capsinsets.x..' '..self._capsinsets.y..' '..self._capsinsets.width..' '..self._capsinsets.height)
    local X = self._capsinsets.x * self._scale
    local Y = self._capsinsets.y * self._scale
    local W = self._capsinsets.width * self._scale
    local H = self._capsinsets.height * self._scale


    self.lineH1:SetPosition('50%', self._layerH - Y - H)
    self.lineH2:SetPosition('50%', self._layerH - Y)
    self.lineV1:SetPosition(X, '50%')
    self.lineV2:SetPosition(X + W, '50%')
end