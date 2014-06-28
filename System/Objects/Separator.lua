Colour = colours.grey

OnDraw = function(self, x, y)
	local char = "|"
	if self.Width > self.Height then
		char = '-'
	end
	Drawing.DrawArea(x, y, self.Width, self.Height, char, self.Colour, colours.transparent)
end