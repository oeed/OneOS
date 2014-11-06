Inherit = 'View'
Height = 3

OnLoad = function(self)
	self:OnUpdate('Text')
end

OnUpdate = function(self, value)
	if value == 'Text' then
		self:RemoveAllObjects()
		self:AddObject({
			Y = 1,
			X = 1,
			Width = "100%",
			Align = "Center",
			Type = "Label",
			Text = self.Text,
			TextColour = self.TextColour,
			BackgroundColour = self.BackgroundColour
		})

		local underline = ''
		for i = 1, #self.Text + 2 do
			underline = underline .. '='
		end
		self:AddObject({
			Y = 2,
			X = 1,
			Width = "100%",
			Align = "Center",
			Type = "Label",
			Text = underline,
			TextColour = self.TextColour,
			BackgroundColour = self.BackgroundColour
		})
	end
end