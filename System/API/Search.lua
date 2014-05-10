
Width = 20
Buffer = nil
SearchBox = nil
SearchItems = {}

local ready = false

function AnimateOpen()
end

function Close()
	ready = false
	Current.SearchActive = false
	Animation.SearchToggle(Current.SearchActive, function()
		Current.CanDraw = true
		Overlay.UpdateButtons()
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
	if not Overlay.hideTime then
		local timeString = ' '..textutils.formatTime(os.time())
		Drawing.DrawCharacters(Drawing.Screen.Width - #timeString - 1 - Search.Width, 1, timeString, Overlay.ToolBarTextColour, Overlay.ToolBarColour)
	end
end

function Draw()
	if not ready then
		return
	end
	UpdateTime()

	SearchBox:Draw()

	Drawing.DrawBuffer()
	term.setTextColour(colours.white)
	term.setCursorPos(Drawing.Screen.Width + 4 - Search.Width + SearchBox.TextInput.CursorPos, 2)
	term.setCursorBlink(true)
end

function UpdateSearch()
	SearchItems = {
		Documents = {},
		Images = {},
		Programs = {},
		System = {},
		Other = {}
	}
	local paths = Search(SearchBox.TextInput.Value)
	for i, path in ipairs(paths) do
		local extension = Helpers.Extension(path)
		local fileType = 'Other'
		if extension == 'txt' or extension == 'text' or extension == 'LICENSE' then

		table.insert(SearchItems, {Path = path, Name = })
	end
	Draw()
end

function Click(event, side, x, y)
	if event == 'mouse_click' then
		if x <= Drawing.Screen.Width - Search.Width then
			Search.Close()
		end
	end
end

function Activate()
	Current.SearchActive = true
	Overlay.UpdateButtons()
	MainDraw()
	Current.CanDraw = false
	Search.Buffer = Drawing.BackBuffer
	DrawBlankToBuffer()
	SearchBox = TextBox:Initialise(Drawing.Screen.Width + 3 - Search.Width, 2, Search.Width - 3, 1, nil, '', colours.lightGrey, colours.white, Search.UpdateSearch, false, 'Search...', colours.grey)
	Animation.SearchToggle(Current.SearchActive, function()
		ready = true
		Current.Input = SearchBox.TextInput
	end)
end