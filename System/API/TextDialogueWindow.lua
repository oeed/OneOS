	X = 1
	Y = 1
	Width = 0
	Height = 0
	TextInput = nil
	CursorPos = 1
	CancelButton = nil
	OkButton = nil
	Visible = true

	Draw = function(self)
		if not self.Visible then
			term.setCursorBlink(false)
			return
		end
		Drawing.DrawBlankArea(self.X + 1, self.Y+1, self.Width, self.Height, colours.grey)
		Drawing.DrawBlankArea(self.X, self.Y, self.Width, 1, colours.lightGrey)
		Drawing.DrawBlankArea(self.X, self.Y+1, self.Width, self.Height-1, colours.white)
		Drawing.DrawCharactersCenter(self.X, self.Y, self.Width, 1, self.Title, colours.black, colours.lightGrey)
		Drawing.DrawBlankArea(self.X + 2, self.Y + 2, self.Width - 4, 1, colours.lightGrey)
		Drawing.DrawCharacters(self.X + 3, self.Y + 2, self.TextInput.Value, colours.black, colours.lightGrey)
		self.OkButton:Draw()
		self.CancelButton:Draw()
		term.setCursorBlink(true)
		Current.CursorPos = {self.X + 3 + self.TextInput.CursorPos, self.Y + 2}
		Current.CursorColour = colours.black
	end

	Initialise = function(self, title, returnFunc)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Width = 28
		new.Height = 6
		new.Return = returnFunc
		new.X = math.ceil((Drawing.Screen.Width - new.Width) / 2)
		new.Y = math.ceil((Drawing.Screen.Height - new.Height) / 2)
		new.Title = Helpers.TruncateString(title, 26)
		new.Visible = true
		new.OkButton = Button:Initialise(new.Width - 5, 5, nil, 1, colours.lightGrey, colours.black, colours.blue, colours.white, new, function()
			returnFunc(true, new.TextInput.Value)
			new:Close()
		end, "Ok")
		new.CancelButton = Button:Initialise(new.Width - 14, 5, nil, 1, colours.lightGrey, colours.black, colours.blue, colours.white, new, function()
			returnFunc(false)
			new:Close()
		end, "Cancel")
		new.TextInput = TextInput:Initialise('', function(key)
			if key == keys.enter then
				new.OkButton:Click()
			end
			MainDraw()
		end)
		return new
	end

	Show = function(self)
		Current.Window = self
		Current.Input = self.TextInput
		return self
	end

	Close = function(self)
		term.setCursorBlink(false)
		Current.Window = nil
		Current.Input = nil
		self = nil
		if Current.Program then
			Current.Program.AppRedirect:Draw()
		end
	end

	Flash = function(self)
		self.Visible = false
		MainDraw()
		sleep(0.15)
		self.Visible = true
		MainDraw()
		sleep(0.15)
		self.Visible = false
		MainDraw()
		sleep(0.15)
		self.Visible = true
		MainDraw()
	end

	local function ButtonClick(self, button, x, y)
		if button.X <= x and button.Y <= y and button.X + button.Width > x and button.Y + button.Height > y then
			button:Click()
		end
	end

	Click = function(self, side, x, y)
		ButtonClick(self, self.OkButton, x, y)
		ButtonClick(self, self.CancelButton, x, y)
		return true
	end