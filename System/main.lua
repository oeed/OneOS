local bedrock = Bedrock:Initialise()

bedrock.AllowTerminate = false

if type(term.native) == 'function' then
	local cur = term.current()
	restoreTerm = function()term.redirect(cur)end
else
	restoreTerm = function()term.restore()end
end

Current = {
	ProgramView = nil,
	Overlay = nil,
	Programs = {},
	Program = nil,
	Desktop = nil,
	Bedrock = bedrock
}

function UpdateOverlay()
	bedrock:GetObject('Overlay'):UpdateButtons()
end

bedrock.OnKeyChar = function(self, event, keychar)
	if keychar == '\\' then
		--Restart()
		AnimateShutdown(true)
	elseif Current.Program then
		Current.Program:QueueEvent(event, keychar)
	end
end

bedrock.OnTimer = function(self, event, timer)
	for i, program in ipairs(Current.Programs) do
		for i2, _timer in ipairs(program.Timers) do
			if _timer == timer then
				program:QueueEvent('timer', timer)
			end
		end
	end
end

local oldHandler = bedrock.EventHandler
bedrock.EventHandler = function(self)
	for i, program in ipairs(Current.Programs) do
		for i, event in ipairs(program.EventQueue) do
			program:Resume(unpack(event))
		end
		program.EventQueue = {}
	end
	oldHandler(self)
end

function Shutdown(force, restart)
	local success = true
	if not force then
		for i, program in ipairs(Current.Programs) do
			if not program.Hidden and not program:Close() then
				success = false
			end
		end
	end

	if success then
		AnimateShutdown(restart)
	else
		Current.Desktop:SwitchTo()
		local shutdownLabel = (restart and 'restart' or 'shutdown')
		local shutdownLabelCaptital = (restart and 'Restart' or 'Shutdown')

		bedrock:DisplayAlertWindow("Programs Still Open", "You have unsaved work. Save your work and close the program or click 'Force "..shutdownLabelCaptital.."'.", {'Force '..shutdownLabelCaptital, 'Cancel'}, function(value)
			if value ~= 'Cancel' then
				AnimateShutdown(restart)
			end
		end)
	end
end

function AnimateShutdown(restart)
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
	if restart then
		sleep(0.2)
		os.reboot()
	else
		os.shutdown()
	end
end

function Restart(force)
	Shutdown(force, true)
end

function Initialise()
	bedrock:Run(function()
		bedrock:LoadView('main', false)
		
		Current.ProgramView = bedrock:GetObject('ProgramView')
		Current.Overlay = bedrock:GetObject('Overlay')
		Indexer.RefreshIndex() --TODO: finish the search. this needs to be done before starting the desktop
		Current.Desktop = Helpers.OpenFile('System/Programs/Desktop.program', {isHidden = true})

		if Settings:GetValues()['StartupProgram'] then
			Helpers.OpenFile('Programs/'..Settings:GetValues()['StartupProgram'])
			UpdateOverlay()
		end

		Helpers.OpenFile('System/Programs/Files.program')
		--Helpers.OpenFile('Programs/Shell.program')
		--Helpers.OpenFile('Programs/Test2.program')
		UpdateOverlay()
	end)
end