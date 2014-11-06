--[[

This essentially allows the programs to run sandboxed. For example, os.shutdown doesn't shut the entire computer down. Instead, it simply stops the program.

]]

local errorHandler = function(program, apiName, name, value)
	if type(value) ~= 'function' then
		return value
	end
	return function(...)local response = {pcall(value, ...)}
				local ok = response[1]
				table.remove(response, 1)
				if ok then
					return unpack(response)
				else
					for i, err in ipairs(response) do
						printError(apiName .. ' Error ('..name..'): /System/API/' .. err)
				    	Log.e('['..program.Title..'] Environment Error: '..apiName .. ' Error ('..name..'): /System/API/' .. err)
					end
						
				end
			end
end

function addErrorHandler(program, api, apiName)
	local newApi = {}
	for k, v in pairs(api) do
		newApi[k] = errorHandler(program, apiName, k, v)
	end
	return newApi
end

GetCleanEnvironment = function(self)
	local cleanEnv = {}
	for k, v in pairs(cleanEnvironment) do
		cleanEnv[k] = v
	end
	return cleanEnv
end

Initialise = function(self, program, shell, path)
	local env = {}    -- the new instance
	local cleanEnv = self:GetCleanEnvironment()
	setmetatable( env, {__index = cleanEnv} )
	env._G = cleanEnv
	env.fs = addErrorHandler(program, self.FS(env, program, path), 'FS API')
	env.io = addErrorHandler(program, self.IO(env, program, path), 'IO API')
	env.os = addErrorHandler(program, self.OS(env, program, path), 'OS API')
	env.loadfile = function( _sFile)
		local file = env.fs.open( _sFile, "r")
		if file then
			local func, err = loadstring( file.readAll(), env.fs.getName( _sFile) )
			file.close()
			return func, err
		end
		return nil, "File not found"
	end

	env.dofile = function( _sFile )
		local fnFile, e = env.loadfile( _sFile )
		if fnFile then
			setfenv( fnFile, getfenv(2) )
			return fnFile()
		else
			error( e, 2 )
		end
	end

	local tColourLookup = {}
	for n=1,16 do
		tColourLookup[ string.byte( "0123456789abcdef",n,n ) ] = 2^(n-1)
	end

	env.textutils.slowWrite = function( sText, nRate )
		nRate = nRate or 20
		if nRate < 0 then
			error( "rate must be positive" )
		end
		local nSleep = 1 / nRate
			
		sText = tostring( sText )
		local x,y = term.getCursorPos(x,y)
		local len = string.len( sText )
		
		for n=1,len do
			term.setCursorPos( x, y )
			env.os.sleep( nSleep )
			local nLines = write( string.sub( sText, 1, n ) )
			local newX, newY = term.getCursorPos()
			y = newY - nLines
		end
	end

	env.textutils.slowPrint = function( sText, nRate )
		env.textutils.slowWrite( sText, nRate)
		print()
	end

	env.paintutils.loadImage = function( sPath )
		local relPath = Helpers.RemoveFileName(path) .. sPath
		local tImage = {}
		if fs.exists( relPath ) then
			local file = io.open(relPath, "r" )
			local sLine = file:read()
			while sLine do
				local tLine = {}
				for x=1,sLine:len() do
					tLine[x] = tColourLookup[ string.byte(sLine,x,x) ] or 0
				end
				table.insert( tImage, tLine )
				sLine = file:read()
			end
			file:close()
			return tImage
		end
		return nil
	end

	env.shell = {}
	local shellEnv = {}
	setmetatable( shellEnv, { __index = env } )
	setfenv(self.Shell, shellEnv)
	self.Shell(env, program, shell, path, Helpers, os.run)
	env.shell = addErrorHandler(program, shellEnv, 'Shell')
	env.OneOS = addErrorHandler(program, self.OneOS(env, program, path), 'OneOS API')
	env.sleep = env.os.sleep
	return env
end

IO = function(env, program, path)
	local relPath = Helpers.RemoveFileName(path)
	return {
		input = io.input,
		output = io.output,
		type = io.type,
		close = io.close,
		write = io.write,
		flush = io.flush,
		lines = io.lines,
		read = io.read,
		open = function(_path, mode)
			return io.open(relPath .. _path, mode)
		end
	}
end

