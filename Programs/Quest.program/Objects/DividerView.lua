Inherit = 'View'
Char = nil

OnDraw = function(self, x, y)
	if self.BackgroundColour then
		if self.Char then
			Drawing.DrawArea (x, y, self.Width, self.Height, self.Char, self.TextColour, self.BackgroundColour)
		else
			Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
		end
	end
end