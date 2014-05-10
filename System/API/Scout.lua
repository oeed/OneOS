
Width = 20
Buffer = nil

local ready = false

function AnimateOpen()
end

function Close()
	Current.ScoutActive = false
	Animation.ScoutToggle(Current.ScoutActive, function()end)
	Current.CanDraw = true
	MainDraw()
end

function DrawBlankToBuffer()
	local xStart = Drawing.Screen.Width + 1
	for y = 1, Drawing.Screen.Height do
		Scout.Buffer[y][xStart] = {' ', colours.black, colours.black}
	end

	for y = 1, Drawing.Screen.Height do
		for x = 1, Scout.Width - 1 do
			Scout.Buffer[y][x + xStart] = {' ', colours.black, colours.grey}
		end
	end
end

function UpdateTime()
	if not Overlay.hideTime then
		local timeString = textutils.formatTime(os.time())
		Drawing.DrawCharacters(Drawing.Screen.Width - #timeString - 1 - Scout.Width, 1, timeString, Overlay.toolBarTextColour, Overlay.toolBarColour)
	end
end

function Draw()
	if not ready then
		return
	end
	UpdateTime()
	Drawing.DrawBuffer()
end

function Activate()
	Current.ScoutActive = true
	Overlay.UpdateButtons()
	MainDraw()
	Current.CanDraw = false
	Scout.Buffer = Drawing.BackBuffer
	DrawBlankToBuffer()
	Animation.ScoutToggle(Current.ScoutActive, function()ready = true end)
end