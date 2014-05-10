
	X = 1
	Y = 1
	Width = 0
	Height = 0
	BackgroundColour = colours.lightGrey
	TextColour = colours.black
	PlaceholderTextColour = colours.lightGrey
	Parent = nil
	TextInput = nil
	Visible = true
	Placeholder = ''

	Draw = function(self)
		if not self.Visible then
			if Current.Input == self.TextInput then
				Current.Input = nil
			end
			return
		end
		local pos = GetAbsolutePosition(self)
		Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, self.BackgroundColour)
		local text = self.TextInput.Value
		if self.TextInput.CursorPos > #text then
			self.TextInput.CursorPos = #text
		end

		if #text > (self.Width - 2) then
			text = text:sub(#text-(self.Width - 3))
			if Current.Input == self.TextInput then
				Current.CursorPos = {pos.X + 1 + self.Width-2, pos.Y}
			end
		else
			if Current.Input == self.TextInput then
				Current.CursorPos = {pos.X + 1 + self.TextInput.CursorPos, pos.Y}
			end
		end

		if #tostring(text) == 0 then
			Drawing.DrawCharacters(pos.X + 1, pos.Y, self.Placeholder, self.PlaceholderTextColour, self.BackgroundColour)
		else
			Drawing.DrawCharacters(pos.X + 1, pos.Y, text, self.TextColour, self.BackgroundColour)
		end


		Current.CursorColour = self.TextColour
		RegisterClick(self)
	end

	Initialise = function(self, x, y, width, height, parent, text, backgroundColour, textColour, change, numerical, placeholder, placeholderColour)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		height = height or 1
		new.Width = width or #text + 2
		new.Height = height
		new.Y = y
		new.X = x
		new.TextInput = TextInput:Initialise(text or '', function(key)
			change(new, key)
			MainDraw()
		end, numerical)
		new.BackgroundColour = backgroundColour or colours.lightGrey
		new.TextColour = textColour or colours.black
		new.Parent = parent
		new.Placeholder = placeholder or ''
		new.PlaceholderTextColour = placeholderColour or colours.lightGrey
		return new
	end

	Click = function(self, side, x, y)
		if not self.Visible then
			return false
		end
		if Current.Input ~= self.TextInput then
			Current.Input = self.TextInput
		end
		self.TextInput.CursorPos = x - 2
		
		MainDraw()
	end

	Register = function(self)
		RegisterElement(self)
		return self
	end