Char = nil

OnInitialise = function(self, node)
	local attr = self.Attributes
	self.Text = self.Text or ''
	if attr.char then
		if #attr.char == 1 then
			self.Char = attr.char
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
		BackgroundColour = self.BackgroundColour,
		TextColour = self.TextColour,
		Type = "DividerView",
		Char = self.Char
	}
end