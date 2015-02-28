Inherit = 'PageView'

OnNext = function(self)
	for k, v in pairs(self.Bedrock.SettingsValues) do
		self.Bedrock.Settings[k] = v
	end

	System.AnimateShutdown(true, true)
end