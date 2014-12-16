Inherit = 'SnapWindow'
ContentViewName = 'brushwindow'

Title = 'Brush'

OnContentLoad = function(self)
	self:GetObject('SquareImageView').OnClick = function(_self, event, side, x, y)
		local artboard = self.Bedrock:GetObject('Artboard')
		if artboard then
			artboard.BrushShape = 'Square'
		end
	end

	self:GetObject('CircleImageView').OnClick = function(_self, event, side, x, y)
		local artboard = self.Bedrock:GetObject('Artboard')
		if artboard then
			artboard.BrushShape = 'Circle'
		end
	end

	local artboard = self.Bedrock:GetObject('Artboard')
	if artboard then
		self:GetObject('NumberBox').Value = artboard.BrushSize
	end

	self:GetObject('NumberBox').OnChange = function(_self)
		local artboard = self.Bedrock:GetObject('Artboard')
		if artboard then
			artboard.BrushSize = _self.Value
		end
	end
end