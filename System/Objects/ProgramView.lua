-- drawing
Term = nil
CursorPos = nil
TextColour = colours.white
BackgroundColour = colours.black
CursorBlink = false
Buffer = {}
Buffer = {}
UpdateDrawBlacklist = {
	['EventQueue'] = true
}
BufferWidth = nil
BufferHeight = nil
Opening = false


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
	self.BufferWidth = self.Bedrock.View.Width
	self.BufferHeight = self.Bedrock.View.Height - 1
	self:Execute()

	if self.BufferWidth ~= self.Width or self.BufferHeight ~= self.Height then
		if self.Bedrock.AnimationEnabled then
			self.Opening = true
			self.Bedrock:StartTimer(function()
				self:AnimateValue('Width', nil, self.BufferWidth, nil, function()
					self.Opening = false
				end)
				self:AnimateValue('X', nil, 1)
				self:AnimateValue('Height', nil, self.BufferHeight)
				self:AnimateValue('Y', nil, 2)
			end, 0.05)
		else
			self.Width = self.BufferWidth
			self.Height = self.BufferHeight
			self.X = 1
			self.Y = 2
		end
	end
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
        		OneOS.Log.e(err2 or 'not fnFile')
				term.setTextColour(colours.red)
				term.setBackgroundColour(colours.black)
				if err2 then
					print(err2)
				else
					print('The program doesn\'t exist.')
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
				if type(self.Arguments) ~= 'table' then
					self.Arguments = {self.Arguments}
				end
	        	fnFile( unpack( self.Arguments ) )
	        end )
	        if not ok then
	        	if err3 and err3 ~= "" then
	        		OneOS.Log.e(err3)
					term.setTextColour(colours.red)
					term.setBackgroundColour(colours.black)
					term.setCursorPos(1,1)
					print(err3)
		        end
	        end
		end)

    	if not _ and err and err ~= "" then
			OneOS.Log.e(err)
			term.setTextColour(colours.red)
			term.setBackgroundColour(colours.black)
			term.setCursorPos(1,1)
			print(err)
		end
	end

	self.CursorPos = {1, 1}
	self.CursorBlink = false
	self.Buffer = {}
	self:ResizeBuffer()
	self.Term = self:MakeTerm()
	self.EventQueue = {}
	self.Timers = {}
	self.Environment = Environment:Initialise(self, shell, self.Path, self.Bedrock)
	self.Running = true

	setfenv(executable, self.Environment)
	self.Process = coroutine.create(executable)
	self:Resume()		
end

SwitcherColour = function(self)
	local colour
	if self.Environment.OneOS.ToolBarColour then
		colour = self.Environment.OneOS.ToolBarColour
	elseif self.Environment.OneOS.ToolBarColor then
		colour = self.Environment.OneOS.ToolBarColor
	end

	if not colour then
		-- get the average colour at the top row if one hasn't been set
		local occurences = {}
		for x, pixel in pairs(self.Buffer[1]) do
			occurences[pixel[3]] = occurences[pixel[3]] or 0
			occurences[pixel[3]] = occurences[pixel[3]] + 1
		end

		local mostCommon = colours.red
		local count = 0
		for col, n in pairs(occurences) do
			if n > count then
				mostCommon = col
			end
		end
		colour = mostCommon
	end

	return colour or colours.blue
end

MakeActive = function(self, previous, done)
	Log.i('Make active '.. self.Title)
	if self.Bedrock:GetActiveObject() == self then
		Log.i('Already active')
		return
	end

	previous = previous or System.CurrentProgram()
	self.Bedrock:SetActiveObject(self)		
	if not self.Opening then
		for i, v in ipairs(self.Bedrock:GetObjects('ProgramView')) do
			if v ~= self then
				v.Visible = false
			end
		end
		System.UpdateSwitcher()
		self.Visible = true
		if previous and previous.Index then
			local newIndex = self:Index()
			local oldIndex = previous:Index()

			local direction = 1
			if newIndex <= oldIndex then
				direction = -1
			end
		
			local margin = 5

			self.X = (self.Width + margin) * direction
			previous.Visible = true

			self:AnimateValue('X', (self.Width + margin) * direction, 1, Switcher.AnimationSpeed)

			previous:AnimateValue('X', 1, (self.Width + 1 + margin) * -direction, Switcher.AnimationSpeed, function()
				previous.Visible = false
			end)
		

			self.Bedrock:GetObject('Switcher'):SwitchBackground(previous:SwitcherColour(), self:SwitcherColour(), direction)

			if done then
				done()
			end
		else
			self.X = 1
			self.Bedrock:GetObject('Switcher').BackgroundColour = self:SwitcherColour()
		end
	else		
		self.Bedrock:GetObject('Switcher').BackgroundColour = self:SwitcherColour()
		System.UpdateSwitcher()
	end
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

