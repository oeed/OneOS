
Width = 20
Buffer = nil

local ready = false

function AnimateOpen()
end

function Close()
	Current.SearchActive = false
	Animation.SearchToggle(Current.SearchActive, function()end)
	Current.CanDraw = true
	MainDraw()
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
end

function UpdateTime()
	if not Overlay.hideTime then
		local timeString = textutils.formatTime(os.time())
		Drawing.DrawCharacters(Drawing.Screen.Width - #timeString - 1 - Search.Width, 1, timeString, Overlay.toolBarTextColour, Overlay.toolBarColour)
	end
end

function Draw()
	if not ready then
		return
	end
	UpdateTime()

	Drawing.DrawCharacters(Drawing.Screen.Width + 3 - Search.Width, 1, 'Search', colours.white, colours.grey)

	Drawing.DrawBuffer()
end

function Activate()
	Current.SearchActive = true
	Overlay.UpdateButtons()
	MainDraw()
	Current.CanDraw = false
	Search.Buffer = Drawing.BackBuffer
	DrawBlankToBuffer()
	Animation.SearchToggle(Current.SearchActive, function()ready = true end)
end