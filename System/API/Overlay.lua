local toolBarColour = colours.white
local toolBarTextColour = colours.black
local hideTime = false

Elements = {
	
}

function Initialise()
	UpdateButtons()
end
local availableSpace = 0
function UpdateButtons()
	hideTime = false
	if Current.Program then
		toolBarColour = Current.Program.Environment.OneOS.ToolBarColour
		toolBarTextColour = Current.Program.Environment.OneOS.ToolBarTextColour
	else
		toolBarColour = colours.white
		toolBarTextColour = colours.black
	end
	Elements = {}
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
	availableSpace = Drawing.Screen.Width - 5
	local menuPrograms = {}
	if Current.Programs and #Current.Programs >= 1 then
		for i, program in ipairs(Current.Programs) do
			if availableSpace - 2 - #program.Title <= 2 then
				hideTime = true
				table.insert(menuPrograms, {
					Title = program.Title,
					Click = function(self, side)
						if side == 3 then
							program:Close()
							program = nil
							return
						end
						SwitchToProgram(program, currentProgramI, i)
					end
				})
			else
			
				local textColour = toolBarTextColour
				local activeBackgroundColour = colours.lightBlue

				if not program.Process or coroutine.status(program.Process) == "dead" then
					textColour = toolBarTextColour--colours.grey
					activeBackgroundColour = colours.grey
				end
				
				if not Current.Program or Current.Program ~= program then
					availableSpace = availableSpace - 2 - #program.Title
					InsertButton(program.Title, false, toolBarColour, activeBackgroundColour, textColour, colours.white, function(self, side, x, y, toggle)
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
					hideTime = true
				end
			end
		end
	end

	if #menuPrograms ~= 0 then
		InsertMenu("=", menuPrograms, Drawing.Screen.Width-1)
	end

	Draw()
end

function InsertMenu(title, items, x)
	local menuX = -1
	local width = Helpers.LongestString(items, 'Title')
	if Drawing.Screen.Width < x + width then
		menuX = width - 1
	end

	table.insert(Elements,
	 Button:Initialise(x-1, 1, #title+2, 1, toolBarColour, toolBarTextColour, nil, nil, nil, function(self, side, x, y, toggle)
		local menu = nil
		if toggle then
			menu = Menu:Initialise(0-menuX, 2, nil, nil, self, items, true, function()
				if Current.Program then
					MainDraw()
					--Current.Program.AppRedirect:Draw()
				end
			end):Show()
		else
			Current.Menu:Close()
			return false
		end
		return true
	end, title, false))
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
	if Current.Program then
		toolBarColour = Current.Program.Environment.OneOS.ToolBarColour
		toolBarTextColour = Current.Program.Environment.OneOS.ToolBarTextColour
	else
		toolBarColour = colours.white
		toolBarTextColour = colours.black
	end

	Drawing.DrawBlankArea(1, 1, Drawing.Screen.Width, 1, toolBarColour)

	for i, elem in ipairs(Elements) do
		elem:Draw()
	end

	if not hideTime then
		local timeString = textutils.formatTime(os.time())
		Drawing.DrawCharacters(Drawing.Screen.Width - #timeString, 1, timeString, toolBarTextColour, toolBarColour)
	end
end