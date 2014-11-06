Align = "Center"

OnInitialise = function(self, node)
	local attr = self.Attributes
	self.Text = self.Text or ''
	if attr.align then
		if attr.align:lower() == 'left' or attr.align:lower() == 'center' or attr.align:lower() == 'right' then
			self.Align = attr.align:lower():gsub("^%l", string.upper)
		end
	end
end

OnCreateObject = function(self, parentObject, y)
	return {
		Element = self,
		Y = y,
		X = 1,
		Width = "100%",
		Align = self.Align,
		Type = "HeadingView",
		Text = self.Text,
		TextColour = self.TextColour,
		BackgroundColour = self.BackgroundColour
	}
end