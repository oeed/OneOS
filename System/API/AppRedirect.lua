	
	--buffer item: text, text colour, background colour

	X = 1
	Y = 1
	Buffer = {}
	TextColour = colours.white
	BackgroundColour = colours.black
	CursorPos = {1, 1}
	Size = {1, 1}
	CursorBlink = false

	Initialise = function(self, x, y, width, height, program)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.X = x
		new.Y = y
		new.Size = {width, height}
		new.CursorPos = {1, 1}
		new.Buffer = {}
		new.TextColour = colours.white
		new.BackgroundColour = colours.black
		new.CursorBlink = false
		new.Term = _term(new)
		new:ResizeBuffer()
		new.Program = program
		return new
	end
	
	Draw = function(self)
		local start = os.clock()
		local pos = GetAbsolutePosition(self)
		for y, row in ipairs(self.Buffer) do
			for x, pixel in pairs(row) do
				Drawing.WriteToBuffer(pos.X+x-1, pos.Y+y-1, pixel[1], pixel[2], pixel[3])
			end
		end
		Current.CursorPos = {pos.X+self.CursorPos[1]-1, pos.Y+self.CursorPos[2]-1}
		Current.CursorColour = self.TextColour
		term.setCursorBlink(self.CursorBlink)
	end

	ResizeBuffer = function(self)
		if #self.Buffer ~= self.Size[2] then
			while #self.Buffer < self.Size[2] do
				table.insert(self.Buffer, {})
			end

			while #self.Buffer > self.Size[2] do
				table.remove(self.Buffer, #self.Buffer)
			end
		end

		for i, row in ipairs(self.Buffer) do
			while #row < self.Size[1] do
				table.insert(row, {' ', self.TextColour, self.BackgroundColour})
			end

			while #row > self.Size[1] do
				table.remove(row, #row)
			end
		end
	end

	local _oldterm = term.native
	if type(_oldterm) == 'function' then
		_oldterm = _oldterm()
	end
	local count = 1

	ClearLine = function(self, y, backgroundColour)
		if y > self.Size[2] or y < 1 then
			return
		end

		if not Current.Window and not Current.Menu and Current.Program == self.Program then
			_oldterm.setBackgroundColour(backgroundColour)
			_oldterm.setCursorPos(1, y+1)
			_oldterm.clearLine()
		end
		self.Buffer[y] = self.Buffer[y] or {}
		for x = 1, self.Size[1] do
			self.Buffer[y][x] = {' ', self.TextColour, backgroundColour}
		end
	end

	WriteToBuffer = function(self, character, textColour, backgroundColour)
		local x = math.floor(self.CursorPos[1])
		local y = math.floor(self.CursorPos[2])
		if x > self.Size[1] or y > self.Size[2] or x < 1 or y < 1 then
			return
		end
		
		if Current.CanDraw and not Current.Window and not Current.Menu and Current.Program == self.Program and (not self.Buffer[y] or (self.Buffer[y][x][1] ~= character or self.Buffer[y][x][2] ~= textColour or self.Buffer[y][x][3] ~= backgroundColour)) then
			--Drawing.WriteToBuffer(pos.X+x-1, pos.Y+y-1, character, textColour, backgroundColour)
			_oldterm.setCursorPos(x+self.X-1, y+self.Y-1)
			_oldterm.setTextColour(textColour)
			_oldterm.setBackgroundColour(backgroundColour)
			_oldterm.write(character)
		end
		self.Buffer[y] = self.Buffer[y] or {}
		self.Buffer[y][x] = {character, textColour, backgroundColour}
	end
	
	-- 'term' methods
	-- This is based upon 1.56, programs designed for 1.6 might not work correctly
	_term = function(self)
		local _term = {}
		_term.native = _term

		_term.write = function(characters)
			if type(characters) == 'number' then
				characters = tostring(characters)
			elseif type(characters) ~= 'string' then
				return
			end
			self.CursorPos[1] = self.CursorPos[1] - 1
			for i = 1, #characters do
				local character = characters:sub(i,i)
				self.CursorPos[1] = self.CursorPos[1] + 1
				self:WriteToBuffer(character, self.TextColour, self.BackgroundColour)
			end
			self.CursorPos[1] = self.CursorPos[1] + 1
		end

		_term.clear = function()
			local cursorPosX, cursorPosY = self.CursorPos[1], self.CursorPos[2]
			for y = 1, self.Size[2] do
				self:ClearLine(y, self.BackgroundColour)
			end
			self.CursorPos = {cursorPosX, cursorPosY}
		end	

		_term.clearLine = function()
			local cursorPosX, cursorPosY = self.CursorPos[1], self.CursorPos[2]
			self:ClearLine(cursorPosY, self.BackgroundColour)
			self.CursorPos = {cursorPosX, cursorPosY}
		end	

		_term.getCursorPos = function()
			return self.CursorPos[1], self.CursorPos[2]
		end

		_term.setCursorPos = function(x, y)
			local pos = GetAbsolutePosition(self)
			self.CursorPos[1] = math.floor( tonumber(x) ) or self.CursorPos[1]
			self.CursorPos[2] = math.floor( tonumber(y) ) or self.CursorPos[2]
			Current.CursorPos = {pos.X+self.CursorPos[1]-1, pos.Y+self.CursorPos[2]-1}
		end

		_term.setCursorBlink = function(blink)
			self.CursorBlink = blink
		end

		_term.isColour = function()
			return true
		end

		_term.isColor = _term.isColour

		_term.setTextColour = function(colour)
			if colour and colour <= 32768 and colour >= 1 then
				self.TextColour = colour
				Current.CursorColour = self.TextColour
			end
		end

		_term.setTextColor = _term.setTextColour

		_term.setBackgroundColour = function(colour)
			if colour and colour <= 32768 and colour >= 1 then
				self.BackgroundColour = colour
			end
		end

		_term.setBackgroundColor = _term.setBackgroundColour

		_term.getSize = function()
			return self.Size[1], self.Size[2]
		end

		_term.scroll = function(amount)
			if amount == nil then
				error("Expected number", 2)
			end
			local lines = {}
			if amount > 0 then
				for _ = 1, amount do
					table.remove(self.Buffer, 1)
					table.insert(lines, #self.Buffer+1)
				end
			elseif amount < 0 then
				for _ = 1, amount do
					table.remove(self.Buffer, #self.Buffer)
					local row = {}
					for i = 1, self.Size[1] do
						table.insert(row, {' ', self.TextColour, self.BackgroundColour})
					end
					table.insert(self.Buffer, 1, row)
					table.insert(lines, _)
				end
			end
			self:ResizeBuffer()
			for i, v in ipairs(lines) do
				self:ClearLine(v, self.BackgroundColour)
			end
			self:Draw()
		end

		return _term
	end 