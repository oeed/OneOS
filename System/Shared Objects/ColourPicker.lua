Width = 34

ActiveColour = nil

local pickerColours = {
	colours.brown,
	colours.yellow,
	colours.orange,
	colours.red,
	colours.green,
	colours.lime,
	colours.magenta,
	colours.pink,
	colours.purple,
	colours.blue,
	colours.cyan,
	colours.lightBlue,
	colours.lightGrey,
	colours.grey,
	colours.black,
	colours.white
}

OnDraw = function(self, x, y)
	local _x = 0

	for i, col in ipairs(pickerColours) do
		local w = 2
		if col == self.ActiveColour then
			w = 4
		end

		if col == colours.white then
			Drawing.DrawCharacters(x + _x, y, ('#'):rep(w), colours.lightGrey, col)
		else
			Drawing.DrawBlankArea(x + _x, y, w, self.Height, col)
		end

		_x = _x + w
	end
end

OnUpdate = function(self, value)
	if value == 'ActiveColour' then
		if self.OnChange then
			self:OnChange(self.ActiveColour)
		end
	end
end

OnClick = function(self, event, side, x, y)
	local _x = 0

	for i, col in ipairs(pickerColours) do
		local w = 2
		if col == self.ActiveColour then
			w = 4
		end

		if x >= _x + 1 and x <= _x + w + 1 then
			self.ActiveColour = col
		end

		_x = _x + w
	end
end

OnDrag = OnClick