OneOS = function(env, program, path)
	local h = fs.open('/System/.version', 'r')
	local version = h.readAll()
	h.close()

	local tAPIsLoading = {}
	return {
		ToolBarColour = colours.white,
		ToolBarColor = colours.white,
		ToolBarTextColor = colours.black,
		ToolBarTextColour = colours.black,
		OpenFile = Helpers.OpenFile,
		Helpers = Helpers,
		Settings = Settings,
		Version = version,
		Restart = function(f)Restart(f, false)end,
		Reboot = function(f)Restart(f, false)end,
		Shutdown = function(f)Shutdown(f, false, true)end,
		KillSystem = function()os.reboot()end,
		Clipboard = Clipboard,
		FS = fs,
		OSRun = os.run,
		Shell = shell,
		ProgramLocation = program.Path,
		SetTitle = function(title)
			if title and type(title) == 'string' then
				program.Title = title
			end
			UpdateOverlay()
		end,
		CanClose = function()end,
		Close = function()
			program:Close(true)
		end,
		Run = function(path, ...)
			local args = {...}
			if fs.isDir(path) and fs.exists(path..'/startup') then
				Program:Initialise(shell, path..'/startup', Helpers.RemoveExtension(fs.getName(path)), args)
			elseif not fs.isDir(path) then
				Program:Initialise(shell, path, Helpers.RemoveExtension(fs.getName(path)), args)
			end
		end,
		LoadAPI = function(_sPath, global)
			local sName = Helpers.RemoveExtension(fs.getName( _sPath))
			if tAPIsLoading[sName] == true then
				env.printError( "API "..sName.." is already being loaded" )
				return false
			end
			tAPIsLoading[sName] = true
				
			local tEnv = {}
			setmetatable( tEnv, { __index = env } )
			if not global == false then
				tEnv.fs = fs
			end
			local fnAPI, err = loadfile( _sPath)
			if fnAPI then
				setfenv( fnAPI, tEnv )
				fnAPI()
			else
				printError( err )
		        tAPIsLoading[sName] = nil
				return false
			end
			
			local tAPI = {}
			for k,v in pairs( tEnv ) do
				tAPI[k] =  v
			end
			
			env[sName] = tAPI
			tAPIsLoading[sName] = nil
			return true
		end,
		LoadFile = function( _sFile)
			local file = fs.open( _sFile, "r")
			if file then
				local func, err = loadstring( file.readAll(), fs.getName( _sFile) )
				file.close()
				return func, err
			end
			return nil, "File not found"
		end,
		LoadString = loadstring,
		IO = io,
		DoesRunAtStartup = function()
			if not Settings:GetValues()['StartupProgram'] then
				return false
			end
			return Helpers.TidyPath('/Programs/'..Settings:GetValues()['StartupProgram']..'/startup') == Helpers.TidyPath(path)
		end,
		RequestRunAtStartup = function()
			if Settings:GetValues()['StartupProgram'] and Helpers.TidyPath('/Programs/'..Settings:GetValues()['StartupProgram']..'/startup') == Helpers.TidyPath(path) then
				return
			end
			local settings = Settings:GetValues()
			local onBlacklist = false
			local h = fs.open('/System/.StartupBlacklist.settings', 'r')
			if h then
				local blacklist = textutils.unserialize(h.readAll())
				h.close()
				for i, v in ipairs(blacklist) do
					if v == Helpers.TidyPath(path) then
						onBlacklist = true
						return
					end
				end
			end

			if not settings['StartupProgram'] or not Helpers.TidyPath('/Programs/'..settings['StartupProgram']..'/startup') == Helpers.TidyPath(path) then
				Current.Bedrock:DisplayAlertWindow("Run at startup?", "Would you like run "..Helpers.RemoveExtension(fs.getName(Helpers.RemoveFileName(path))).." when you turn your computer on?", {"Yes", "No", "Never Ask"}, function(value)
					if value == 'Yes' then
						Settings:SetValue('StartupProgram', fs.getName(Helpers.RemoveFileName(path)))
					elseif value == 'Never Ask' then
						local h = fs.open('/System/.StartupBlacklist.settings', 'r')
						local blacklist = {}
						if h then
							blacklist = textutils.unserialize(h.readAll())
							h.close()
						end
						table.insert(blacklist, Helpers.TidyPath(path))
						local h = fs.open('/System/.StartupBlacklist.settings', 'w')
						if h then
							h.write(textutils.serialize(blacklist))
							h.close()
						end	
					end
				end)
			end
		end,
		Log = {
			i = function(msg)Log.i('['..program.Title..'] '..tostring(msg))end,
			w = function(msg)Log.w('['..program.Title..'] '..tostring(msg))end,
			e = function(msg)Log.e('['..program.Title..'] '..tostring(msg))end,
		}
	}
end

