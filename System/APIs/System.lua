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

Initialise = function()
	System.Settings = Settings:Initialise()
	System.Clipboard = Clipboard:Initialise(System.Bedrock)

	local h = fs.open('/System/.version', 'r')
	if h then
		System.Version = h.readAll()
		h.close()
	end

	System.Settings:OnUpdate(function(key)
		if key == 'UseAnimations' then
			System.Bedrock.AnimationEnabled = System.Settings.UseAnimations
		end
	end)
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
			return readIcon('System/Resources/Icons/bundle')
		end
	elseif extension and fs.exists('System/Resources/Icons/'..extension) and not fs.isDir('System/Resources/Icons/'..extension) then
		return readIcon('System/Resources/Icons/'..extension)
	elseif extension and #extension ~= 0 then
		local _path = Indexer.FindFileInFolder(extension, 'Icons')
		if _path then
			return readIcon(_path, extension)
		elseif fs.isDir(path) then
			return readIcon('System/Resources/Icons/bundle')
		else
			return readIcon('System/Resources/Icons/unknown')
		end
	elseif fs.isDir(path) then
		if fs.exists(path..'/.FolderIcon') then
			return readIcon(path..'/.FolderIcon')
		else
			return readIcon('System/Resources/Icons/folder')
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
		local extension = System.RealExtension(path)
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
				OpenFileWith(path)
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
		System.Bedrock:AddObject({
			X = 1,
			Y = 1,
			Height = '100%',
			Width = '100%',
			BackgroundColour = 'black',
			Type = 'View'
		})

		System.Bedrock:RemoveObjects()
		System.Bedrock:Draw()

		term.setBackgroundColour(colours.black)
		term.clear()
		Log.i('Animating')
		Drawing.Clear(colours.black)
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

MakeAlias = function(path, pointer)
	return System.Bedrock.FileSystem:MakeAlias(path, pointer)
end

AddFavourite = function(path)
	local newPath = '/Favourites/' .. System.Bedrock.Helpers.RemoveExtension(fs.getName(path))
	System.MakeAlias(newPath, path)
end

AddToDesktop = function(path)
	local newPath = '/Desktop/' .. System.Bedrock.Helpers.RemoveExtension(fs.getName(path))
	System.MakeAlias(newPath, path)
end

RenameFile = function(path, done, bedrock)
	bedrock = bedrock or System.Bedrock
	path = bedrock.Helpers.TidyPath(path)
	local function showRename()
		local ext = ''
		if fs.getName(path):find('%.') then
			ext = '.'..bedrock.Helpers.Extension(path)
		end

		Log.i('blah')
		Log.i(ext)
		bedrock:DisplayTextBoxWindow('Rename '..fs.getName(path), "Enter the new file name.", function(success, value)
			if success and #value ~= 0 then
				local _, err = pcall(function()fs.move(path, bedrock.Helpers.RemoveFileName(path)..value) if done then done() end end)
				if err then
					bedrock:DisplayAlertWindow('Rename Failed!', 'Error: '..err, {'Ok'})
				end
			end
		end, ext)
	end
	
	if path == '/startup' or path:find('/System/') or path == '/Desktop/Documents/' or path == '/Desktop/' then
		bedrock:DisplayAlertWindow('Important File!', 'Renaming this file might cause your computer to stop working. Are you sure you want to rename it?', {'Rename', 'Cancel'}, function(text)
			if text == 'Rename' then
				showRename()
			end
		end)
	else
		showRename()
	end
end

