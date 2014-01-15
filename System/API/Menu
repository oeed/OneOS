	X = 1
	Y = 1
	Width = 0
	Height = 0
	BackgroundColour = colours.white
	TextColour = colours.black
	Items = {}
	Parent = nil
	_Click = nil
	HideTop = false
	OnClose = nil


	Draw = function(self)
		if Current.Menu ~= self then
			self:Close()
			return
		end

		local bg = self.BackgroundColour
		if type(bg) == 'function' then
			bg = bg()
		end

		local pos = GetAbsolutePosition(self)

		local topHeight = 1
		if self.HideTop then
			topHeight = 0
		end

		Drawing.DrawBlankArea(pos.X+1, pos.Y+topHeight, self.Width, self.Height+1, colours.grey)
		Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height + topHeight, bg)
		for i, item in ipairs(self.Items) do
			if item.Separator then
				Drawing.DrawArea(pos.X, pos.Y+i-1 + topHeight, self.Width, 1, '-', colours.grey, bg)
			else
				Drawing.DrawCharacters(pos.X + 1, pos.Y+i-1 + topHeight, item.Title, self.TextColour, bg)
			end
		end

		RegisterClick(self)
	end

	Initialise = function(self, x, y, backgroundColour, textColour, parent, items, hideTop, onClose)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Width = Helpers.LongestString(items, 'Title') + 2
		new.Height = #items + 1

		local posY = y
		if y + new.Height + 1 > Drawing.Screen.Height then
			posY = Drawing.Screen.Height - new.Height - 1
		end
		new.Y = posY
		
		local posX = x
		if x + new.Width > Drawing.Screen.Width then
			posX = Drawing.Screen.Width - new.Width
		end
		new.X = posX
		new.HideTop = hideTop or false
		new.Items = items
		new.BackgroundColour = backgroundColour or colours.white
		new.TextColour = textColour or colours.black
		new.Parent = parent
		new.OnClose = onClose or function()end
		return new
	end

	Show = function(self)
		if Current.Menu and Current.Menu ~= self then
			Current.Menu:Close()
		end

		self:Register()
		Current.Menu = self
	end

	Close = function(self)
		if Current.Menu == self then
			Current.Menu = nil
		end
		UnregisterElement(self)
		if self.Parent and self.Parent.Toggle then
			self.Parent.Toggle = false
			self.Parent:Draw()
		end
		self:OnClose()
		self = nil
	end

	Register = function(self)
		RegisterElement(self)
		return self
	end

	Click = function(self, side, x, y)
		local topHeight = 1
		if self.HideTop then
			topHeight = 0
		end
		if self.Items[y-topHeight] and self.Items[y-topHeight].Click then
			if side == 1 then
				self.Items[y-topHeight]:Click()
				self:Close()
			end
			return true
		else
			return false
		end
	end