BackgroundColour = colours.lightGrey
BarColour = colours.blue
TextColour = colours.black
ShowText = false
Value = 0
Maximum = 1

OnDraw = function(self, x, y)
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
	if self.ShowText then
		Drawing.DrawCharactersCenter(x, y, self.Width, self.Height, self.Text, self.TextColour, colours.transparent)
	end

	local values = self.Value
	local barColours = self.BarColour
	if type(values) == 'number' then
		values = {values}
	end
	if type(barColours) == 'number' then
		barColours = {barColours}
	end
	local _x = x
	for i, v in ipairs(values) do
		local width = self.Bedrock.Helpers.Round((v / self.Maximum) * self.Width)
		Drawing.DrawBlankArea(_x, y, width, self.Height, barColours[((i-1)%#barColours)+1])
		_x = _x + width
	end
end