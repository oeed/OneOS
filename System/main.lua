local bedrock = Bedrock:Initialise()

nativeTerm = term.native
if type(nativeTerm) == 'function' then
	nativeTerm = term.current()
end

Current = {
	ProgramView = nil,
	Programs = {},
	Program = nil,
	Desktop = nil,
	DrawSpeed = 0.35,
	DefaultDrawSpeed = 0.5
}

function LaunchProgram(path, args, title)
	Current.Program = nil
	return Program:Initialise(shell, path, title, args)
	--bedrock:Draw()
end

--an ever so slightly changed version of the textutils version
local function getTimeString()
	local sTOD = nil
	local nTime = os.time()
	if not bTwentyFourHour then
	    if nTime >= 12 then
	        sTOD = "pm"
	    else
	        sTOD = "am"
	    end
	    if nTime >= 13 then
	        nTime = nTime - 12
	    end
	end

	local nHour = math.floor(nTime)
	local nMinute = math.floor((nTime - nHour)*60)
	if sTOD then
		if nHour == 0 then
			nHour = 12
		end
	    return string.format( "%d:%02d%s", nHour, nMinute, sTOD )
	else
	    return string.format( "%d:%02d", nHour, nMinute )
	end
end

function Update()
	--bedrock:GetObject('TimeLabel').Text = getTimeString()
	bedrock:Draw()
end

function UpdateOverlay()
	bedrock:GetObject('Overlay'):ForceDraw()
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

function Initialise()
	bedrock:Run(function()
		bedrock:LoadView('main', false)
		Current.ProgramView = bedrock:GetObject('ProgramView')
		Current.Desktop = LaunchProgram('System/Programs/Desktop.program/startup', {isHidden = true}, 'Desktop')
		bedrock:StartRepeatingTimer(Update, function()return Current.DrawSpeed end) --TODO: decide on length

		Update()

		--LaunchProgram('Programs/Sketch.program/startup', {}, 'Sketch')
		--LaunchProgram('Programs/LuaIDE.program/startup', {}, 'LuaIDE')
		LaunchProgram('Programs/Test.program/startup', {}, 'Test')

	end)
end