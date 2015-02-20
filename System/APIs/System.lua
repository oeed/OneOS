Bedrock = nil

local iconCache = {}

local LoadImage = function(path, global)
	local image = {
		text = {},
		textcol = {}
	}
	if fs.exists(path) then
		local _io = io
		if OneOS and global then
			_io = OneOS.IO
		end
        local file = _io.open(path, "r")
        if not file then
        	error('Error Occured. _io:'..tostring(_io)..' OneOS: '..tostring(OneOS)..' OneOS.IO'..tostring(OneOS.IO)..' io: '..tostring(io))
        end
        local sLine = file:read()
        local num = 1
        while sLine do  
            table.insert(image, num, {})
            table.insert(image.text, num, {})
            table.insert(image.textcol, num, {})
                                        
            --As we're no longer 1-1, we keep track of what index to write to
            local writeIndex = 1
            --Tells us if we've hit a 30 or 31 (BG and FG respectively)- next char specifies the curr colour
            local bgNext, fgNext = false, false
            --The current background and foreground colours
            local currBG, currFG = nil,nil
            for i=1,#sLine do
                    local nextChar = string.sub(sLine, i, i)
                    if nextChar:byte() == 30 then
                            bgNext = true
                    elseif nextChar:byte() == 31 then
                            fgNext = true
                    elseif bgNext then
                            currBG = Drawing.GetColour(nextChar)
		                    if currBG == nil then
		                    	currBG = colours.transparent
		                    end
                            bgNext = false
                    elseif fgNext then
                            currFG = Drawing.GetColour(nextChar)
		                    if currFG == nil or currFG == colours.transparent then
		                    	currFG = colours.white
		                    end
                            fgNext = false
                    else
                            if nextChar ~= " " and currFG == nil then
                                    currFG = colours.white
                            end
                            image[num][writeIndex] = currBG
                            image.textcol[num][writeIndex] = currFG
                            image.text[num][writeIndex] = nextChar
                            writeIndex = writeIndex + 1
                    end
            end
            num = num+1
            sLine = file:read()
        end
        file:close()
    else
    	Log.i('dne')
    	return nil		
	end
 	return image
end

local function readIcon(path, cacheName)
	cacheName = cacheName or path
	if not iconCache[cacheName] then
		iconCache[cacheName] = LoadImage(path, true)
	end
	return iconCache[cacheName]
end

GetIcon = function(path)
	local extension = System.RealExtension(path)

	local unknownIconPath = 'System/Resources/Icons/unknown'

	if extension and iconCache[extension] then
		return iconCache[extension]
	elseif extension and extension == 'shortcut' then
		h = fs.open(path, 'r')
		if h then
			local shortcutPointer = h.readLine()
			h.close()
			return GetIcon(shortcutPointer)
		end
		return readIcon(unknownIconPath)
	elseif extension and extension == 'program' then
		if fs.isDir(path) and fs.exists(path..'/startup') and fs.exists(path..'/icon') then
			return readIcon(path..'/icon')
		elseif not fs.isDir(path) or (fs.isDir(path) and fs.exists(path..'/startup') and not fs.exists(path..'/icon')) then
			return readIcon('System/Resources/Icons/program')
		else
			return readIcon('System/Resources/Icons/folder')
		end
	elseif fs.isDir(path) then
		if fs.exists(path..'/.FolderIcon') then
			return readIcon(path..'/.FolderIcon')
		else
			return readIcon('System/Resources/Icons/folder')
		end
	elseif extension and fs.exists('System/Resources/Icons/'..extension) and not fs.isDir('System/Resources/Icons/'..extension) then
		return readIcon('System/Resources/Icons/'..extension)
	elseif extension then
		local _path = Indexer.FindFileInFolder(extension, 'Icons')
		if _path then
			return readIcon(_path, extension)
		else
			return readIcon('System/Resources/Icons/unknown')
		end
	else
		return readIcon('System/Resources/Icons/unknown')
	end
end

UpdateSwitcher = function ()
	System.Bedrock:GetObject('Switcher'):UpdateButtons()
end

CurrentProgram = function()
	return System.Bedrock:GetActiveObject()
end