Index = function(self)
	local name = tostring(self)
	Log.i('INDEX')
	Log.i(#self.Bedrock:GetObject('Switcher').ProgramOrder)
	for i, _program in ipairs(self.Bedrock:GetObject('Switcher').ProgramOrder) do
		Log.i(_program)
		if name == _program then
			return i + 1
		end
	end
	return 1
end

Close = function(self, force)
	if force or not self.Environment.OneOS.CanClose or self.Environment.OneOS.CanClose() ~= false then
		Log.i('Closing program: '..self.Title)
		
		if System.CurrentProgram() == self then
			local programIndex = self:Index()
			self.Bedrock:RemoveObject(self)

			local programs = self.Bedrock:GetObjects('ProgramView')
			for i, v in ipairs(programs) do
				Log.i(i .. ': '..v.Title)
			end
			Log.i('Closing, was active')		
			Log.i('Index was '..programIndex)
			if programs[programIndex] then		
			Log.i('make active '..programs[programIndex].Title)
				programs[programIndex]:MakeActive(self)
			elseif programs[programIndex - 1] then
			Log.i('make active1 '..programs[programIndex-1].Title)
				programs[programIndex - 1]:MakeActive(self)
			end
		else
			self.Bedrock:RemoveObject(self)
		end

		System.UpdateSwitcher()
		return true
	else
		Log.i('Closing program aborted: '..self.Title)
		return false
	end
end

QueueEvent = function(self, ...)
	local t = {...}
	table.insert(self.EventQueue, t)
end

OnClick = function(self, ...)
	if self.Running then
		self:Resume(...)
	else
		self:Close()
	end
end

OnDrag = function(self, ...)
	self:Resume(...)
end

OnScroll = function(self, ...)
	self:QueueEvent(...)
end

OnKeyChar = function(self, ...)
	self:QueueEvent(...)
end

Kill = function(self, code)
	Log.i('Killing program: "'..self.Title..'": '..code)
	term.setBackgroundColour(colours.black)
	term.setTextColour(colours.white)
	term.setCursorBlink(false)
	print('Click anywhere to close this program.')
	-- coroutine.yield(self.Process)
	self.Process = nil
	self.Running = false
end

Restart = function(self)
	Log.i('Restarting program: "'..self.Title)
	self:Close(-1)
	System.StartProgram(self.Path:gsub('/startup', ''))
end

OnDraw = function(self, x, y)
	local wtb = Drawing.WriteToBuffer
	if self.BufferWidth == self.Width and self.BufferHeight == self.Height then
		for _y, row in ipairs(self.Buffer) do
			for _x, pixel in pairs(row) do
				wtb(x+_x-1, y+_y-1, pixel[1], pixel[2], pixel[3])
			end
		end
	else
		local preview = self:RenderPreview(self.Width, self.Height)
		for _x, col in pairs(preview) do
			for _y, colour in ipairs(col) do
				local char = '-'
				if colour[1] == ' ' then
					char = ' '
				end
				Drawing.WriteToBuffer(x+_x, y+_y-1, char, colour[2], colour[3])
			end
		end
	end
	if System.CurrentProgram() == self then
		if self.CursorBlink then
			self.Bedrock.CursorPos = {x + self.CursorPos[1] - 1, y + self.CursorPos[2] - 1}
			self.Bedrock.CursorColour = self.TextColour
		else
			self.Bedrock.CursorPos = nil
		end
	end
end

ResizeBuffer = function(self)
	if #self.Buffer ~= self.BufferWidth then
		while #self.Buffer < self.BufferWidth do
			table.insert(self.Buffer, {})
		end

		while #self.Buffer > self.BufferWidth do
			table.remove(self.Buffer, #self.Buffer)
		end
	end

	for i, row in ipairs(self.Buffer) do
		while #row < self.BufferHeight do
			table.insert(row, {' ', self.TextColour, self.BackgroundColour})
		end

		while #row > self.BufferHeight do
			table.remove(row, #row)
		end
	end
end

ClearLine = function(self, y, backgroundColour)
	if y > self.BufferHeight or y < 1 then
		return
	end
	
	if not self.Buffer[y] then
		self.Buffer[y] = {}
	end

	for x = 1, self.BufferWidth do
		self.Buffer[y][x] = {' ', self.TextColour, backgroundColour}
	end
end

WriteToBuffer = function(self, character, textColour, backgroundColour)
	local x = math.floor(self.CursorPos[1])
	local y = math.floor(self.CursorPos[2])
	if y > self.BufferHeight or y < 1 or x > self.BufferWidth or x < 1 then
		return
	end
	
	if not self.Buffer[y] then
		self.Buffer[y] = {}
	end
	self.Buffer[y][x] = {character, textColour, backgroundColour}
end

MakeTerm = function(self)
	local _term = {}
	local native = _term
	local redirectTarget = _term

	_term.native = function()
		return native
	end

	_term.current = function()
	    return redirectTarget
	end

	_term.write = function(characters)
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

	_term.redirect = function( target )
		if target == nil or type( target ) ~= "table" then
			error( "Invalid redirect target", 2 )
		end
		for k,v in pairs( native ) do
			if type( k ) == "string" and type( v ) == "function" then
				if type( target[k] ) ~= "function" then
					target[k] = function()
						error( "Redirect object is missing method "..k..".", 2 )
					end
				end
			end
		end
		local oldRedirectTarget = redirectTarget
		redirectTarget = target
		return oldRedirectTarget
	end

	_term.clear = function()
		local buffer = {}
		local tc = self.TextColour
		local bc = self.BackgroundColour
		for y = 1, self.BufferHeight do
			buffer[y] = {}
			for x = 1, self.BufferWidth do
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
		return self.BufferWidth, self.BufferHeight
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
				for i = 1, self.BufferWidth do
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

	_term.restore = function()
		_term.redirect(native)
	end

	_term.clear()
	return _term
end

RenderPreview = function(self, width, height)
	local preview = {}
	local deltaX = self.BufferWidth / width
	local deltaY = self.BufferHeight / height

	for _x = 1, width do
		local x = self.Bedrock.Helpers.Round(1 + (_x - 1) * deltaX)
		preview[_x] = {}
		for _y = 1, height do
			local y = self.Bedrock.Helpers.Round(1 + (_y - 1) * deltaY)
			preview[_x][_y] = self.Buffer[y][x]
		end
	end
	return preview
end