	X = 1
	Y = 1
	Width = 0
	Height = 0
	BackgroundColour = colours.white
	ActiveBackgroundColour = colours.blue
	ActiveTextColour = colours.white
	TextColour = colours.black
	Text = ""
	Parent = nil
	_Click = nil
	Toggle = nil
	Momentary = false

	Draw = function(self)
		local bg = self.BackgroundColour
		if type(bg) == 'function' then
			bg = bg()
		end

		if self.Toggle then
			bg = self.ActiveBackgroundColour
		end
		if type(bg) == 'function' then
			bg = bg()
		end

		local txt = self.TextColour
		if self.Toggle then
			txt = self.ActiveTextColour
		end
		if type(txt) == 'function' then
			txt = txt()
		end
		local pos = GetAbsolutePosition(self)--{X = self.X, Y = self.Y}
		Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, bg)
		Drawing.DrawCharactersCenter(pos.X, pos.Y, self.Width, self.Height, self.Text, txt, bg)

		if self.Momentary then
			self.Toggle = false
		end

		RegisterClick(self)
	end

	Initialise = function(self, x, y, width, height, backgroundColour, textColour, activeBackgroundColour, activeTextColour, parent, click, text,  toggle)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		height = height or 1
		width = width or #text + 2
		new.Width = width
		new.Height = height
		new.Y = y
		new.X = x
		if toggle == 3 then
			new.Momentary = true
			new.Toggle = false
		else
			new.Toggle = toggle
		end
		new.Text = text or ""
		new.BackgroundColour = backgroundColour or self.BackgroundColour
		new.TextColour = textColour or self.TextColour
		new.ActiveBackgroundColour = activeBackgroundColour or self.ActiveBackgroundColour
		new.ActiveTextColour = activeTextColour or self.ActiveTextColour
		new.Parent = parent
		new._Click = click
		return new
	end

	Register = function(self)
		RegisterElement(self)
		return self
	end

	Click = function(self, side, x, y)
		if self._Click then
			if self:_Click(side, x, y, not self.Toggle) ~= false and self.Toggle ~= nil then
				self.Toggle = not self.Toggle
			end
			return true
		else
			return false
		end
	end