Inherit = 'TextBox'

FilterName = nil
TextFilterName = nil

OnLoad = function(self)
	if not self.CursorPos then
		self.CursorPos = #self.Text
	end
	
	self:OnUpdate('FilterName')
	self:OnUpdate('TextFilterName')
end


OnDraw = function(self, x, y)
	local filter = self.Filter
	local textFilter = self.TextFilter or filter
	for _x = 1, self.Width do
		for _y = 1, self.Height do
			if Drawing.Buffer[y + _y - 1] and Drawing.Buffer[y + _y - 1][x + _x - 1] then
				local px = Drawing.Buffer[y + _y - 1][x + _x - 1]
				Drawing.WriteToBuffer(x + _x - 1, y + _y - 1, ' ', Drawing.FilterColour(px[2], textFilter), Drawing.FilterColour(px[3], filter))
			end
		end
	end

	local function textColour(_x, _y)
		if Drawing.Buffer[_y] and Drawing.Buffer[_y][_x] then
			local px = Drawing.Buffer[_y][_x]
			return Drawing.FilterColour(px[3], textFilter)
		end
	end

	if self.CursorPos > #self.Text then
		self.CursorPos = #self.Text
	elseif self.CursorPos < 0 then
		self.CursorPos = 0
	end
	local text = self.Text
	local offset = self:TextOffset()
	if #text > (self.Width - 2) then
		text = text:sub(offset+1, offset + self.Width - 2)
		-- self.Bedrock.CursorPos = {x + 1 + self.Width-2, y}
	-- else
	end
	if self.Bedrock:GetActiveObject() == self then
		-- error(y)
		self.Bedrock.CursorPos = {x + 1 + self.CursorPos - offset - objOffset.X, y}
		self.Bedrock.CursorColour = textColour(x + 1 + self.CursorPos - offset, y)
	else
		self.Selected = false
	end

	if #tostring(text) == 0 then
		Drawing.DrawCharacters(x + 1, y, self.Placeholder, self.PlaceholderTextColour, colours.transparent)
	else
		if not self.Selected then
			Drawing.DrawCharacters(x + 1, y, text, textColour(x + 1, y), colours.transparent)
		else
			local startPos = self.DragStart - offset
			local endPos = self.CursorPos - offset
			if startPos > endPos then
				startPos = self.CursorPos - offset
				endPos = self.DragStart - offset
			end
			for i = 1, #text do
				local char = text:sub(i, i)
				local tc = textColour(x + i, y)
				local backgroundColour = colours.transparent

				if i > startPos and i - 1 <= endPos then
					tc = self.SelectedTextColour
					backgroundColour = self.SelectedBackgroundColour
				end
				Drawing.DrawCharacters(x + i, y, char, tc, backgroundColour)
			end
		end
	end
end

OnUpdate = function(self, value)
	if value == 'FilterName' then
		self.Filter = Drawing.Filters[self.FilterName or 'None']
	elseif value == 'TextFilterName' then
		self.TextFilter = Drawing.Filters[self.TextFilterName]
	end
end