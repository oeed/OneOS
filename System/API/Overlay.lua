ToolBarColour = colours.white
ToolBarTextColour = colours.black
HideTime = false

Elements = {
	
}

function Initialise()
	UpdateButtons()
end
local availableSpace = 0
function UpdateButtons()
	Overlay.HideTime = false
	if Current.Program then
		if Current.Program.Environment.OneOS.ToolBarColor ~= colours.white then
			Overlay.ToolBarColour = Current.Program.Environment.OneOS.ToolBarColor
		else
			Overlay.ToolBarColour = Current.Program.Environment.OneOS.ToolBarColour
		end
		
		if Current.Program.Environment.OneOS.ToolBarTextColor ~= colours.black then
			Overlay.ToolBarTextColour = Current.Program.Environment.OneOS.ToolBarTextColor
		else
			Overlay.ToolBarTextColour = Current.Program.Environment.OneOS.ToolBarTextColour
		end
	else
		Overlay.ToolBarColour = colours.white
		Overlay.ToolBarTextColour = colours.black
	end
	Elements = {}
	local searchChar = '@'
	if Current.DidIndex then
		searchChar = '%'
	end
	table.insert(Elements, Button:Initialise(Drawing.Screen.Width - 2, 1, 3, 1, Overlay.ToolBarColour, Overlay.ToolBarTextColour, colours.blue, colours.white,  nil, function() Search.Activate() end, searchChar, Current.SearchActive))
	InsertMenu("One", {
				{
					Title = 'Desktop',
					Click = function()
						Desktop:RefreshFiles()
						Current.Program = nil
						UpdateButtons()
					end
				},
				{
					Title = 'About OneOS',
					Click = function()
						LaunchProgram('/System/Programs/About OneOS/startup', {}, 'About OneOS')
					end
				},
				{
					Title = 'Settings',
					Click = function()
						LaunchProgram('/System/Programs/Settings/startup', {}, 'Settings')
					end
				},
				--[[
				{
					Title = 'Help',
					Click = function()
						LaunchProgram('Programs/Help/startup', {}, 'Help')
					end
				},
				]]--
				
				{
					Separator = true
				},
				{
					Title = 'Update OneOS',
					Click = function()
						CheckAutoUpdate(true)
					end
				},

				{
					Separator = true
				},
				--[[
				{
					Title = 'Sleep',
					Click = function()
						Sleep()
					end
				},
				]]--
				{
					Title = 'Restart',
					Click = function()
						Restart()
					end
				},
				{
					Title = 'Shutdown',
					Click = function()
						Shutdown()
					end
				},
			}, 2)
	local currentProgramI = 1
	availableSpace = Drawing.Screen.Width - 8
	local menuPrograms = {}
	local activeInMenu = false
	local activeInMenuText = false
	if Current.Programs and #Current.Programs >= 1 then
		for i, program in ipairs(Current.Programs) do
			if availableSpace - 2 - #program.Title <= 2 then
				Overlay.HideTime = true
				if Current.Program and Current.Program == program then
					activeInMenu = colours.lightBlue
					activeInMenuText = colours.white
				end
				table.insert(menuPrograms, {
					Title = 'x '..program.Title,
					Click = function(self, side, x, y)
						if side == 3 or x == 2 then
							program:Close()
							program = nil
							return
						end
						SwitchToProgram(program, currentProgramI, i)
					end
				})
			else
			
				local textColour = Overlay.ToolBarTextColour
				local activeBackgroundColour = colours.lightBlue

				if not program.Process or coroutine.status(program.Process) == "dead" then
					textColour = Overlay.ToolBarTextColour--colours.grey
					activeBackgroundColour = colours.grey
				end
				
				if not Current.Program or Current.Program ~= program then
					availableSpace = availableSpace - 2 - #program.Title
					InsertButton(program.Title, false, Overlay.ToolBarColour, activeBackgroundColour, textColour, colours.white, function(self, side, x, y, toggle)
						if side == 3 then
							program:Close()
							program = nil
							return
						end
						SwitchToProgram(program, currentProgramI, i)
					end)
				else
					currentProgramI = i
					availableSpace = availableSpace - 4 - #program.Title
					InsertButton("x "..Current.Program.Title, true, colours.white, activeBackgroundColour, textColour, colours.white, function(self, side, x, y, toggle)
						if side == 3 then
							program:Close()
							program = nil
							return
						end
						if x == 2 then
							program:Close(side == 2)
						end
						self.Toggle = false
					end)
				end
				if availableSpace <= 8 then
					Overlay.HideTime = true
				end
			end
		end
	end

	if #menuPrograms ~= 0 then
		InsertMenu("=", menuPrograms, Drawing.Screen.Width - 3, activeInMenu, activeInMenuText)
	end

	Draw()
end

function InsertMenu(title, items, x, bg, tc)
	local menuX = -1
	local width = Helpers.LongestString(items, 'Title')
	if Drawing.Screen.Width < x + width then
		menuX = width - 1
	end
	local bg = bg or Overlay.ToolBarColour
	local tc = tc or Overlay.ToolBarTextColour
	local highlighted = false
	if Current.Menu and Current.Menu.Tag == title then
		highlighted = true
	end
	table.insert(Elements,
	Button:Initialise(x-1, 1, #title+2, 1, bg, tc, nil, nil, nil, function(self, side, x, y, toggle)
		local menu = nil
		if toggle then
			menu = Menu:Initialise(0-menuX, 2, nil, nil, self, items, true, function()
				Current.Menu = nil
				Overlay.UpdateButtons()
				MainDraw()
			end)
			menu.Tag = title
			menu:Show()
		else
			Current.Menu:Close()
			return false
		end
		return true
	end, title, highlighted))
end

function InsertButton(title, active, backgroundColour, activeBackgroundColour, textColour, activeTextColour, click)
	title = Helpers.TruncateString(title, 12)
	local x = 2
	if #Elements ~= 0 then
		local elem = Elements[#Elements]
		x = elem.X + elem.Width + 1
	end

	table.insert(Elements, Button:Initialise(x-1, 1, #title+2, 1, backgroundColour, textColour, activeBackgroundColour, activeTextColour,  nil, click, title, active))
end

function Draw()
	if isFirstSetup then
		return
	end
	
	if Current.Program then
		if Current.Program.Environment.OneOS.ToolBarColor ~= colours.white then
			Overlay.ToolBarColour = Current.Program.Environment.OneOS.ToolBarColor
		else
			Overlay.ToolBarColour = Current.Program.Environment.OneOS.ToolBarColour
		end
		
		if Current.Program.Environment.OneOS.ToolBarTextColor ~= colours.black then
			Overlay.ToolBarTextColour = Current.Program.Environment.OneOS.ToolBarTextColor
		else
			Overlay.ToolBarTextColour = Current.Program.Environment.OneOS.ToolBarTextColour
		end
	else
		Overlay.ToolBarColour = colours.white
		Overlay.ToolBarTextColour = colours.black
	end

	Drawing.DrawBlankArea(1, 1, Drawing.Screen.Width, 1, Overlay.ToolBarColour)

	for i, elem in ipairs(Elements) do
		elem:Draw()
	end

	if not Overlay.HideTime then
		local timeString = textutils.formatTime(os.time())
		Drawing.DrawCharacters(Drawing.Screen.Width - #timeString - 2, 1, timeString, Overlay.ToolBarTextColour, Overlay.ToolBarColour)
	end
end