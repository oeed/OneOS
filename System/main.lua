local bedrock = Bedrock:Initialise()

nativeTerm = term.native
if type(nativeTerm) == 'function' then
	nativeTerm = term.current()
end

Current = {
	ProgramView = nil,
	Programs = {},
	Program = nil,
}

function LaunchProgram(path, args, title)
	Current.Program = nil
	Program:Initialise(shell, path, title, args)
	--bedrock:Draw()
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
			if Current.Menu then
				Current.Menu:Close()
			end
			Current.CanDraw = true
			Current.Program = newProgram
			Overlay.UpdateButtons()
			Current.Program.AppRedirect:Draw()
			Drawing.DrawBuffer()
		end)
	end
end

function Update()
	bedrock:Draw()
end

bedrock.OnKeyChar = function(event, keychar)
	if keychar == '\\' then
		os.reboot()
	elseif Current.Program then
		Current.Program:QueueEvent(event, keychar)
	end
end

bedrock.OnTimer = function(event, timer)
	for i, program in ipairs(Current.Programs) do
		for i2, _timer in ipairs(program.Timers) do
			if _timer == timer then
				program:QueueEvent('timer', timer)
			end
		end
	end
end

local oldHandle = bedrock.EventHandler
bedrock.EventHandler = function(self)
	for i, program in ipairs(Current.Programs) do
		for i, event in ipairs(program.EventQueue) do
			program:Resume(unpack(event))
		end
		program.EventQueue = {}
	end
	oldHandle(self)
end

function Initialise()
	bedrock:Run(function()
		bedrock:LoadView('main')
		Current.ProgramView = bedrock:GetObject('ProgramView')
--		LaunchProgram('Programs/Moretest.program/startup', {}, 'Test')
		LaunchProgram('Programs/Sketch.program/startup', {}, 'Test')
		bedrock:StartRepeatingTimer(Update, 1)
	end)
end