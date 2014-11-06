Align = "Left"

OnInitialise = function(self, node)
	local attr = self.Attributes
	if attr.align then
		if attr.align:lower() == 'left' or attr.align:lower() == 'right' then
			self.Align = attr.align:lower():gsub("^%l", string.upper)
		end
	end
end

OnCreateObject = function(self, parentObject, y)
	return {
		Element = self,
		Y = y,
		X = 1,
		Width = self.Width,
		Height = self.Height,
		Align = self.Align,
		BackgroundColour = self.BackgroundColour,
		Type = "FloatView"
	}
end