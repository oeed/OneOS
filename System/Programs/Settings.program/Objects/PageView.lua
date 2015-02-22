Inherit = 'ScrollView'

OnLoad = function(self)
	ScrollView.OnLoad(self)

	if self.OnPageLoad then
		self:OnPageLoad()
	end
end