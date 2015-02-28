Inherit = 'PageView'

OnPageLoad = function(self)
	self:GetObject('NoButton').OnClick = function()
		self.Bedrock.SettingsValues.UseAnimations = false
		self.Bedrock:NextPage()
	end

	self:GetObject('YesButton').OnClick = function()
		self.Bedrock.SettingsValues.UseAnimations = true
		self.Bedrock:NextPage()
	end
end