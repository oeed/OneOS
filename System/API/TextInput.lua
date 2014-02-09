	Value = ""
	Change = nil
	CursorPos = nil
	Numerical = false

	Initialise = function(self, value, change, numerical)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Value = value
		new.Change = change
		new.CursorPos = #value
		new.Numerical = numerical
		return new
	end

	Char = function(self, char)
		if self.Numerical then
			char = tostring(tonumber(char))
		end
		if char == 'nil' then
			return
		end
		self.Value = string.sub(self.Value, 1, self.CursorPos ) .. char .. string.sub( self.Value, self.CursorPos + 1 )
		if self.Numerical then
			self.Value = tostring(tonumber(self.Value))
			if self.Value == 'nil' then
				self.Value = '1'
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
			if self.CursorPos < string.len(self.Value) then
				self.CursorPos = self.CursorPos + 1
				self.Change(key)
			end
		
		elseif key == keys.backspace then
			-- Backspace
			if self.CursorPos > 0 then
				self.Value = string.sub( self.Value, 1, self.CursorPos - 1 ) .. string.sub( self.Value, self.CursorPos + 1 )
				self.CursorPos = self.CursorPos - 1					
				if self.Numerical then
					self.Value = tostring(tonumber(self.Value))
					if self.Value == 'nil' then
						self.Value = '1'
					end
				end
				self.Change(key)
			end
		elseif key == keys.home then
			-- Home
			self.CursorPos = 0
			self.Change()
		elseif key == keys.delete then
			if self.CursorPos < string.len(self.Value) then
				self.Value = string.sub( self.Value, 1, self.CursorPos ) .. string.sub( self.Value, self.CursorPos + 2 )		
				if self.Numerical then
					self.Value = tostring(tonumber(self.Value))
					if self.Value == 'nil' then
						self.Value = '1'
					end
				end
				self.Change(key)
			end
		elseif key == keys["end"] then
			-- End
			self.CursorPos = string.len(self.Value)
			self.Change(key)
		end
	end