FS = function(env, program, path)
	local function doIndex()
		Current.Bedrock:StartTimer(Indexer.DoIndex, 4)
	end
	local relPath = Helpers.RemoveFileName(path)
	local list = {}
	for k, f in pairs(fs) do
		if k ~= 'open' and k ~= 'combine' and k ~= 'copy' and k ~= 'move' and k ~= 'delete' and k ~= 'makeDir' then
			list[k] = function(_path)
				return fs[k](relPath .. _path)
			end
		elseif k == 'delete' or k == 'makeDir' then
			list[k] = function(_path)
				doIndex()
				return fs[k](relPath .. _path)
			end
		elseif k == 'copy' or k == 'move' then
			list[k] = function(_path, _path2)
				doIndex()
				return fs[k](relPath .. _path, relPath .. _path2)
			end
		elseif k == 'combine' then
			list[k] = function(_path, _path2)
				return fs[k](_path, _path2)
			end
		elseif k == 'open' then
			list[k] = function(_path, mode)
				if mode ~= 'r' then 
					doIndex()
				end
				return fs[k](relPath .. _path, mode)
			end
		end
	end
	return list
end

OS = function(env, program, path)
	local tAPIsLoading = {}
	_os = {

		version = os.version,

		getComputerID = os.getComputerID,

		getComputerLabel = os.getComputerLabel,

		setComputerLabel = os.setComputerLabel,

		run = function( _tEnv, _sPath, ... )
		    local tArgs = { ... }
		    local fnFile, err = loadfile( Helpers.RemoveFileName(path) .. '/' .. _sPath )
		    if fnFile then
		        local tEnv = _tEnv
		        --setmetatable( tEnv, { __index = function(t,k) return _G[k] end } )
				setmetatable( tEnv, { __index = env} )
		        setfenv( fnFile, tEnv )
		        local ok, err = pcall( function()
		        	fnFile( unpack( tArgs ) )
		        end )
		        if not ok then
		        	if err and err ~= "" then
			        	printError( err )
			        end
		        	return false
		        end
		        return true
		    end
		    if err and err ~= "" then
				printError( err )
			end
		    return false
		end,

		loadAPI = function(_sPath)
			local _fs = env.fs

			local sName = _fs.getName( _sPath)
			if tAPIsLoading[sName] == true then
				env.printError( "API "..sName.." is already being loaded" )
				return false
			end
			tAPIsLoading[sName] = true
				
			local tEnv = {}
			setmetatable( tEnv, { __index = env } )
			tEnv.fs = _fs
			local fnAPI, err = env.loadfile( _sPath)
			if fnAPI then
				setfenv( fnAPI, tEnv )
				fnAPI()
			else
				printError( err )
		        tAPIsLoading[sName] = nil
				return false
			end
			
			local tAPI = {}
			for k,v in pairs( tEnv ) do
				tAPI[k] =  v
			end
			
			env[sName] = tAPI

			tAPIsLoading[sName] = nil
			return true
		end,

		unloadAPI = function ( _sName )
			if _sName ~= "_G" and type(env[_sName]) == "table" then
				env[_sName] = nil
			end
		end,

		pullEvent = function(target)
			local eventData = nil
			local wait = true
			while wait do
				eventData = { coroutine.yield(target) }
				if eventData[1] == "terminate" then
					error( "Terminated", 0 )
				elseif target == nil or eventData[1] == target then
					wait = false
				end
			end
			return unpack( eventData )
		end,

		pullEventRaw = function(target)
			local eventData = nil
			local wait = true
			while wait do
				eventData = { coroutine.yield(target) }
				if target == nil or eventData[1] == target then
					wait = false
				end
			end
			return unpack( eventData )
		end,

		queueEvent = function(...)
			program:QueueEvent(...)
		end,

		clock = function()
			return os.clock()
		end,

		startTimer = function(time)
			local timer = os.startTimer(time)
			table.insert(program.Timers, timer)
			return timer
		end,

		time = function()
			return os.time()
		end,

		sleep = function(time)
		    local timer = _os.startTimer( time )
			repeat
				local sEvent, param = _os.pullEvent( "timer" )
			until param == timer
		end,

		day = function()
			return os.day()
		end,

		setAlarm = os.setAlarm,

		shutdown = function()
			program:Close()
		end,

		reboot = function()
			program:Restart()
		end
	}
	return _os
end

