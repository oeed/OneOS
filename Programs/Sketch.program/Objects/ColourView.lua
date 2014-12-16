OnDraw = function(self, x, y)
	if self.BackgroundColour ~= colours.transparent then
		Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
	else
		for _x = 1, self.Width do
			local odd = (_x % 2) == 0
			for _y = 1, self.Height do
				if odd then
					Drawing.WriteToBuffer(x + _x - 1, y + _y - 1, ":", colours.lightGrey, colours.white)
				else
					Drawing.WriteToBuffer(x + _x - 1, y + _y - 1, ":", colours.white, colours.lightGrey)
				end
				odd = not odd
			end
		end
	end
end