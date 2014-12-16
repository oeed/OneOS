Inherit = 'View'

BackgroundColour = colours.grey
FlashingColour = colours.lightBlue
Z = 101
Flashing = false

OnDraw = function(self, x, y)
	local bgColour = self.BackgroundColour
	if self.Flashing then
		bgColour = self.FlashingColour
	end
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, bgColour)
end

UpdateButtons = function(self, enabled)
	for i, v in ipairs(self.Children) do
		v.Enabled = enabled
	end
end

CloseDocked = function(self)
	for i, v in ipairs(self.Children) do
		if v.WindowDocked then
			v.Window:Close()
		end
	end
end

OnDock = function(self)
	self.Flashing = true
	self.Bedrock:StartTimer(function()
		self.Flashing = false
	end, 0.2)
end