	X = 1
	Y = 1
	Width = 0
	Height = 0
	BackgroundColour = colours.lightGrey
	ActiveColour = colours.blue
	Text = ""
	Parent = nil
	Total = 1
	Value = 0

	Draw = function(self)
		local pos = GetAbsolutePosition(self)--{X = self.X, Y = self.Y}
		Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, self.BackgroundColour)

		if self.Value > self.Total then
			self.Value = self.Total
		end

		if (self.Value > 0) and (self.Total > 0) then
			Drawing.DrawBlankArea(pos.X, pos.Y, (self.Value / self.Total) * self.Width, self.Height, self.ActiveColour)
		end
		
		local text = self.Text
		if text == '' then
			text = math.floor(100*(self.Value / self.Total)) .. '%'
		end

		Drawing.DrawCharactersCenter(pos.X, pos.Y, self.Width, self.Height, text, colours.white, colours.transparent)
		--Drawing.DrawCharacters(math.floor((self.Width - #self.Text) / 2) + pos.X, pos.Y, self.Text:sub(1, ((self.Value / self.Total) * self.Width) - (math.floor((self.Width - #self.Text) / 2))), colours.white, self.ActiveColour)
		
	end

	Initialise = function(self, x, y, width, height, backgroundColour, activeColour, parent, text, value, total)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		height = height or 1
		width = width or #text + 2
		new.Width = width
		new.Height = height
		new.Y = y
		new.X = x
		new.Text = text or ""
		new.BackgroundColour = backgroundColour or self.BackgroundColour
		new.ActiveColour = activeColour or self.ActiveColour
		new.Parent = parent
		new.Value = value
		new.Total = total
		return new
	end

	Register = function(self)
		RegisterElement(self)
		return self
	end

	Click = function(self, side, x, y)
		return false
	end