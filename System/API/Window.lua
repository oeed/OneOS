	X = 1
	Y = 1
	Width = 0
	Height = 0
	AppRedirect = nil

	Draw = function(self)
		Drawing.DrawBlankArea(self.X, self.Y, self.Width, 1, colours.lightGrey)
		Drawing.DrawBlankArea(self.X, self.Y+1, self.Width, self.Height-1, colours.white)
		Drawing.DrawCharactersCenter(self.X, self.Y, self.Width, 1, self.Title, colours.black, colours.lightGrey)

		--self.AppRedirect.Term.write('Test')
		self.AppRedirect.Term.setCursorPos(1,2)

		self.AppRedirect:Draw()
		RegisterClick(self)
	end

	Initialise = function(self, x, y, width, height, title, program)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Width = width
		new.Height = height
		new.Y = y
		new.X = x
		new.Title = title
		new.AppRedirect = AppRedirect:Initialise(1, 2, width, height-1, new)
		return new
	end

	Show = function(self)
		self:Register()
		Current.Window = self
		return self
	end

	Register = function(self)
		RegisterElement(self)
		return self
	end

	Click = function(self, side, x, y)
		if self._Click then
			if self.Toggle ~= nil then
				self.Toggle = not self.Toggle
			end
			self:_Click(side, x, y, self.Toggle)
			return true
		else
			return false
		end
	end