Shell = function(env, program, nativeShell, appPath, Helpers, osrun)
	
	local parentShell = nil--nativeShell

	local bExit = false
	local sDir = (parentShell and parentShell.dir()) or ""
	local sPath = (parentShell and parentShell.path()) or ".:/rom/programs"
	local tAliases = {
		ls = "list",
		dir = "list",
		cp = "copy",
		mv = "move",
		rm = "delete",
		preview = "edit"
	}
	local tProgramStack = {fs.getName(appPath)}

	-- Colours
	local promptColour, textColour, bgColour
	if env.term.isColour() then
		promptColour = colours.yellow
		textColour = colours.white
		bgColour = colours.black
	else
		promptColour = colours.white
		textColour = colours.white
		bgColour = colours.black
	end


	local function _run( _sCommand, ... )
		local sPath = nativeShell.resolveProgram(_sCommand)
		if sPath == nil or sPath:sub(1,3) ~= 'rom' then
			sPath = nativeShell.resolveProgram(Helpers.RemoveFileName(appPath) .. '/' ..  _sCommand )
		end

		if sPath ~= nil then
			tProgramStack[#tProgramStack + 1] = sPath
	   		local result = osrun( env, sPath, ... )
			tProgramStack[#tProgramStack] = nil
			return result
	   	else
	    	env.printError( "No such program" )
	    	return false
	    end
	end

	local function runLine( _sLine )
		local tWords = {}
		for match in string.gmatch( _sLine, "[^ \t]+" ) do
			table.insert( tWords, match )
		end

		local sCommand = tWords[1]
		if sCommand then
			return _run( sCommand, unpack( tWords, 2 ) )
		end
		return false
	end

	function run( ... )
		return runLine( table.concat( { ... }, " " ) )
	end

	function exit()
	    bExit = true
	end

	function dir()
		return sDir
	end

	function setDir( _sDir )
		sDir = _sDir
	end

	function path()
		return sPath
	end

	function setPath( _sPath )
		sPath = _sPath
	end

	function resolve( _sPath)
		local sStartChar = string.sub( _sPath, 1, 1 )
		if sStartChar == "/" or sStartChar == "\\" then
			return env.fs.combine( "", _sPath)
		else
			return env.fs.combine( sDir, _sPath)
		end
	end

	function resolveProgram( _sCommand)
		-- Substitute aliases firsts
		if tAliases[ _sCommand ] ~= nil then
			_sCommand = tAliases[ _sCommand ]
		end

	    -- If the path is a global path, use it directly
	    local sStartChar = string.sub( _sCommand, 1, 1 )
	    if sStartChar == "/" or sStartChar == "\\" then
	    	local sPath = fs.combine( "", _sCommand )
	    	if fs.exists( sPath) and not fs.isDir( sPath) then
				return sPath
	    	end
			return nil
	    end

	    function lookInFolder(_fPath)
	    	for i, f in ipairs(fs.list(_fPath, true)) do
	    		if not fs.isDir( fs.combine( _fPath, f), true) then
					if f == _sCommand then
						return fs.combine( _fPath, f)
					end
				end
	    	end
	    end

	    local list = {Helpers.RemoveFileName(appPath), '/rom/programs/', '/rom/programs/color/', '/rom/programs/computer/'}
	    if http then
	    	table.insert(list, '/rom/programs/http/')
	    end
	    if turtle then
	    	table.insert(list, '/rom/programs/turtle/')
	    end
	    for i, p in ipairs(list) do
	    	local r = lookInFolder(p)
	    	if r then
	    		return r
	    	end
	    end

		-- Not found
		return nil
	end

	function programs( _bIncludeHidden )
		local tItems = {}

	    local function addFolder(_fPath)
	    	for i, f in ipairs(fs.list(_fPath, true)) do
	    		if not fs.isDir( fs.combine( _fPath, f), true) then
					if (_bIncludeHidden or string.sub( f, 1, 1 ) ~= ".") then
						tItems[ f ] = true
					end
				end
	    	end
	    end

	    addFolder('/rom/programs/')
	    addFolder('/rom/programs/color/')
	    addFolder('/rom/programs/computer/')
	    if http then
	    	addFolder('/rom/programs/http/')
	    end
	    if turtle then
	    	addFolder('/rom/programs/turtle/')
	    end
	    addFolder(Helpers.RemoveFileName(appPath))

		-- Sort and return
		local tItemList = {}
		for sItem, b in pairs( tItems ) do
			table.insert( tItemList, sItem )
		end
		table.sort( tItemList )
		return tItemList
	end

	function getRunningProgram()
		if #tProgramStack > 0 then
			return tProgramStack[#tProgramStack]
		end
		return nil
	end

	function setAlias( _sCommand, _sProgram )
		tAliases[ _sCommand ] = _sProgram
	end

	function clearAlias( _sCommand )
		tAliases[ _sCommand ] = nil
	end

	function aliases()
		-- Add aliases
		local tCopy = {}
		for sAlias, sCommand in pairs( tAliases ) do
			tCopy[sAlias] = sCommand
		end
		return tCopy
	end
end