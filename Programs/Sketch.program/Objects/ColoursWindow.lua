Inherit = 'SnapWindow'
ContentViewName = 'colourswindow'

Title = 'Colours'

OnContentLoad = function(self)
	local artboard = self.Bedrock:GetObject('Artboard')
	if artboard then
		self:GetObject('PrimaryColourButton').BackgroundColour = artboard.BrushColour
		self:GetObject('SecondaryColourButton').BackgroundColour = artboard.SecondaryBrushColour
	else
		self:GetObject('PrimaryColourButton').BackgroundColour = colours.lightBlue
		self:GetObject('SecondaryColourButton').BackgroundColour = colours.magenta
	end

	local buttons = self:GetObjects('ColourButton')
	for i, button in ipairs(buttons) do
		button.OnClick = function(_self, event, side, x , y)
			local artboard = self.Bedrock:GetObject('Artboard')
			if artboard then
				if side == 1 then
					artboard:SetBrushColour(button.BackgroundColour)
					self:GetObject('PrimaryColourButton').BackgroundColour = button.BackgroundColour
				elseif side == 2 then
					artboard:SetSecondaryBrushColour(button.BackgroundColour)
					self:GetObject('SecondaryColourButton').BackgroundColour = button.BackgroundColour
				end
			end
		end
	end
end