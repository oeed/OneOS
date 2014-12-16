Inherit = 'View'

BackgroundColour = colours.transparent
TextColour = colours.black
Height = 3
Image = nil
Enabled = true

OnLoad = function(self)
	self.Image = Drawing.LoadImage('Resources/filterPreview.nft')

	self:AddObject({
		X = 6,
		Y = 1,
		Text = self.FilterName,
		Type = 'Label',
		BackgroundColour = colours.transparent,
		TextColour = self.TextColour
	})
end

OnDraw = function(self, x, y)
	if self.BackgroundColour then
		Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
	end

	local filter = Drawing.Filters[self.Filter]
	if not filter then
		filter = Drawing.Filters.None
	end

	for _y = 1, #self.Image do
		for _x = 1, #self.Image[_y] do
			local bgColour = Drawing.FilterColour(self.Image[_y][_x], filter)
            local textColour = Drawing.FilterColour(self.Image.textcol[_y][_x] or colours.white, filter)
            local char = self.Image.text[_y][_x]
            Drawing.WriteToBuffer(x+_x, y+_y-1, char, textColour, bgColour)
		end
	end
end

OnClick = function(self, event, side, x, y)
	if self.Enabled then
		local artboard = self.Bedrock:GetObject('Artboard')
		if artboard then
			artboard:CreateLayer(self.FilterName .. ' Filter', colours.white, 'Filter:' .. self.Filter)
		end
	end
end