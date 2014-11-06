OnCreateObject = function(self, parentObject, y)
	return {
		Element = self,
		Y = y,
		X = 1,
		Width = "100%",
		Height = self.Height,
		BackgroundColour = self.BackgroundColour,
		Type = "CenterView"
	}
end