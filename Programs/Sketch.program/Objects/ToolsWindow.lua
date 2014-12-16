Inherit = 'SnapWindow'
ContentViewName = 'toolswindow'

Title = 'Tools'

OnContentLoad = function(self)
	local buttons = self:GetObjects('ToolButton')
	for i, button in ipairs(buttons) do
		button.OnClick = function(_self, event, side, x , y)
			local artboard = self.Bedrock:GetObject('Artboard')
			if artboard then
				artboard:SetTool(getfenv()[button.ToolName])
			end
		end
	end
end