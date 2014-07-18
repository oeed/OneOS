BackgroundColour = colours.lightGrey
BarColour = colours.blue
TextColour = colours.white
ShowText = false
Value = 0
Maximum = 1

OnDraw = function(self, x, y)
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)

	local values = self.Value
	local barColours = self.BarColour
	if type(values) == 'number' then
		values = {values}
	end
	if type(barColours) == 'number' then
		barColours = {barColours}
	end
	local total = 0
	local _x = x
	for i, v in ipairs(values) do
		local width = self.Bedrock.Helpers.Round((v / self.Maximum) * self.Width)
		total = total + v
		Drawing.DrawBlankArea(_x, y, width, self.Height, barColours[((i-1)%#barColours)+1])
		_x = _x + width
	end

	if self.ShowText then
		local text = self.Bedrock.Helpers.Round((total / self.Maximum) * 100) .. '%'
		Drawing.DrawCharactersCenter(x, y, self.Width, self.Height, text, self.TextColour, colours.transparent)
	end
end