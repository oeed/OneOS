Width = 20
InputName = ''

OnInitialise = function(self, node)
	if attr.value then
		new.Text = attr.value
	end

	if attr.name then
		new.InputName = attr.name
	end
end

UpdateValue = function(self)
	self.Value = self.Object.MenuItems[self.Object.Selected].Value
end

OnCreateObject = function(self, parentObject, y)
	return {
		Element = self,
		Y = y,
		X = 1,
		Width = self.Width,
		Type = "SelectView",
		TextColour = self.TextColour,
		BackgroundColour = self.BackgroundColour,
		InputName = self.InputName,
	}
end