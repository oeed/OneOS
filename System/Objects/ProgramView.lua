-- drawing
Term = nil
CursorPos = nil
TextColour = colours.white
BackgroundColour = colours.black
CursorBlink = false
Buffer = {}
UpdateDrawBlacklist = {
	['EventQueue'] = true
}

-- program
Process = nil
EventQueue = nil
Timers = nil
Running = true
Path = nil
Title = nil
Environment = nil
Arguments = nil
Hidden = false

OnLoad = function(self)
	self.CursorPos = {1, 1}
	self.Buffer = {}

	self.Term = self:MakeTerm()
	self.EventQueue = {}
	self.Timers = {}
	self.Environment = Environment:Initialise(self, shell, self.Path)
	self.Running = true
	self:Execute()
end

Execute = function(self)
	local executable = function()
		local _, err = pcall(function()
			local fnFile, err2 = nil
			local h = OneOS.FS.open( self.Path, "r")
			if h then
				fnFile, err2 = loadstring( h.readAll(), OneOS.FS.getName(self.Path) )
				if err2 then
					err2 = err2:gsub("^.-: %[string \"","")
					err2 = err2:gsub('"%]',"")
				end
				h.close()
			end
	        local tEnv = self.Environment
			setmetatable( tEnv, { __index = _G } )
			setfenv( fnFile, tEnv )

			if (not fnFile) or err2 then
				term.setTextColour(colours.red)
				term.setBackgroundColour(colours.black)
				if err2 then
					print(err2)
				end
				if err2 == 'File not found' then
					term.clear()
					term.setTextColour(colours.white)
					term.setCursorPos(1,2)
					print('The program could not be found or is corrupt.')
					print()
					print('Try running the program again or reinstalling it.')
					print()
					print()
				end
				return false
			end

			local ok, err3 = pcall( function()
	        	fnFile( unpack( self.Arguments ) )
	        end )
	        if not ok then
	        	if err3 and err3 ~= "" then
					term.setTextColour(colours.red)
					term.setBackgroundColour(colours.black)
					term.setCursorPos(1,1)
					print(err3)
		        end
	        end
		end)

    	if not _ and err and err ~= "" then
			term.setTextColour(colours.red)
			term.setBackgroundColour(colours.black)
			term.setCursorPos(1,1)
			print(err)
		end
	end

	setfenv(executable, self.Environment)
	self.Process = coroutine.create(executable)
	self:Resume()		
end

MakeActive = function(self)
	self.Bedrock:SetActiveObject(self)
	self.Visible = true
	for i, v in ipairs(self.Bedrock:GetObjects('ProgramView')) do
		if v ~= self then
			v.Visible = false
		end
	end
	self.Bedrock:StartTimer(function()
		self.UpdateSwitcher()
	end, 0.05)
end

Resume = function(self, ...)
	local event = {...}
	local result = false
	xpcall(
		function()
			if not self.Process or coroutine.status(self.Process) == "dead" then
				return false
			end
			
			term.redirect(self.Term)
			local response = {coroutine.resume(self.Process, unpack(event))}
			if not response[1] and response[2] then
				print()
		    	term.setTextColour(colours.red)
		    	print('The program has crashed.')
		    	print(response[2])
		    	Log.e('Program crashed')
		    	Log.e(response[2])
		    	self:Kill(1)
			elseif coroutine.status(self.Process) == "dead" then
		    	print()
		    	term.setTextColour(colours.red)
		    	print('The program has finished.')
		    	self:Kill(0)
		    end
		    restoreTerm()
		    result = unpack(response)
		end,
		function(err)
			if string.find(err, "Too long without yielding") then
		    	term.redirect(self.Term)
		    	print()
		    	term.setTextColour(colours.red)
		    	print('Too long without yielding')
		    	Log.e('Too long without yielding')
		    	self:Kill(0)
		    	restoreTerm()
		    else
		    	Log.e(err)
		    	error(err)
			end
		end)
	self:ForceDraw(nil, nil, true)
	self.Bedrock:Draw()
	if result then
		return result
	end
end

