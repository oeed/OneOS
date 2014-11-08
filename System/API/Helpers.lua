local IconCache = {}

function LaunchProgram(path, args, title)
	return Program:Initialise(shell, path, title, args)
end

OpenFile = function(path, args)
	args = args or {}
	if fs.exists(path) then
		if Current.Bedrock then
			local centrePoint = Current.Bedrock:GetObject('CentrePoint')
			if centrePoint and centrePoint.Visible then
				centrePoint:Hide()
			end
		end

		local extension = Helpers.Extension(path)
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

			Helpers.OpenFile(shortcutPointer, tArgs)
		elseif extension == 'program' and fs.isDir(path) and fs.exists(path..'/startup') then
			return LaunchProgram(path..'/startup', args, Helpers.RemoveExtension(fs.getName(path)))
		elseif extension == 'program' and not fs.isDir(path) then
			return LaunchProgram(path, args, Helpers.RemoveExtension(fs.getName(path)))
		elseif fs.isDir(path) then
			LaunchProgram('/System/Programs/Files.program/startup', {path}, 'Files')
		elseif extension then
			local _path = Indexer.FindFileInFolder(extension, 'Icons')
			if _path and not _path:find('System/Images/Icons/') then
				Helpers.OpenFile(Helpers.ParentFolder(Helpers.ParentFolder(_path)), {path})
			else
				OpenFileWith(path)
			end
		else
			OpenFileWith(path)
		end
	end
end

