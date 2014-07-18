BackgroundColour = colours.lightGrey
TextColour = colours.black
PlaceholderTextColour = colours.grey
Placeholder = ''
AutoWidth = false
Text = ""
CursorPos = nil
Numerical = false

OnDraw = function(self, x, y)
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
	if self.CursorPos > #self.Text then
		self.CursorPos = #self.Text
	elseif self.CursorPos < 0 then
		self.CursorPos = 0
	end
	local text = self.Text
	if self.Bedrock:GetActiveObject() == self then
		if #text > (self.Width - 2) then
			text = text:sub(#text-(self.Width - 3))
			self.Bedrock.CursorPos = {x + 1 + self.Width-2, y}
		else
			self.Bedrock.CursorPos = {x + 1 + self.CursorPos, y}
		end
		self.Bedrock.CursorColour = self.TextColour
	end

	if #tostring(text) == 0 then
		Drawing.DrawCharacters(x + 1, y, self.Placeholder, self.PlaceholderTextColour, self.BackgroundColour)
	else
		Drawing.DrawCharacters(x + 1, y, text, self.TextColour, self.BackgroundColour)
	end
end

OnLoad = function(self)
	if not self.CursorPos then
		self.CursorPos = #self.Text
	end
end

OnClick = function(self, event, side, x, y)
	self.Bedrock:SetActiveObject(self)
	self.CursorPos = x - 2
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
		if self.OnChange then
			self:OnChange(event, keychar)
		end
		return false
	elseif event == 'key' then
		if keychar == keys.enter then
			if self.OnChange then
				self:OnChange(event, keychar)
			end
		elseif keychar == keys.left then
			--[[
TODO: behaves odly when the text is too long and arrow keys are pushed
]]--
			-- Left
			if self.CursorPos > 0 then
				self.CursorPos = self.CursorPos - 1
				if self.OnChange then
					self:OnChange(event, keychar)
				end
			end
			
		elseif keychar == keys.right then
			-- Right				
			if self.CursorPos < string.len(self.Text) then
				self.CursorPos = self.CursorPos + 1
				if self.OnChange then
					self:OnChange(event, keychar)
				end
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
				if self.OnChange then
					self:OnChange(event, keychar)
				end
			end
		elseif keychar == keys.home then
			-- Home
			self.CursorPos = 0
			if self.OnChange then
				self:OnChange(event, keychar)
			end
		elseif keychar == keys.delete then
			if self.CursorPos < string.len(self.Text) then
				self.Text = string.sub( self.Text, 1, self.CursorPos ) .. string.sub( self.Text, self.CursorPos + 2 )		
				if self.Numerical then
					self.Text = tostring(tonumber(self.Text))
					if self.Text == 'nil' then
						self.Text = '1'
					end
				end
				if self.OnChange then
					self:OnChange(keychar)
				end
			end
		elseif keychar == keys["end"] then
			-- End
			self.CursorPos = string.len(self.Text)
		else
			if self.OnChange then
				self:OnChange(event, keychar)
			end
			return false
		end
	end
end