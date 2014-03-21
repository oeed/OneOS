OneOSVersion = '...'

local x = 1
local y = 1
local m = 4

local needsDisplay = true
local drawing = false

local updateTimer = nil
local clockTimer = nil
local desktopRefreshTimer = nil

Current = {
	Clicks = {},
	Menu = nil,
	Programs = {},
	Window = nil,
	CursorPos = {1,1},
	CursorColour = colours.white,
	Program = nil,
	Input = nil,
	IconCache = {},
	CanDraw = true,
	AllowAnimate = true
}

Events = {
	
}

InterfaceElements = {
	
}

isFirstSetup = false


function ShowDesktop()
	Desktop.LoadSettings()
	Desktop.RefreshFiles()
	Desktop.SaveSettings()

	RegisterElement(Overlay)
	Overlay:Initialise()
	
end

function FirstSetup()
	EventRegister('mouse_click', TryClick)
	EventRegister('mouse_drag', TryClick)
	EventRegister('monitor_touch', TryClick)
	EventRegister('oneos_draw', Draw)
	EventRegister('key', HandleKey)
	EventRegister('char', HandleKey)
	EventRegister('timer', Update)
	--updateTimer = os.startTimer(0.5)
	
	isFirstSetup = true
	Overlay:Initialise()
	RegisterElement(Overlay)
	local prog = Program:Initialise(shell, '/System/Programs/Setup.program/startup', 'OneOS Setup', {}, 1)
	Drawing.Clear(colours.white)
	Draw()
	Desktop = nil
	
	EventHandler()
end

function Initialise()
	EventRegister('mouse_click', TryClick)
	EventRegister('mouse_drag', TryClick)
	EventRegister('monitor_touch', TryClick)
	EventRegister('oneos_draw', Draw)
	EventRegister('oneos_shutdown', function(ev, restart)Shutdown(true, restart)end)
	EventRegister('key', HandleKey)
	EventRegister('char', HandleKey)
	EventRegister('timer', Update)
	EventRegister('http_success', AutoUpdateRespose)
	EventRegister('http_failure', AutoUpdateFail)
	ShowDesktop()
	Draw()
	clockTimer = os.startTimer(0.8333333)
	desktopRefreshTimer = os.startTimer(5)
	local h = fs.open('/System/.version', 'r')
	if not h then
		os.reboot()
	end
	OneOSVersion = h.readAll()
	h.close()
	
	Helpers.OpenFile('Programs/Ink.program', {'/Desktop/Documents/Test.txt'})

	CheckAutoUpdate()
	EventHandler()
end

local checkAutoUpdateArg = nil
local checkingAutoUpdateWindow = nil

function CheckAutoUpdate(arg)
	checkAutoUpdateArg = arg
	if http then
		if checkAutoUpdateArg then
			checkingAutoUpdateWindow = ButtonDialogueWindow:Initialise("Update OneOS", "Checking for updates, this may take a moment.", 'Ok', nil, function(success)end)
			checkingAutoUpdateWindow:Show()
		end
		http.request('https://api.github.com/repos/oeed/OneOS/releases#')
	elseif arg then
		ButtonDialogueWindow:Initialise("HTTP Not Enabled!", "Turn on the HTTP API to update.", 'Ok', nil, function(success)end):Show()
	end
end

function split(str, sep)
        local sep, fields = sep or ":", {}
        local pattern = string.format("([^%s]+)", sep)
        str:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
end

function GetSematicVersion(tag)
	tag = tag:sub(2)
	return split(tag, '.')
end

--Returns true if the FIRST version is NEWER
function SematicVersionIsNewer(version, otherVersion)
	if version[1] > otherVersion[1] then
		return true
	elseif version[2] > otherVersion[2] then
		return true
	elseif version[3] > otherVersion[3] then
		return true
	end
	return false
end

function AutoUpdateFail(event, url, data)
	if url ~= 'https://api.github.com/repos/oeed/OneOS/releases#' then
		return false
	end
	if checkAutoUpdateArg then
		if checkingAutoUpdateWindow then
			checkingAutoUpdateWindow:Close()
		end
		ButtonDialogueWindow:Initialise("Update Check Failed", "Check your connection and try again.", 'Ok', nil, function(success)end):Show()
	end
end