StartProgram = function(path, args, isHidden, x, y)
	args = args or {}
	local name = System.Bedrock.Helpers.RemoveExtension(fs.getName(path))
	if fs.isDir(path) then
		path = path .. '/startup'
	end
	local width = '100%'
	local height = '100%,-1'
	if x and y then
		width = 4
		height = 3
	end

	local program = System.Bedrock:AddObject({
		Type = 'ProgramView',
		X = x or 1,
		Y = y or 2,
		Width = width,
		Height = height,
		BufferWidth = '100%',
		BufferHeight = '100%',
		Path = path,
		Title = name,
		Arguments = args,
		Hidden = isHidden or false
	})
	program:MakeActive()
end

OpenFile = function(path, args, x, y)
	Log.i('Opening file: '..path)
	args = args or {}
	if fs.exists(path) then
		local extension = System.Bedrock.Helpers.Extension(path)
		Log.i(extension)
		if extension == 'shortcut' then
			h = fs.open(path, 'r')
			local shortcutPointer = h.readLine()
			local sArgs = h.readLine()
			local tArgs = {}
			if sArgs then
				for match in string.gmatch( sArgs, "[^ \t]+" ) do
					table.insert(tArgs, match)
				end
			end
			h.close()

			OpenFile(shortcutPointer, tArgs, x, y)
		elseif extension == 'program' then
			return StartProgram(path, args, nil, x, y)
		elseif fs.isDir(path) then
			StartProgram('/System/Programs/Files.program', {path}, nil, x, y)
		elseif extension then
			local _path = Indexer.FindFileInFolder(extension, 'Icons')
			if _path and not _path:find('System/Resources/Icons/') then
				OpenFile(Helpers.ParentFolder(Helpers.ParentFolder(_path)), {path}, x, y)
			else
				OpenFileWith(path) -- TODO: open file with
			end
		else
			OpenFileWith(path)
		end
	end
end

function Shutdown(force, restart, animate)
	Log.i('Trying to shutdown/restart. Restart: '..tostring(restart))
	local success = true
	if not force then
		for i, program in ipairs(System.Bedrock:GetObjects('ProgramView')) do
			if not program.Hidden and not program:Close() then
				success = false
			end
		end
	end

	if success then
		AnimateShutdown(restart, animate)
	else
		Log.w('Shutdown/restart aborted')
		Current.Desktop:SwitchTo()
		local shutdownLabel = (restart and 'restart' or 'shutdown')
		local shutdownLabelCaptital = (restart and 'Restart' or 'Shutdown')

		System.Bedrock:DisplayAlertWindow("Programs Still Open", "You have unsaved work. Save your work and close the program or click 'Force "..shutdownLabelCaptital.."'.", {'Force '..shutdownLabelCaptital, 'Cancel'}, function(value)
			if value ~= 'Cancel' then
				AnimateShutdown(restart, animate)
			end
		end)
	end
end

function AnimateShutdown(restart, animate)
	Log.w('System safely stopping.')
	if System.Bedrock.AnimationEnabled and animate then
		Log.i('Animating')
		Drawing.Clear(colours.white)
		Drawing.DrawBuffer()
		sleep(0)
		local x = 0
		local y = 0
		local w = 0
		local h = 0
		for i = 1, 8 do
			local percent = (i * 0.05)
			Drawing.Clear(colours.black)
			x = Drawing.Screen.Width * (i * 0.01)
			y = math.floor(Drawing.Screen.Height * (i * 0.05)) + 3
			w = Drawing.Screen.Width - (2 * x) + 1
			h = Drawing.Screen.Height - (2 * y) + 1

			if h < 1 then
				h = 1
			end

			Drawing.DrawBlankArea(x + 1, y, w, h, colours.white)
			Drawing.DrawBuffer()
			sleep(0)
		end

		Drawing.DrawBlankArea(x + 1, y, w, h, colours.lightGrey)
		Drawing.DrawBuffer()
		sleep(0)

		Drawing.DrawBlankArea(x + 1, y, w, h, colours.grey)
		Drawing.DrawBuffer()
		sleep(0)
		Log.i('Done animation')
	end

	term.setBackgroundColour(colours.black)
	term.clear()
	if restart then
		sleep(0.2)
		Log.i('Rebooting now.')
		os.reboot()
	else
		Log.i('Shutting down now.')
		os.shutdown()
	end
end

function Restart(force, animate)
	Shutdown(force, true, animate)
end

RealExtension = function(path)
	return Bedrock.Helpers.Extension(System.ResolveAlias(path))
end

ResolveAlias = function(path)
	return System.Bedrock.FileSystem:ResolveAlias(path)
end