Close = function(self, force)
	if force or not self.Environment.OneOS.CanClose or self.Environment.OneOS.CanClose() ~= false then
		Log.i('Closing program: '..self.Title)
		
		if self.Bedrock:GetActiveObject() == self then
			local programIndex = 2
			local name = tostring(self)
			for i, _program in ipairs(self.Bedrock:GetObject('Switcher').ProgramOrder) do
				if name == _program then
					programIndex = i
				end
			end
			self.Bedrock:RemoveObject(self)

			local programs = self.Bedrock:GetObjects('ProgramView')
			if programs[programIndex] then
				programs[programIndex]:MakeActive()
			elseif programs[programIndex - 1] then
				programs[programIndex - 1]:MakeActive()
			end
		else
			self.Bedrock:RemoveObject(self)
		end

		self.UpdateSwitcher()
		return true
	else
		Log.i('Closing program aborted: '..self.Title)
		return false
	end
end

QueueEvent = function(self, ...)
	table.insert(self.EventQueue, {...})
end

OnClick = function(self, ...)
	if self.Running then
		self:QueueEvent(...)
	else
		self:Close()
	end
end

OnDrag = function(self, ...)
	self:QueueEvent(...)
end

OnScroll = function(self, ...)
	self:QueueEvent(...)
end

OnKeyChar = function(self, ...)
	self:QueueEvent(...)
end

Kill = function(self, code)
	Log.i('Kill program "'..self.Title..'": '..code)
	term.setBackgroundColour(colours.black)
	term.setTextColour(colours.white)
	term.setCursorBlink(false)
	print('Click anywhere to close this program.')
	-- coroutine.yield(self.Process)
	self.Process = nil
	self.Running = false
end

--TODO: program close: switcher middle click

OnDraw = function(self, x, y)
	local wtb = Drawing.WriteToBuffer
	for _y, row in ipairs(self.Buffer) do
		for _x, pixel in pairs(row) do
			wtb(x+_x-1, y+_y-1, pixel[1], pixel[2], pixel[3])
		end
	end
	if self.Bedrock:GetActiveObject() == self then
		if self.CursorBlink then
			self.Bedrock.CursorPos = {x + self.CursorPos[1] - 1, y + self.CursorPos[2] - 1}
			self.Bedrock.CursorColour = self.TextColour
		else
			self.Bedrock.CursorPos = nil
		end
	end
end

ResizeBuffer = function(self)
	if #self.Buffer ~= self.Width then
		while #self.Buffer < self.Width do
			table.insert(self.Buffer, {})
		end

		while #self.Buffer > self.Width do
			table.remove(self.Buffer, #self.Buffer)
		end
	end

	for i, row in ipairs(self.Buffer) do
		while #row < self.Height do
			table.insert(row, {' ', self.TextColour, self.BackgroundColour})
		end

		while #row > self.Height do
			table.remove(row, #row)
		end
	end
end

ClearLine = function(self, y, backgroundColour)
	if y > self.Height or y < 1 then
		return
	end
	
	if not self.Buffer[y] then
		self.Buffer[y] = {}
	end

	for x = 1, self.Width do
		self.Buffer[y][x] = {' ', self.TextColour, backgroundColour}
	end
end

WriteToBuffer = function(self, character, textColour, backgroundColour)
	local x = math.floor(self.CursorPos[1])
	local y = math.floor(self.CursorPos[2])
	if y > self.Height or y < 1 or x > self.Width or x < 1 then
		return
	end
	
	if not self.Buffer[y] then
		self.Buffer[y] = {}
	end
	self.Buffer[y][x] = {character, textColour, backgroundColour}
end

MakeTerm = function(self)
	local _term = {}
	_term.native = _term

	_term.write = function(characters)
		-- Log.i('write')
		if type(characters) == 'number' then
			characters = tostring(characters)
		end
		assert(type(characters) == 'string', 'bad argument: string expected, got '..type(characters))
		self.CursorPos[1] = self.CursorPos[1] - 1
		for i = 1, #characters do
			local character = characters:sub(i,i)
			self.CursorPos[1] = self.CursorPos[1] + 1
			self:WriteToBuffer(character, self.TextColour, self.BackgroundColour)
		end
		
		self.CursorPos[1] = self.CursorPos[1] + 1
	end

	_term.clear = function()
		local buffer = {}
		local tc = self.TextColour
		local bc = self.BackgroundColour
		for y = 1, self.Height do
			buffer[y] = {}
			for x = 1, self.Width do
				buffer[y][x] = {' ', tc, bc}
			end
		end
		self.Buffer = buffer
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
		self.CursorPos[1] = math.floor( tonumber(x) ) or self.CursorPos[1]
		self.CursorPos[2] = math.floor( tonumber(y) ) or self.CursorPos[2]
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
		return self.Width, self.Height
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
				for i = 1, self.Width do
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
	end

	_term.clear()
	return _term
end