function AutoUpdateRespose(event, url, data)
	if url ~= 'https://api.github.com/repos/oeed/OneOS/releases#' then
		return false
	end
	os.loadAPI('/System/JSON')
	if not data then
		return
	end
	local releases = JSON.decode(data.readAll())
	os.unloadAPI('JSON')
	if not releases or not releases[1] or not releases[1].tag_name then
		if checkAutoUpdateArg then
			if checkingAutoUpdateWindow then
				checkingAutoUpdateWindow:Close()
			end
			ButtonDialogueWindow:Initialise("Update Check Failed", "Check your connection and try again.", 'Ok', nil, function(success)end):Show()
		end
		return
	end
	local latestReleaseTag = releases[1].tag_name

	if OneOSVersion == latestReleaseTag then
		--using latest version
		if checkAutoUpdateArg then
			if checkingAutoUpdateWindow then
				checkingAutoUpdateWindow:Close()
			end
			ButtonDialogueWindow:Initialise("Up to date!", "OneOS is up to date!", 'Ok', nil, function(success)end):Show()
		end
		return
	elseif SematicVersionIsNewer(GetSematicVersion(latestReleaseTag), GetSematicVersion(OneOSVersion)) then
		if checkingAutoUpdateWindow then
			checkingAutoUpdateWindow:Close()
		end
		ButtonDialogueWindow:Initialise("Update OneOS", "There is a new version of OneOS available, do you want to update?", 'Yes', 'No', function(success)
			if success then
				LaunchProgram('/System/Programs/Update OneOS/startup', {}, 'Update OneOS')
			end
		end):Show()
	end
end

function LaunchProgram(path, args, title)
	Animation.RectangleSize(Drawing.Screen.Width/2, Drawing.Screen.Height/2, 1, 1, Drawing.Screen.Width, Drawing.Screen.Height, colours.grey, 0.3, function()
		if Current.Menu then
			Current.Menu:Close()
		end
		Current.Program = nil
		Program:Initialise(shell, path, title, args)
	end)
end

function SwitchToProgram(newProgram, currentIndex, newIndex)
	if Current.Program and newProgram ~= Current.Program then
		local direction = 1
		if newIndex < currentIndex then
			direction = -1
		end
		Animation.SwipeProgram(Current.Program, newProgram, direction)
	else
		Animation.RectangleSize(Drawing.Screen.Width/2, Drawing.Screen.Height/2, 1, 1, Drawing.Screen.Width, Drawing.Screen.Height, colours.grey, 0.3, function()
			Current.Program = newProgram
			Overlay.UpdateButtons()
			Current.Program.AppRedirect:Draw()
			Drawing.DrawBuffer()
		end)
	end
end

function Update(event, timer)
	if timer == updateTimer then
		updateTimer = os.startTimer(0.5)
		Current.Program.AppRedirect:Draw()
		Drawing.DrawBuffer()
	elseif timer == clockTimer then
		clockTimer = os.startTimer(0.8333333)
		Draw()
	elseif Desktop and timer == desktopRefreshTimer then
		Desktop:RefreshFiles()
		desktopRefreshTimer = os.startTimer(3)
	elseif Desktop and timer == Desktop.desktopDragOverTimer then
		Desktop.DragOverUpdate()
	else
		Animation.HandleTimer(timer)
		for i, program in ipairs(Current.Programs) do
			for i2, _timer in ipairs(program.Timers) do
				if _timer == timer then
					program:QueueEvent('timer', timer)
				end
			end
		end
	end
end



function Draw()
	term.restore()
	if isFirstSetup then
		Current.Program.AppRedirect:Draw()
		Drawing.DrawBuffer()
	end

	if not Current.CanDraw then
		return
	end

	drawing = true
	Current.Clicks = {}

	if Current.Program then
		Current.Program.AppRedirect:Draw()
	else
		Desktop:Draw()
		term.setCursorBlink(false)
	end

	for i, elem in ipairs(InterfaceElements) do
		if elem.Draw then
			elem:Draw()
		end
	end

	if Current.Window then
		Current.Window:Draw()
	end

	Drawing.DrawBuffer()
	if Current.Menu then
		term.setCursorBlink(false)
	end

	term.setCursorPos(Current.CursorPos[1], Current.CursorPos[2])
	term.setTextColour(Current.CursorColour)
	drawing = false
	needsDisplay = false
end


MainDraw = Draw

function RegisterElement(elem)
	table.insert(InterfaceElements, elem)
end

function UnregisterElement(elem)
	for i, e in ipairs(InterfaceElements) do
		if elem == e then
			InterfaceElements[i] = nil
		end
	end
end

function RegisterClick(elem)
	table.insert(Current.Clicks, elem)
end

function CheckClick(object, x, y)
	local pos = GetAbsolutePosition(object)
	if pos.X <= x and pos.Y <= y and  pos.X + object.Width > x and pos.Y + object.Height > y then
		return true
	end
end