DeleteFile = function(path, done, bedrock)
	bedrock = bedrock or System.Bedrock
	path = bedrock.Helpers.TidyPath(path)
	local function doDelete()
		local _, err = pcall(function()fs.delete(path) if done then done() end end)
		if err then
			bedrock:DisplayAlertWindow('Delete Failed!', 'Error: '..err, {'Ok'})
		end
	end
	
	if path == '/startup' or path:find('/System/') or path == '/Desktop/Documents/' or path == '/Desktop/' then
		bedrock:DisplayAlertWindow('Important File!', 'Deleting this file might cause your computer to stop working. Are you sure you want to delete it?', {'Delete', 'Cancel'}, function(text)
			if text == 'Delete' then
				doDelete()
			end
		end)
	else
		bedrock:DisplayAlertWindow('Delete File?', 'Are you sure you want to permanently "' .. fs.getName(path) .. '"?', {'Delete', 'Cancel'}, function(text)
			if text == 'Delete' then
				doDelete()
			end
		end)
	end
end

NewFile = function(basePath, done, bedrock)
	bedrock = bedrock or System.Bedrock
	basePath = bedrock.Helpers.TidyPath(basePath)
	bedrock:DisplayTextBoxWindow('Create New File', "Enter the new file name.", function(success, value)
		if success and #value ~= 0 then
			local _, err = pcall(function()
				local h = fs.open(basePath..value, 'w')
				h.close()
				if done then done() end
			end)
			if err then
				bedrock:DisplayAlertWindow('File Creation Failed!', 'Error: '..err, {'Ok'})
			end
		end
	end)
end

NewFolder = function(basePath, done, bedrock)
	bedrock = bedrock or System.Bedrock
	basePath = bedrock.Helpers.TidyPath(basePath)
	bedrock:DisplayTextBoxWindow('Create New Folder', "Enter the new folder name.", function(success, value)
		if success and #value ~= 0 then
			local _, err = pcall(function()
				fs.makeDir(basePath..value)
				if done then done() end
			end)
			if err then
				bedrock:DisplayAlertWindow('File Creation Failed!', 'Error: '..err, {'Ok'})
			end
		end
	end)
end

OpenFileWith = function(path, bedrock)
	bedrock = bedrock or System.Bedrock
	path = bedrock.Helpers.TidyPath(path)
	local text = 'Choose the program you want to open this file with.'
	local height = #bedrock.Helpers.WrapText(text, 26)

	local items = {}

	for i, v in ipairs(fs.list('Programs/')) do
		if string.sub( v, 1, 1 ) ~= '.' then
			table.insert(items, v)
		end
	end

	local children = {
		{
			Y = "100%,-1",
			X = "100%,-6",
			Name = "OpenButton",
			Type = "Button",
			Text = "Open",
			OnClick = function()
				local selected = bedrock.Window:GetObject('ListView').Selected
				if selected then
					System.OpenFile('Programs/' .. selected.Text, {path})
					bedrock.Window:Close()
				end
			end
		},
		{
			Y = "100%,-1",
			X = "100%,-15",
			Name = "CancelButton",
			Type = "Button",
			Text = "Cancel",
			OnClick = function()
				bedrock.Window:Close()
			end
		},
	    {
			Y = 6,
			X = 2,
			Height = "100%,-8",
			Width = "100%,-2",
			Name = "ListView",
			Type = "ListView",
			TextColour = 128,
			BackgroundColour = 0,
			CanSelect = true,
			Items = items,
	    },
	    {
			Y = 2,
			X = 2,
			Width = "100%,-2",
			Height = height,
			Name = "Label",
			Type = "Label",
			Text = text
		}
	}

	local view = {
		Children=children,
		Width=28,
		Height=10+height
	}
	bedrock:DisplayWindow(view, 'Open With')
end

OpenFileArgs = function(path, bedrock)
	bedrock = bedrock or System.Bedrock
	path = bedrock.Helpers.TidyPath(path)

					
	bedrock:DisplayTextBoxWindow('Open With Arguments', "Enter the command line arguments.", function(success, value)
		if success and #value ~= 0 then
			System.OpenFile(path, bedrock.Helpers.Split(value, ' '))
		end
	end, ext)
end

SetBootArgs = function(value)
	local h = fs.open('/System/.bootargs', 'w')
	if h then
		h.write(value)
		h.close()
	end
end

ClearBootArgs = function()
	fs.delete('/System/.bootargs')
end