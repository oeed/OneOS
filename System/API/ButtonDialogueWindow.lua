	X = 1
	Y = 1
	Width = 0
	Height = 0
	CursorPos = 1
	CancelButton = nil
	OkButton = nil
	Visible = true
	Lines = {}

	Draw = function(self)
		if not self.Visible then
			return
		end
		Drawing.DrawBlankArea(self.X + 1, self.Y+1, self.Width, self.Height, colours.grey)
		Drawing.DrawBlankArea(self.X, self.Y, self.Width, 1, colours.lightGrey)
		Drawing.DrawBlankArea(self.X, self.Y+1, self.Width, self.Height-1, colours.white)
		Drawing.DrawCharactersCenter(self.X, self.Y, self.Width, 1, self.Title, colours.black, colours.lightGrey)

		for i, text in ipairs(self.Lines) do
			Drawing.DrawCharacters(self.X + 1, self.Y + 1 + i, text, colours.black, colours.white)
		end

		self.OkButton:Draw()
		if self.CancelButton then
			self.CancelButton:Draw()
		end
	end

	Initialise = function(self, title, message, okText, cancelText, returnFunc)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Width = 28
		new.Lines = Helpers.WrapText(message, new.Width - 2)
		new.Height = 5 + #new.Lines
		new.Return = returnFunc
		new.X = math.ceil((Drawing.Screen.Width - new.Width) / 2)
		new.Y = math.ceil((Drawing.Screen.Height - new.Height) / 2)
		new.Title = Helpers.TruncateString(title, 26)
		new.Visible = true
		new.OkButton = Button:Initialise(new.Width - #okText - 2, new.Height - 1, nil, 1, colours.lightGrey, colours.black, colours.blue, colours.white, new, function()
			returnFunc(true)
			new:Close()
		end, okText)
		if cancelText then
			new.CancelButton = Button:Initialise(new.Width - #okText - 2 - 1 - #cancelText - 2, new.Height - 1, nil, 1, colours.lightGrey, colours.black, colours.blue, colours.white, new, function()
				returnFunc(false)
				new:Close()
			end, cancelText)
		end
		return new
	end

	Show = function(self)
		Current.Window = self
		return self
	end

	Close = function(self)
		term.setCursorBlink(false)
		Current.Window = nil
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
		if self.CancelButton then
			ButtonClick(self, self.CancelButton, x, y)
		end
		return true
	end