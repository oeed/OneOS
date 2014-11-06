Inherit = 'View'
Height = 2
UnderlineColour = colours.blue
UnderlineVisible = true

OnLoad = function(self)
	if self.Text and #self.Text > 0 then
		self:AddObject({
			Y = 1,
			X = 1,
			Width = self.Width,
			Align = self.Align,
			Type = "Label",
			Text = self.Text,
			TextColour = self.TextColour,
			BackgroundColour = self.BackgroundColour
		})
	end
end

OnRecalculateStart = function(self)
	self:RemoveObject('UnderlineLabel')
end

OnRecalculateEnd = function(self, currentY)
	if self.UnderlineVisible then
		local underline = ''
		local len = self.Width
		if self.Text then
			len = #self.Text
		end

		for i = 1, len do
			underline = underline .. '-'
		end
		local col = self.UnderlineColour
		if self.UnderlineColour == nil then
			col = self.TextColour
		end

		local ul = self:AddObject({
			Y = currentY,
			X = 1,
			Width = self.Width,
			Align = self.Align,
			Type = "Label",
			Name = "UnderlineLabel",
			Text = underline,
			TextColour = col,
			BackgroundColour = self.BackgroundColour
		})	
		return currentY + 1
	else
		return currentY
	end
end

OnClick = function(self)
	self.Bedrock:GetObject('WebView'):GoToURL(self.URL)
end