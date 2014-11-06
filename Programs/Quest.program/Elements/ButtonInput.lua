BackgroundColour = colours.lightGrey
TextColour = colours.black
Text = 'Submit'
InputName = ''

OnInitialise = function(self, node)
	local attr = self.Attributes
	if attr.value then
		self.Text = attr.value
	end

	if attr.name then
		self.InputName = attr.name
	end

	if not attr.width then
		self.Width = #self.Text + 2
	end
end

UpdateValue = function(self, force)
	if force then
		self.Value = self.Object.Text
	end
end

CreateObject = function(self, parentObject, y)
	return parentObject:AddObject({
		Element = self,
		Y = y,
		X = 1,
		Width = self.Width,
		Type = "Button",
		Text = self.Text,
		TextColour = self.TextColour,
		BackgroundColour = self.BackgroundColour,
		InputName = self.InputName,
		OnClick = function(_self, event, side, x, y)
			local form = self
			local step = 0
			while form.Tag ~= 'form' and step < 50 do
				form = form.Parent
			end
			self.Value = _self.Text
			if form and form.Submit then
				form:Submit()
			end
		end
	})
end