	X = 1
	Y = 1
	Width = 0
	Height = 0
	BackgroundColour = colours.lightGrey
	TextColour = colours.black
	PlaceholderTextColour = colours.lightGrey
	Parent = nil
	Visible = true
	Placeholder = ''
	Name = nil
	AutoWidth = false
	Text = ""
	Change = nil
	CursorPos = nil
	Numerical = false
	Bedrock = nil

	Draw = function(self)
		if not self.Visible then
			if Bedrock:GetActiveObject() == self then
				Bedrock:SetActiveObject()
			end
			return
		end
		local pos = self.Bedrock:GetAbsolutePosition(self)

		Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, self.BackgroundColour)
		if self.CursorPos > #self.Text then
			self.CursorPos = #self.Text
		end

		if Bedrock:GetActiveObject() == self then
			if #self.Text > (self.Width - 2) then
				self.Text = self.Text:sub(#self.Text-(self.Width - 3))
				Bedrock.CursorPos = {pos.X + 1 + self.Width-2, pos.Y}
			else
				Bedrock.CursorPos = {pos.X + 1 + self.CursorPos, pos.Y}
			end
		end

		if #tostring(self.Text) == 0 then
			Drawing.DrawCharacters(pos.X + 1, pos.Y, self.Placeholder, self.PlaceholderTextColour, self.BackgroundColour)
		else
			Drawing.DrawCharacters(pos.X + 1, pos.Y, self.Text, self.TextColour, self.BackgroundColour)
		end


		Bedrock.CursorColour = self.TextColour
		RegisterClick(self)
	end

	Initialise = function(self, x, y, width, height, parent, text, backgroundColour, textColour, change, numerical, placeholder, placeholderColour)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		height = height or 1
		new.AutoWidth = not width
		if text then
			width = width or #text + 2
		elseif not width then
			width = 2
		end
		new.Width = width
		new.Height = height
		new.Y = y
		new.X = x
		new.BackgroundColour = backgroundColour or colours.lightGrey
		new.TextColour = textColour or colours.black
		new.Parent = parent
		new.Placeholder = placeholder or ''
		new.PlaceholderTextColour = placeholderColour or colours.lightGrey

		new.Text = text or ""
		new.CursorPos = #new.Text
		new.Numerical = numerical
		return new
	end

	Click = function(self, event, side, x, y)
		if not self.Visible then
			return false
		end
		Bedrock:SetActiveObject(self)
		self.CursorPos = x - 2
	end

	Register = function(self)
		RegisterElement(self)
		return self
	end

	Char = function(self, char)
		if self.Numerical then
			char = tostring(tonumber(char))
		end
		if char == 'nil' then
			return
		end
		self.Text = string.sub(self.Text, 1, self.CursorPos ) .. char .. string.sub( self.Text, self.CursorPos + 1 )
		if self.Numerical then
			self.Text = tostring(tonumber(self.Text))
			if self.Text == 'nil' then
				self.Text = '1'
			end
		end
		
		self.CursorPos = self.CursorPos + 1
		self.Change(key)
	end

	Key = function(self, key)
		if key == keys.enter then
			self.Change(true)		
		elseif key == keys.left then
			-- Left
			if self.CursorPos > 0 then
				self.CursorPos = self.CursorPos - 1
				self.Change(key)
			end
			
		elseif key == keys.right then
			-- Right				
			if self.CursorPos < string.len(self.Text) then
				self.CursorPos = self.CursorPos + 1
				self.Change(key)
			end
		
		elseif key == keys.backspace then
			-- Backspace
			if self.CursorPos > 0 then
				self.Text = string.sub( self.Text, 1, self.CursorPos - 1 ) .. string.sub( self.Text, self.CursorPos + 1 )
				self.CursorPos = self.CursorPos - 1					
				if self.Numerical then
					self.Text = tostring(tonumber(self.Text))
					if self.Text == 'nil' then
						self.Text = '1'
					end
				end
				self.Change(key)
			end
		elseif key == keys.home then
			-- Home
			self.CursorPos = 0
			self.Change()
		elseif key == keys.delete then
			if self.CursorPos < string.len(self.Text) then
				self.Text = string.sub( self.Text, 1, self.CursorPos ) .. string.sub( self.Text, self.CursorPos + 2 )		
				if self.Numerical then
					self.Text = tostring(tonumber(self.Text))
					if self.Text == 'nil' then
						self.Text = '1'
					end
				end
				self.Change(key)
			end
		elseif key == keys["end"] then
			-- End
			self.CursorPos = string.len(self.Text)
			self.Change(key)
		end
	end