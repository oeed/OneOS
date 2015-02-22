Width = 9

Toggle = false

OnDraw = function(self, x, y)
	local _x = 0

	local onColour = self.Toggle and colours.green or colours.lightGrey
	Drawing.DrawCharacters(x, y, ' On ', colours.white, onColour)

	local offColour = self.Toggle and colours.lightGrey or colours.red
	Drawing.DrawCharacters(x + 4, y, ' Off ', colours.white, offColour)
end

OnClick = function(self, event, side, x, y)
	if x >= 5 then
		self.Toggle = false
	else
		self.Toggle = true
	end

	if self.OnChange then
		self:OnChange(self.Toggle)
	end
end