ParentFolder = function(path)
	local folderName = fs.getName(path)
	return path:sub(1, #path-#folderName-1)
end

ListPrograms = function()
	local programs = {}

	for i, v in ipairs(fs.list('Programs/')) do
		if string.sub( v, 1, 1 ) ~= '.' then
			table.insert(programs, v)
		end
	end

	return programs
end

ReadIcon = function(path, cacheName)
	cacheName = cacheName or path
	if not IconCache[cacheName] then
		IconCache[cacheName] = Drawing.LoadImage(path, true)
	end
	return IconCache[cacheName]
end

Split = function(str,sep)
    sep=sep or'/'
    return str:match("(.*"..sep..")")
end

Extension = function(path, addDot)
	if not path then
		return nil
	elseif not string.find(fs.getName(path), '%.') then
		if not addDot then
			return fs.getName(path)
		else
			return ''
		end
	else
		local _path = path
		if path:sub(#path) == '/' then
			_path = path:sub(1,#path-1)
		end
		local extension = _path:gmatch('%.[0-9a-z]+$')()
		if extension then
			extension = extension:sub(2)
		else
			--extension = nil
			return ''
		end
		if addDot then
			extension = '.'..extension
		end
		return extension:lower()
	end
end

RemoveExtension = function(path)
	--local name = string.match(fs.getName(path), '(%a+)%.?.-')
	if path:sub(1,1) == '.' then
		return path
	end
	local extension = Helpers.Extension(path)
	if extension == path then
		return fs.getName(path)
	end
	return string.gsub(path, extension, ''):sub(1, -2)
end

RemoveFileName = function(path)
	if string.sub(path, -1) == '/' then
		path = string.sub(path, 1, -2)
	end
	local v = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
	if type(v) == 'string' then
		return v
	end
	return v[1]
end

IsDirectory = function(path)
	return fs.isDir(path) and Helpers.Extension(path) ~= 'program'
end

IconForFile = function(path)
	path = TidyPath(path)
	local extension = Helpers.Extension(path)
	if extension and IconCache[extension] then
		return IconCache[extension]
	elseif extension and extension == 'shortcut' then
		h = fs.open(path, 'r')
		if h then
			local shortcutPointer = h.readLine()
			h.close()
			return Helpers.IconForFile(shortcutPointer)
		end
		return ReadIcon('System/Images/Icons/unknown')
	elseif extension and extension == 'program' then
		if fs.isDir(path) and fs.exists(path..'/startup') and fs.exists(path..'/icon') then
			return ReadIcon(path..'/icon')
		elseif not fs.isDir(path) or (fs.isDir(path) and fs.exists(path..'/startup') and not fs.exists(path..'/icon')) then
			return ReadIcon('System/Images/Icons/program')
		else
			return ReadIcon('System/Images/Icons/folder')
		end
	elseif fs.isDir(path) then
		return ReadIcon('System/Images/Icons/folder')
	elseif extension and fs.exists('System/Images/Icons/'..extension) and not fs.isDir('System/Images/Icons/'..extension) then
		return ReadIcon('System/Images/Icons/'..extension)
	elseif extension then
		local _path = Indexer.FindFileInFolder(extension, 'Icons')
		if _path then
			return ReadIcon(_path, extension)
		else
			return ReadIcon('System/Images/Icons/unknown')
		end
	else
		return ReadIcon('System/Images/Icons/unknown')
	end
end

TruncateString = function(sString, maxLength)
	if #sString > maxLength then
		sString = sString:sub(1,maxLength-3)
		if sString:sub(-1) == ' ' then
			sString = sString:sub(1,maxLength-4)
		end
		sString = sString  .. '...'
	end
	return sString
end

TruncateStringStart = function(sString, maxLength)
	local len = #sString
	if #sString > maxLength then
		sString = sString:sub(len - maxLength, len - 3)
		if sString:sub(-1) == ' ' then
			sString = sString:sub(len - maxLength, len - 4)
		end
		sString = '...' .. sString
	end
	return sString
end

WrapText = function(text, maxWidth)
	local lines = {''}
    for word, space in text:gmatch('(%S+)(%s*)') do
            local temp = lines[#lines] .. word .. space:gsub('\n','')
            if #temp > maxWidth then
                    table.insert(lines, '')
            end
            if space:find('\n') then
                    lines[#lines] = lines[#lines] .. word
                    
                    space = space:gsub('\n', function()
                            table.insert(lines, '')
                            return ''
                    end)
            else
                    lines[#lines] = lines[#lines] .. word .. space
            end
    end
	return lines
end

MakeShortcut = function(path)
	path = TidyPath(path)
	local name = Helpers.RemoveExtension(fs.getName(path))
	local f = fs.open('Desktop/'..name..'.shortcut', 'w')
	f.write(path)
	f.close()
end

TidyPath = function(path)
	path = '/'..path
	if fs.exists(path) and fs.isDir(path) then
		path = path .. '/'
	end

	path, n = path:gsub("//", "/")
	while n > 0 do
		path, n = path:gsub("//", "/")
	end
	return path
end

Capitalise = function(str)
	return str:sub(1, 1):upper() .. str:sub(2, -1)
end

RenameFile = function(path, done, bedrock)
	bedrock = bedrock or Current.Bedrock
	path = TidyPath(path)
	local function showRename()
		local ext = ''
		if fs.getName(path):find('%.') then
			ext = '.'..Extension(path)
		end
		bedrock:DisplayTextBoxWindow('Rename '..fs.getName(path), "Enter the new file name.", function(success, value)
			if success and #value ~= 0 then
				Indexer.RefreshIndex()
				local _, err = pcall(function()fs.move(path, RemoveFileName(path)..value) if done then done() end end)
				if err then
					bedrock:DisplayAlertWindow('Rename Failed!', 'Error: '..err, {'Ok'})
				end
			end
		end, ext, true)
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
	bedrock = bedrock or Current.Bedrock
	path = TidyPath(path)
	local function doDelete()
		local _, err = pcall(function()fs.delete(path) Indexer.RefreshIndex() if done then done() end end)
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
		bedrock:DisplayAlertWindow('Delete File?', 'Are you sure you want to permanently delete this file?', {'Delete', 'Cancel'}, function(text)
			if text == 'Delete' then
				doDelete()
			end
		end)
	end
end

NewFile = function(basePath, done, bedrock)
	bedrock = bedrock or Current.Bedrock
	basePath = TidyPath(basePath)
	bedrock:DisplayTextBoxWindow('Create New File', "Enter the new file name.", function(success, value)
		if success and #value ~= 0 then
			Indexer.RefreshIndex()
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
	bedrock = bedrock or Current.Bedrock
	basePath = TidyPath(basePath)
	bedrock:DisplayTextBoxWindow('Create New Folder', "Enter the new folder name.", function(success, value)
		if success and #value ~= 0 then
			Indexer.RefreshIndex()
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
	bedrock = bedrock or Current.Bedrock
	path = TidyPath(path)
	local text = 'Choose the program you want to open this file with.'
	local height = #Helpers.WrapText(text, 26)

	local items = {}

	for i, v in ipairs(fs.list('Programs/')) do
		if string.sub( v, 1, 1 ) ~= '.' then
			table.insert(items, v)
		end
	end

	local children = {
		{
			["Y"]="100%,-1",
			["X"]="100%,-5",
			["Name"]="OpenButton",
			["Type"]="Button",
			["Text"]="Open",
			OnClick = function()
				local selected = bedrock.Window:GetObject('ListView').Selected
				if selected then
					OpenFile('Programs/' .. selected.Text, {path})
					bedrock.Window:Close()
				end
			end
		},
		{
			["Y"]="100%,-1",
			["X"]="100%,-14",
			["Name"]="CancelButton",
			["Type"]="Button",
			["Text"]="Cancel",
			OnClick = function()
				bedrock.Window:Close()
			end
		},
	    {
			["Y"]=6,
			["X"]=2,
			["Height"]="100%,-8",
			["Width"]="100%,-2",
			["Name"]="ListView",
			["Type"]="ListView",
			["TextColour"]=128,
			["BackgroundColour"]=0,
			["CanSelect"]=true,
			["Items"]=items,
	    },
	    {
			["Y"]=2,
			["X"]=2,
			["Width"]="100%,-2",
			["Height"]=height,
			["Name"]="Label",
			["Type"]="Label",
			["Text"]=text
		}
	}

	local view = {
		Children=children,
		Width=28,
		Height=10+height
	}
	bedrock:DisplayWindow(view, 'Open With')

end

LongestString = function(input, key, isKey)
	local length = 0
	if isKey then
		for k, v in pairs(input) do
			local titleLength = string.len(k)
			if titleLength > length then
				length = titleLength
			end
		end
	else
		for i = 1, #input do
			local value = input[i]
			if key then
				if value[key] then
					value = value[key]
				else
					value = ''
				end
			end
			local titleLength = string.len(value)
			if titleLength > length then
				length = titleLength
			end
		end
	end
	return length
end

Round = function(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end