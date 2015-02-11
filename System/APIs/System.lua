Bedrock = nil

local iconCache = {}

local function readIcon(path, cacheName)
	cacheName = cacheName or path
	if not iconCache[cacheName] then
		iconCache[cacheName] = Drawing.LoadImage(path, true)
	end
	return iconCache[cacheName]
end

GetIcon = function(path)
	-- path = TidyPath(path)
	local extension = System.Bedrock.Helpers.Extension(path)

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
		return readIcon('System/Resources/Icons/folder')
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
