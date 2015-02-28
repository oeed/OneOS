Inherit = 'PageView'

OnPageLoad = function(self)
	self:GetObject('DesktopColourPicker').OnChange = function()
		self.Bedrock.View.BackgroundColour = self:GetObject('DesktopColourPicker').ActiveColour
	end
end

OnNext = function(self)
	self.Bedrock.SettingsValues.DesktopColour = self:GetObject('DesktopColourPicker').ActiveColour
end