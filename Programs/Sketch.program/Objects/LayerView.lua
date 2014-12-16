Inherit = 'View'

BackgroundColour = colours.transparent
ActiveBackgroundColour = colours.blue
ActiveTextColour = colours.white
Height = 3
DragStart = nil
DragTimer = nil


OnLoad = function(self)
	self:AddObject({
		X = 2,
		Y = 1,
		Width = 1,
		AutoWidth = false,
		Text = (self.Layer.Visible and '@' or '*'),
		Type = 'Button',
		Name = 'VisibleButton',
		BackgroundColour = colours.transparent,
		ActiveBackgroundColour = colours.transparent,
		TextColour = colours.grey,
		ActiveTextColour = colours.black,
		Toggle = self.Layer.Visible,
		OnClick = function(_self)
			if _self.Toggle then
				_self.Text = '@'
			else
				_self.Text = '*'
			end
			self.Layer.Layer.Visible = _self.Toggle
			self.Layer.Visible = _self.Toggle
		end
	})

	self:AddObject({
		X = 2,
		Y = 2,
		Width = 1,
		AutoWidth = false,
		Text = 'X',
		Type = 'Button',
		Name = 'DeleteButton',
		BackgroundColour = colours.transparent,
		ActiveBackgroundColour = colours.transparent,
		TextColour = colours.red,
		OnClick = function(_self)
			self.Layer:DeleteLayer()
		end
	})

	self:AddObject({
		X = 9,
		Y = 1,
		Text = self.Layer.Layer.Name,
		Type = 'Label',
		Name = 'LayerNameLabel',
		BackgroundColour = colours.transparent,
		TextColour = colours.black
	})
end

OnDraw = function(self, x, y)
	local artboard = self.Bedrock:GetObject('Artboard')

	local isActive = (artboard and artboard:GetCurrentLayer() == self.Layer)

	if isActive then
		Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.ActiveBackgroundColour)
		self:GetObject('VisibleButton').TextColour = colours.lightGrey
		self:GetObject('VisibleButton').ActiveTextColour = colours.white
		self:GetObject('DeleteButton').TextColour = colours.white
		self:GetObject('LayerNameLabel').TextColour = colours.white
	else
		Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
		self:GetObject('VisibleButton').TextColour = colours.grey
		self:GetObject('VisibleButton').ActiveTextColour = colours.black
		self:GetObject('DeleteButton').TextColour = colours.red
		self:GetObject('LayerNameLabel').TextColour = colours.black
	end

	local previewX = 3
	local previewY = 0
	for _x = 1, 3 do
		local odd = (_x % 2) == 1
		for _y = 1, 2 do
			if odd then
				Drawing.WriteToBuffer(previewX + x + _x - 1, previewY + y + _y - 1, ":", colours.lightGrey, colours.white)
			else
				Drawing.WriteToBuffer(previewX + x + _x - 1, previewY + y + _y - 1, ":", colours.white, colours.lightGrey)
			end
			odd = not odd
		end
	end

	for _x, col in ipairs(self.Layer:GetZoomPixels(3, 2)) do
		for _y, pixel in ipairs(col) do
			if pixel.Character ~= ' ' or pixel.BackgroundColour ~= colours.transparent then
				Drawing.WriteToBuffer(previewX + x + _x - 1, previewY + y + _y - 1, pixel.Character, pixel.TextColour, pixel.BackgroundColour)
			end
		end
	end

	local splitterColour = colours.lightGrey


	Drawing.DrawArea(x, y  + self.Height - 1, self.Width, 1, '-', (isActive and colours.white or colours.lightGrey), colours.transparent)

end

OnClick = function(self, event, side, x, y)
	if side == 1 then
		self.DragStart = y

		local artboard = self.Bedrock:GetObject('Artboard')
		if artboard then
			artboard:SetCurrentLayer(self.Layer)
		end
	elseif side == 2 then
		if self:ToggleMenu('layermenu', x, y) then
			local artboard = self.Bedrock:GetObject('Artboard')
			if artboard then
				self.Bedrock:GetObject('NewLayerMenuItem').OnClick = function()
					artboard:NewLayer()
				end
				self.Bedrock:GetObject('RenameLayerMenuItem').OnClick = function()
					self.Layer:RenameLayer()
				end
				self.Bedrock:GetObject('DeleteLayerMenuItem').OnClick = function()
					self.Layer:DeleteLayer()
				end
				self.Bedrock:GetObject('DuplicateLayerMenuItem').OnClick = function()
					artboard:DuplicateLayer(self.Layer.Layer)
				end
				self.Bedrock:GetObject('MergeDownLayerMenuItem').OnClick = function()
					self.Layer:MergeDown()
				end
			end
		end
	end
end


OnDrag = function(self, event, side, x, y)
	if self.DragStart then
		local deltaY = y - self.DragStart
		self.Y = self.Y + deltaY
		self.Parent.Parent.Parent:Rearrange(self, y)
	end

	self.DragTimer = self.Bedrock:StartTimer(function(_, timer)
		if timer == self.DragTimer then
			self.Parent.Parent.Parent:OrderLayers()
			self.Parent.Parent.Parent:UpdateLayers()
			self.DragStart = nil
			self.DragTimer = nil
		end
	end, 1)
end