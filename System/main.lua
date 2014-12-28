Bedrock.ProgramPath = shell.getRunningProgram()

local bedrock = Bedrock:Initialise('/System')
System.Bedrock = bedrock

bedrock.OnKeyChar = function(self, event, keychar)
	if keychar == '\\' then
		os.reboot()
	end
end

bedrock.EventHandler = function(self)
	local programs = self:GetObjects('ProgramView')
	for i, program in ipairs(programs) do
		for i, event in ipairs(program.EventQueue) do
			program:Resume(unpack(event))
		end
		if #program.EventQueue ~= 0 then
			program.EventQueue = {}
		end
	end
	local event = { os.pullEventRaw() }


	-- TODO: there seem to be tons of timers appearing out of no where
	local s = 'Event: '
	for i, v in ipairs(event) do
		s = s..tostring(v)..', '
	end
	Log.i(s)

	local name = event[1]
	if name ~= 'char' and name ~= 'key' and name ~= 'mouse_click' and name ~= 'mouse_scroll' and name ~= 'mouse_drag' then
		if name ~= 'timer' or not self.Timers[event[2]] then
			for i, program in ipairs(programs) do
				program:QueueEvent(unpack(event))
			end
		end
	end
	if self.EventHandlers[name] then
		for i, e in ipairs(self.EventHandlers[event[1]]) do
			e(self, unpack(event))
		end
	end
end



bedrock:Run(function()
	-- program:LoadView('main')
	-- TODO: debug only!
	bedrock:RegisterKeyboardShortcut({'\\'}, function()os.reboot()end)

	-- local clock = bedrock:GetObject('OneButton')
	local function updateClock()
		local time = os.time()
        if time >= 12 then
            sTOD = "pm"
        else
            sTOD = "am"
        end
        if time >= 13 then
            time = time - 12
        end
	    local nHour = math.floor(time)
	    local nMinute = math.floor((time - nHour)*60)
		clock.Text = string.format( "%d:%02d %s", nHour, nMinute, sTOD )
	end
	-- bedrock:StartRepeatingTimer(updateClock, 5/6)
	-- updateClock()


	System.StartProgram('/System/Programs/Desktop.program', nil, true)

	bedrock:GetObject('OneButton').OnClick = function()
		bedrock:GetObject('ProgramView'):MakeActive()
	end
	-- startProgram('/Programs/test.program')
	-- startProgram('/Programs/Sketch.program')
end)



