	X = 1
	Y = 1
	Width = 0
	Height = 0
	CursorPos = 1
	CancelButton = nil
	OkButton = nil
	Visible = true
	Lines = {}
	Programs = {}
	ListView = nil

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

		self.ListView:Draw()

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
		new.Height = 11 + #new.Lines
		new.Return = returnFunc
		new.X = math.ceil((Drawing.Screen.Width - new.Width) / 2)
		new.Y = math.ceil((Drawing.Screen.Height - new.Height) / 2) + 1
		new.Title = Helpers.TruncateString(title, 26)
		new.Visible = true
		new.OkButton = Button:Initialise(new.Width - #okText - 2, new.Height - 1, nil, 1, colours.lightGrey, colours.black, colours.blue, colours.white, new, function()
			returnFunc(true, '/Programs/'..new.ListView.Items[new.ListView.Selected]..'.program')
			new:Close()
		end, okText)
		if cancelText then
			new.CancelButton = Button:Initialise(new.Width - #okText - 2 - 1 - #cancelText - 2, new.Height - 1, nil, 1, colours.lightGrey, colours.black, colours.blue, colours.white, new, function()
				returnFunc(false)
				new:Close()
			end, cancelText)
		end

		local programs = {}

		for i, v in ipairs(fs.list('/Programs/')) do
			if Helpers.Extension(v) == 'program' then
				table.insert(programs, Helpers.RemoveExtension(v))
			end
		end

		new.ListView = ListView:Initialise(2, 6, 26, 5, programs, new)
		new.ListView.Selected = 1
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

	local function ButtonClick(self, button, side, x, y)
		if button.X <= x and button.Y <= y and button.X + button.Width > x and button.Y + button.Height > y then
			button:Click(side, x - button.X + 1, y - button.Y + 1)
		end
	end

	Click = function(self, side, x, y)
		ButtonClick(self, self.ListView, side, x, y)
		ButtonClick(self, self.OkButton, side, x, y)
		if self.CancelButton then
			ButtonClick(self, self.CancelButton, side, x, y)
		end
		return true
	end