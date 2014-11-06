Inherit = 'TextInput'

UpdateValue = function(self)
	self.Value = hash.sha256(self.Object.Text)
end

OnCreateObject = function(self, parentObject, y)
	return {
		Element = self,
		Y = y,
		X = 1,
		Width = self.Width,
		Type = "SecureTextBox",
		Text = self.Value,
		TextColour = self.TextColour,
		BackgroundColour = self.BackgroundColour,
		SelectedBackgroundColour = self.SelectedBackgroundColour,
		SelectedTextColour = self.SelectedTextColour,
		PlaceholderTextColour = self.PlaceholderTextColour,
		Placeholder = self.Placeholder,
		InputName = self.InputName,
		OnChange = function(_self, event, keychar)
			if keychar == keys.tab or keychar == keys.enter then
				local form = self
				local step = 0
				while form.Tag ~= 'form' and step < 50 do
					form = form.Parent
				end
				if keychar == keys.tab then
					if form and form.Object and form.Object.OnTab then
						form.Object:OnTab()
					end
				else
					if form and form.Submit then
						form:Submit(true)
					end
				end
			end
		end
	}
end