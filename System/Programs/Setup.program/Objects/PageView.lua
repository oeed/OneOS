Inherit = 'ScrollView'

OnLoad = function(self)
	ScrollView.OnLoad(self)

	local back = self:GetObject('BackButton')

	if back then
		back.OnClick = function()
			self.Bedrock:PreviousPage()
		end
	end


	local next = self:GetObject('NextButton')
	if next then
		next.OnClick = function()
			if self.OnNext then
				self:OnNext()
			end
			
			self.Bedrock:NextPage()
		end
	end

	if self.OnPageLoad then
		self:OnPageLoad()
	end
end