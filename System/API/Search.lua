local lastClick = nil
Width = 20
Buffer = nil
SearchBox = nil
SearchItems = {}
SelectedPath = nil

local ready = false

function Close(done)
	ready = false
	Current.SearchActive = false
	Animation.SearchToggle(Current.SearchActive, function()
		Current.CanDraw = true
		Overlay.UpdateButtons()
		if done then
			done()
		end
		MainDraw()
	end)
end

function DrawBlankToBuffer()
	local xStart = Drawing.Screen.Width + 1
	for y = 1, Drawing.Screen.Height do
		Search.Buffer[y][xStart] = {' ', colours.black, colours.black}
	end

	for y = 1, Drawing.Screen.Height do
		for x = 1, Search.Width - 1 do
			Search.Buffer[y][x + xStart] = {' ', colours.black, colours.grey}
		end
	end

	local chars = {' ','S','e','a','r','c','h','.','.','.'}
	for x = 1, Search.Width - 3 do
		local char = ' '
		if #chars >= x then
			char = chars[x]
		end
		Search.Buffer[2][x + xStart + 1] = {char, colours.grey, colours.lightGrey}
	end
end

function UpdateTime()
	if not Overlay.HideTime then
		local timeString = ' '..textutils.formatTime(os.time())
		Drawing.DrawCharacters(Drawing.Screen.Width - #timeString - 2 - Search.Width, 1, timeString, Overlay.ToolBarTextColour, Overlay.ToolBarColour)
	end
end

function Draw()
	if not ready then
		return
	end
	term.setCursorBlink(false)
	UpdateTime()
	Drawing.DrawBlankArea(Drawing.Screen.Width - Search.Width + 2, 1, Search.Width - 1, Drawing.Screen.Height, colours.grey)

	SearchBox:Draw()
	local usedY = 0
	for name, category in pairs(SearchItems) do
		if #category ~= 0 then
			usedY = usedY + 1
			Drawing.DrawCharacters(Drawing.Screen.Width - Search.Width + 3, 3 + usedY, name, colours.lightGrey, colours.grey)

			for i, item in ipairs(category) do
				usedY = usedY + 1
				local backgroundColour = colours.grey
				local textColour = colours.white
				if SelectedPath == item.Path then
					backgroundColour = colours.blue
				end
				item.Y = 3+usedY
				Drawing.DrawBlankArea(Drawing.Screen.Width - Search.Width + 2, 3+usedY, Search.Width - 1, 1, backgroundColour)
				Drawing.DrawCharacters(Drawing.Screen.Width - Search.Width + 3, 3+usedY, item.Name, textColour, backgroundColour)
			end
			usedY = usedY + 1
		end
	end

	if Current.Menu then
		Current.Menu:Draw()
	end

	Drawing.DrawBuffer()
	term.setTextColour(colours.white)
	term.setCursorPos(Drawing.Screen.Width + 4 - Search.Width + SearchBox.TextInput.CursorPos, 2)
	term.setCursorBlink(true)
end

function UpdateSearch()
	SearchItems = {
		Folders = {},
		Documents = {},
		Images = {},
		Programs = {},
		['System Files'] = {},
		Other = {}
	}
	local paths = Indexer.Search(SearchBox.TextInput.Value)
	local foundSelected = false
	for i, path in ipairs(paths) do
		local extension = Helpers.Extension(path)
		if extension ~= 'shortcut' then
			path = Helpers.TidyPath(path)
			local fileType = 'Other'
			if extension == 'txt' or extension == 'text' or extension == 'LICENSE' then
				fileType = 'Documents'
			elseif extension == 'nft' or extension == 'nfp' or extension == 'skch' then
				fileType = 'Images'
			elseif extension == 'program' then
				fileType = 'Programs'
			elseif extension == 'lua' then
				fileType = 'System Files'
			elseif fs.isDir(path) then
				fileType = 'Folders'
			end
			if path == SelectedPath then
				foundSelected = true
			end
			table.insert(SearchItems[fileType], {Path = path, Name = fs.getName(path), Y = 0})
		end
	end

	if not foundSelected then
		SelectedPath = nil
	end

	Draw()
end

function ClickItem(item, side, x, y)
	if SelectedPath == item.Path and lastClick and (os.clock() - lastClick) < 0.5 then
		Search.Close(function()Helpers.OpenFile(item.Path) end)
	end
	lastClick = os.clock()
	SelectedPath = item.Path
	if side == 2 then
		Menu:Initialise(x, y, nil, nil, self,{ 
			{
				Title = 'Open',
				Click = function()
					Search.Close(function()Helpers.OpenFile(item.Path)end)
				end
			},
			{
				Separator = true
			},
			{
				Title = 'Show in Files',
				Click = function()
					Search.Close(function()Helpers.OpenFile('/System/Programs/Files.program', {item.Path, true})end)
				end
			}
		}):Show()
	end
	Draw()
end

function Click(event, side, x, y)
	if event == 'mouse_click' then
		if Current.Menu and DoClick(event, Current.Menu, side, x, y) then
			Draw()
			return
		elseif x <= Drawing.Screen.Width - Search.Width then
			Search.Close()
		elseif x ~= Drawing.Screen.Width - Search.Width + 1 then
			for name, category in pairs(SearchItems) do
				for i, item in ipairs(category) do
					if y == item.Y then
						ClickItem(item, side, x, y)
						return
					end
				end
			end
		end
	end
end

function Activate()
	if Current.Menu then
		Current.Menu:Close()
	end
	Current.SearchActive = true
	Overlay.UpdateButtons()
	MainDraw()
	Current.CanDraw = false
	Search.Buffer = Drawing.BackBuffer
	DrawBlankToBuffer()
	SearchItems = {}
	SelectedPath = nil
	SearchBox = TextBox:Initialise(Drawing.Screen.Width + 3 - Search.Width, 2, Search.Width - 3, 1, nil, '', colours.lightGrey, colours.white, Search.UpdateSearch, false, 'Search...', colours.grey)
	Animation.SearchToggle(Current.SearchActive, function()
		ready = true
		Current.Input = SearchBox.TextInput
	end)
end