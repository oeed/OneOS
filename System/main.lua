Bedrock.ProgramPath = shell.getRunningProgram()

local bedrock = Bedrock:Initialise('/System')
System.Bedrock = bedrock
System.Initialise()

-- bedrock.AnimationEnabled = false

-- bedrock.OnKeyChar = function(self, event, keychar)
-- 	if keychar == '\\' then
-- 		os.reboot()
-- 	end
-- end

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


function Initialise()
	bedrock.FileSystem = _fileSystem
	_fileSystem.Bedrock = bedrock

	Log.i(bedrock.FileSystem:ResolveAlias('/Favourites/Programs/Blah'))

	-- do return end

	bedrock:Run(function()

		Indexer.RefreshIndex()
		-- program:LoadView('main')
		-- TODO: debug only!
		bedrock:RegisterKeyboardShortcut({'\\'}, function()os.reboot()end)
		bedrock:RegisterKeyboardShortcut({keys.leftCtrl, 'v'}, function() 		
			Log.i('Pasting woot!')
			System.Clipboard:PasteToActiveObject()
		end)

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

		local desktop = bedrock:GetObject('ProgramView')
		bedrock:GetObject('OneButton').OnClick = function()
			desktop:MakeActive()
		end

		if System.Settings.StartupProgram then
			System.OpenFile(System.Settings.StartupProgram)
		end

		if System.Settings.AutomaticUpdates then
			System.CheckUpdates()
		end

		-- System.StartProgram('/Programs/LuaIDE.program')
		-- System.StartProgram('/System/Programs/Files.program')
		-- System.StartProgram('/Programs/Sketch.program')
		-- System.StartProgram('/System/Programs/Settings.program')
		-- System.StartProgram('/Programs/test.program')
	end)
end