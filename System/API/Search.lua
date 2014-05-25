local lastClick = nil
Width = 20
Buffer = nil
local SearchBox = nil
local SearchItems = {}
local SelectedPath = nil
local ListScrollBar = nil

local ready = true

function Close(done)
	if ready then
		ready = false
		Current.SearchActive = false
		Animation.SearchToggle(Current.SearchActive, function()
			ListScrollBar.MaxScroll = 0
			ListScrollBar = nil
			SearchBox = nil
			Current.CanDraw = true
			Overlay.UpdateButtons()
			if done then
				done()
			end
			Restore()
			Drawing.Clear(colours.black)
			MainDraw()
		end)
		ready = true
	end
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

	local usedY = -1*ListScrollBar.Scroll
	for name, category in pairs(SearchItems) do
		if #category ~= 0 then
			usedY = usedY + 1
			if usedY >= 1 then
				Drawing.DrawCharacters(Drawing.Screen.Width - Search.Width + 3, 3 + usedY, name, colours.lightGrey, colours.grey)
			end
			for i, item in ipairs(category) do
				usedY = usedY + 1
				if usedY >= 1 then
					local backgroundColour = colours.grey
					local textColour = colours.white
					if SelectedPath == item.Path then
						backgroundColour = colours.blue
					end
					item.Y = 3+usedY
					Drawing.DrawBlankArea(Drawing.Screen.Width - Search.Width + 2, 3+usedY, Search.Width - 1, 1, backgroundColour)
					Drawing.DrawCharacters(Drawing.Screen.Width - Search.Width + 3, 3+usedY, item.Name, textColour, backgroundColour)
				end
			end
			usedY = usedY + 1
		end
	end
	ListScrollBar.MaxScroll = usedY + ListScrollBar.Scroll - Drawing.Screen.Height + 2
	if ListScrollBar.MaxScroll < 0 then
		ListScrollBar.MaxScroll = 0
	end

	if Current.Menu then
		Current.Menu:Draw()
	end

	ListScrollBar:Draw()
	Drawing.DrawBuffer()
	term.setTextColour(colours.white)
	term.setCursorPos(Drawing.Screen.Width + 4 - Search.Width + SearchBox.TextInput.CursorPos, 2)
	term.setCursorBlink(true)
end

function GetSelectionPosition()
	local n = 0
	for name, category in pairs(SearchItems) do
		for i, item in ipairs(category) do
			n = n + 1
			if item.Path == SelectedPath then
				return n
			end
		end
	end
	return 0
end

function ScrollToSelected()
	local usedY = -1*ListScrollBar.Scroll
	for name, category in pairs(SearchItems) do
		if #category ~= 0 then
			usedY = usedY + 1
			for i, item in ipairs(category) do
				usedY = usedY + 1
				if item.Path == SelectedPath then
					if usedY < 1 then
						ListScrollBar.Scroll = ListScrollBar.Scroll - (0 - usedY) - 1
					elseif usedY >= ListScrollBar.Height then
						ListScrollBar.Scroll = ListScrollBar.Scroll - (ListScrollBar.Height - usedY) -- 1
					end
					if ListScrollBar.Scroll == 1 then
						ListScrollBar.Scroll = 0
					end
				end
			end
			usedY = usedY + 1
		end
	end
end

function SelectItem(n)
	if n < 1 then
		n = 1
	end
	local _n = 0
	local lastPath = nil
	for name, category in pairs(SearchItems) do
		for i, item in ipairs(category) do
			_n = _n + 1
			if _n == n then
				SelectedPath = item.Path
				ScrollToSelected()
				Draw()
				return
			end
			lastPath = item.Path
		end
	end
	SelectedPath = lastPath
	ScrollToSelected()
	Draw()
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
			table.insert(SearchItems[fileType], {Path = path, Name = Helpers.RemoveExtension(fs.getName(path)), Y = 0})
		end
	end

	if not foundSelected then
		SelectItem(0)
	end
	
	ListScrollBar.Scroll = 0

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

function Key(key)
	if key == keys.up then
		SelectItem(GetSelectionPosition() - 1)
		return true
	elseif key == keys.down then
		SelectItem(GetSelectionPosition() + 1)
		return true
	elseif key == keys.enter and SelectedPath then
		Search.Close(function()Helpers.OpenFile(SelectedPath)end)
	end
	return false
end

function Scroll(event, direction, x, y)
	ListScrollBar:DoScroll(direction*2)
	Draw()
end

function Click(event, side, x, y)
	if event == 'mouse_click' then
		if Current.Menu and DoClick(event, Current.Menu, side, x, y) then
			Draw()
			return
		elseif Current.Menu then
			Current.Menu:Close()
			Draw()
		elseif x <= Drawing.Screen.Width - Search.Width then
			Search.Close()
		elseif ListScrollBar.MaxScroll ~= 0 and DoClick(event, ListScrollBar, side, x, y) then
			Draw()
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
	elseif event == 'mouse_drag' then
		if ListScrollBar.MaxScroll ~= 0 and ListScrollBar:Click(side, x - ListScrollBar.X + 1, y - ListScrollBar.Y + 1, true) then
			Draw()
		end
	end
end

function Activate()
	if not ready then
		return
	end
	ready = false
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
	ListScrollBar = ScrollBar:Initialise(Drawing.Screen.Width, 4, Drawing.Screen.Height - 3, 0, colours.grey, colours.lightBlue, nil, function()end):Register()
	Animation.SearchToggle(Current.SearchActive, function()
		ready = true
		Current.Input = SearchBox.TextInput
	end)
end