function DoClick(event, object, side, x, y)
	if object and CheckClick(object, x, y) then
		return object:Click(side, x - object.X + 1, y - object.Y + 1)
	end	
end

function TryClick(event, side, x, y)
	if Current.Menu and DoClick(event, Current.Menu, side, x, y) then
		Draw()
		return
	elseif Current.Window then
		if DoClick(event, Current.Window, side, x, y) then
			Draw()
			return
		else
			Current.Window:Flash()
		end
	else
		if Current.Menu and not (x < 6 and y == 1) then
			Current.Menu:Close()
			NeedsDisplay()
		end
		if Current.Program and y >= 2 then
			Current.Program:Click(event, side, x, y-1)
		elseif y >= 2 and Desktop then
			Desktop.Click(event, side, x, y)
		end

		for i, object in ipairs(Current.Clicks) do
			if DoClick(event, object, side, x, y) then
				Draw()
				return
			end		
		end
	end
end

function HandleKey(...)
	local args = {...}
	local event = args[1]
	local keychar = args[2]
	
	--REMOVE THIS AT RELEASE!
	if keychar == '\\' and isDebug then
		os.reboot()
	end

	if Current.Input then
		if event == 'char' then
			Current.Input:Char(keychar)
		elseif event == 'key' then
			Current.Input:Key(keychar)
		end
	elseif Current.Program then 
		Current.Program:QueueEvent(...)
	elseif Current.Window then
		if event == 'key' then
			if keychar == keys.enter then
				if Current.Window.OkButton then
					Current.Window.OkButton:Click(1,1,1)
					NeedsDisplay()
				end
			elseif keychar == keys.delete or keychar == keys.backspace then
				if Current.Window.CancelButton then
					Current.Window.CancelButton:Click(1,1,1)
					NeedsDisplay()
				end
			end
		end
	else
		if event == 'key' then
			if keychar == keys.enter then
				Desktop.OpenSelected()
			elseif keychar == keys.delete or keychar == keys.backspace then
				Desktop.DeleteSelected()
			end
		end
	end
end

function GetAbsolutePosition(obj)
	if not obj.Parent then
		return {X = obj.X, Y = obj.Y}
	else
		local pos = GetAbsolutePosition(obj.Parent)
		local x = pos.X + obj.X - 1
		local y = pos.Y + obj.Y - 1
		return {X = x, Y = y}
	end
end

function NeedsDisplay()
	needsDisplay = true
end

function AnimateShutdown()
	if not Settings:GetValues()['UseAnimations'] then
		return
	end

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

	term.setBackgroundColour(colours.black)
	term.clear()
end

function Shutdown(force, restart)
	local success = true
	if not force then
		os.queueEvent('oneos_shutdown', restart)
		for i, program in ipairs(Current.Programs) do
			if not program:Close() then
				success = false
			end
		end
	end
	if success and not restart then
		if force then
			os.shutdown()
		end

		AnimateShutdown()
		os.shutdown()
	elseif success then
		if force then
			os.reboot()
		end

		AnimateShutdown()
		sleep(0.2)
		os.reboot()
	else
		Current.Program = nil
		Overlay.UpdateButtons()
		local shutdownLabel = 'shutdown'
		local shutdownLabelCaptital = 'Shutdown'
		if restart then
			shutdownLabel = 'restart'
			shutdownLabelCaptital = 'Restart'
		end

		ButtonDialogueWindow:Initialise("Programs Still Open", "Some programs stopped themselves from being closed, preventing "..shutdownLabel..". Save your work and close them or click 'Force "..shutdownLabelCaptital.."'.", 'Force '..shutdownLabelCaptital, 'Cancel', function(btnsuccess)
			if btsuccess and not restart then
				os.shutdown()
			elseif btnsuccess then
				os.reboot()
			end
		end):Show()
	end
end

function Restart(force)
	Shutdown(force, true)
end

function EventRegister(event, func)
	if not Events[event] then
		Events[event] = {}
	end
	table.insert(Events[event], func)
end

function ProgramEventHandle()
	for i, program in ipairs(Current.Programs) do
		for i, event in ipairs(program.EventQueue) do
			program:Resume(unpack(event))
		end
		program.EventQueue = {}
	end
end

function EventHandler()
	while true do
		ProgramEventHandle()
		local event = { coroutine.yield() }
		local hasFound = false

		if Events[event[1]] then
			for i, e in ipairs(Events[event[1]]) do
				if e(event[1], event[2], event[3], event[4], event[5]) == false then
					hasFound = false
				else
					hasFound = true
				end
			end
		end

		if not hasFound and Current.Program then
			Current.Program:QueueEvent(unpack(event))
		end
	end
end