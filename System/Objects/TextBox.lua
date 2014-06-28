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
		if self.Bedrock:GetActiveObject() == self then
			self.Bedrock:SetActiveObject()
		end
		return
	end
	local pos = self.Bedrock:GetAbsolutePosition(self)

	Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, self.BackgroundColour)
	if self.CursorPos > #self.Text then
		self.CursorPos = #self.Text
	elseif self.CursorPos < 0 then
		self.CursorPos = 0
	end
	local text = self.Text
	if self.Bedrock:GetActiveObject() == self then
		if #text > (self.Width - 2) then
			text = text:sub(#text-(self.Width - 3))
			self.Bedrock.CursorPos = {pos.X + 1 + self.Width-2, pos.Y}
		else
			self.Bedrock.CursorPos = {pos.X + 1 + self.CursorPos, pos.Y}
		end
	end

	if #tostring(text) == 0 then
		Drawing.DrawCharacters(pos.X + 1, pos.Y, self.Placeholder, self.PlaceholderTextColour, self.BackgroundColour)
	else
		Drawing.DrawCharacters(pos.X + 1, pos.Y, text, self.TextColour, self.BackgroundColour)
	end


	self.Bedrock.CursorColour = self.TextColour
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

InitialiseUpdate = function(self)
	self.CursorPos = #self.Text
	if self.Active then
		self.Bedrock:SetActiveObject(self)
	end
end

Click = function(self, event, side, x, y)
	if not self.Visible then
		return false
	end
	self.Bedrock:SetActiveObject(self)
	self.CursorPos = x - 2
end

Register = function(self)
	RegisterElement(self)
	return self
end

OnKeyChar = function(self, event, keychar)
	if event == 'char' then
		if self.Numerical then
			keychar = tostring(tonumber(keychar))
		end
		if keychar == 'nil' then
			return
		end
		self.Text = string.sub(self.Text, 1, self.CursorPos ) .. keychar .. string.sub( self.Text, self.CursorPos + 1 )
		if self.Numerical then
			self.Text = tostring(tonumber(self.Text))
			if self.Text == 'nil' then
				self.Text = '1'
			end
		end
		
		self.CursorPos = self.CursorPos + 1
		self:_Update(keychar)
		return false
	elseif event == 'key' then
		if keychar == keys.enter then
			self:_Update(true)		
		elseif keychar == keys.left then
			--[[
TODO: behaves odly when the text is too long and arrow keys are pushed
]]--
			-- Left
			if self.CursorPos > 0 then
				self.CursorPos = self.CursorPos - 1
				self:_Update(keychar)
			end
			
		elseif keychar == keys.right then
			-- Right				
			if self.CursorPos < string.len(self.Text) then
				self.CursorPos = self.CursorPos + 1
				self:_Update(keychar)
			end
		
		elseif keychar == keys.backspace then
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
				self:_Update(keychar)
			end
		elseif keychar == keys.home then
			-- Home
			self.CursorPos = 0
			self:_Update()
		elseif keychar == keys.delete then
			if self.CursorPos < string.len(self.Text) then
				self.Text = string.sub( self.Text, 1, self.CursorPos ) .. string.sub( self.Text, self.CursorPos + 2 )		
				if self.Numerical then
					self.Text = tostring(tonumber(self.Text))
					if self.Text == 'nil' then
						self.Text = '1'
					end
				end
				self:_Update(keychar)
			end
		elseif keychar == keys["end"] then
			-- End
			self.CursorPos = string.len(self.Text)
			self:_Update(keychar)
		end
		return false
	end
end