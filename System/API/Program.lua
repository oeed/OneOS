Process = nil
EventQueue = {}
Timers = {}
AppRedirect = nil
Running = true
Hidden = false
local _args = {}
Initialise = function(self, shell, path, title, args)
	Log.i('Starting program: '..title..' ('..path..')')
	local new = {}    -- the new instance
	setmetatable( new, {__index = self} )
	_args = args
	new.Title = title or path
	new.Path = path
	new.Timers = {}
	new.EventQueue = {}
	new.AppRedirect = AppRedirect:Initialise(new)
	new.Environment = Environment:Initialise(new, shell, path)
	new.Running = true
	if args.isHidden then
		new.Hidden = true
	end
	
	local executable = function()
		local _, err = pcall(function()
			--os.run(new.Environment, path, unpack(args))
			local fnFile, err2 = nil
			local h = OneOS.FS.open( path, "r")
			if h then
				fnFile, err2 = loadstring( h.readAll(), OneOS.FS.getName(path) )
				if err2 then
					err2 = err2:gsub("^.-: %[string \"","")
					err2 = err2:gsub('"%]',"")
				end
				h.close()
			end
	        local tEnv = new.Environment
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
	        	fnFile( unpack( args ) )
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

	table.insert(Current.Programs, new)
	Current.Program = new

	if executable then
		setfenv(executable, new.Environment)
		new.Process = coroutine.create(executable)
		new:Resume()		
	else
		printError('Failed to load program: '..path)
	end
	Current.ProgramView:ForceDraw()

	return new
end

Restart = function(self)
	local path = self.Path
	local title = self.Title
	self:Close()
	Helpers.LaunchProgram(path, {}, title)
end

QueueEvent = function(self, ...)
	table.insert(self.EventQueue, {...})
end

Click = function(self, event, button, x, y)
	if self.Running and self.Process and coroutine.status(self.Process) ~= "dead" then
		self:QueueEvent(event, button, x, y)
	else
		self:Close()
	end
end

Resume = function(self, ...)
	local event = {...}
	local result = false
	xpcall(function()
			if not self.Process or coroutine.status(self.Process) == "dead" then
				return false
			end
			
			term.redirect(self.AppRedirect.Term)
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
		    --Drawing.DrawBuffer()
		    result = unpack(response)
		end, function(err)
			if string.find(err, "Too long without yielding") then
		    	term.redirect(self.AppRedirect.Term)
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
	if result then
		return result
	end
end

Kill = function(self, code)
	term.setBackgroundColour(colours.black)
	term.setTextColour(colours.white)
	term.setCursorBlink(false)
	print('Click anywhere to close this program.')
	for i, program in ipairs(Current.Programs) do
		if program == self then
			Current.Programs[i].Running = false
			if code ~= 0 then
				coroutine.yield(Current.Programs[i].Process)
			end
			Current.Programs[i].Process = nil
		end
	end
end

Close = function(self, force)
	if force or not self.Environment.OneOS.CanClose or self.Environment.OneOS.CanClose() ~= false then
		Log.i('Closing program: '..self.Title)
		if self == Current.Program then
			Current.Program = nil
		end
		for i, program in ipairs(Current.Programs) do
			if program == self then
				table.remove(Current.Programs, i)
				break
			end
		end
		UpdateOverlay()
		Current.ProgramView:ForceDraw()
		return true
	else
		Log.i('Closing program aborted: '..self.Title)
		return false
	end
end

SwitchTo = function(self)
	if Current.Program ~= self then
		Current.Program = self
		Current.ProgramView:ForceDraw()
	end
end

RenderPreview = function(self, width, height)
	local preview = {}
	local deltaX = self.AppRedirect.Size[1] / width
	local deltaY = self.AppRedirect.Size[2] / height

	for _x = 1, width do
		local x = Helpers.Round(1 + (_x - 1) * deltaX)
		preview[_x] = {}
		for _y = 1, height do
			local y = Helpers.Round(1 + (_y - 1) * deltaY)
			preview[_x][_y] = self.AppRedirect.Buffer[y][x]
		end
	end
	return preview
end