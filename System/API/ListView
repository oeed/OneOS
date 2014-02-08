	X = 1
	Y = 1
	Width = 0
	Height = 0
	ActiveBackgroundColour = colours.blue
	BackgroundColour = colours.white
	TextColour = colours.black
	ActiveTextColour = colours.white
	Items = {}
	Parent = nil
	Selected = nil
	Scroll = 0
	MaxScroll = 0

	local round = function(num, idp)
		local mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	end

	Draw = function(self)
		local pos = GetAbsolutePosition(self)--{X = self.X, Y = self.Y}
		Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, self.BackgroundColour)

		for i, v in ipairs(self.Items) do
			local y = i - self.Scroll
			if y > 0 and y <= self.Height then
				if self.Selected == i then
					Drawing.DrawBlankArea(pos.X, pos.Y - 1 + y, self.Width, 1, self.ActiveBackgroundColour)
					Drawing.DrawCharacters(pos.X + 1, pos.Y - 1 + y, v, self.ActiveTextColour, self.ActiveBackgroundColour)
				else
					Drawing.DrawCharacters(pos.X + 1, pos.Y - 1 + y, v, self.TextColour, self.BackgroundColour)
				end
			end
		end

		if self.MaxScroll ~= 0 then
			local fullHeight = self.Height
			local barHeight = round(fullHeight*(self.Height/#self.Items))-- (fullHeight - self.MaxScroll)
			local realBarHeight = barHeight
			if barHeight < 2 then
				barHeight = 2
			end
			local barPos = round(self.Scroll*(realBarHeight/fullHeight))
			if self.MaxScroll == self.Scroll then
				barPos = self.Height-barHeight
			end
			Drawing.DrawBlankArea(pos.X + self.Width - 1, pos.Y, 1, fullHeight, colours.grey)
			Drawing.DrawBlankArea(pos.X + self.Width - 1, pos.Y + barPos, 1, barHeight, colours.lightGrey)
		end
		RegisterClick(self)
	end

	Initialise = function(self, x, y, width, height, items, parent)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Width = width
		new.Height = height
		new.Y = y
		new.X = x
		new.TextColour = self.TextColour
		new.ActiveTextColour = self.ActiveTextColour
		new.ActiveBackgroundColour = self.ActiveBackgroundColour
		new.BackgroundColour = self.BackgroundColour
		new.Parent = parent
		new.Items = items
		new.Scroll = 0
		new.MaxScroll = #items - height
		if new.MaxScroll < 0 then
			new.MaxScroll = 0
		end
		return new
	end

	Register = function(self)
		RegisterElement(self)
		return self
	end

	Click = function(self, side, x, y)
		if self.MaxScroll ~= 0 and x == self.Width then
			self.Scroll = round((((y-1)/self.Height)*self.MaxScroll))
			if y == self.Height then
				self.Scroll = self.MaxScroll
			end
			return true
		else
			if self.Items[y+self.Scroll] then
				self.Selected = y+self.Scroll
				return true
			else
				return false
			end
		end
	end