local bedrock = Bedrock:Initialise()

bedrock.AllowTerminate = false

nativeTerm = term.native
if type(nativeTerm) == 'function' then
	nativeTerm = term.current()
end

Current = {
	ProgramView = nil,
	Programs = {},
	Program = nil,
	Desktop = nil,
	Bedrock = bedrock
}

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
		Current.Desktop = Helpers.OpenFile('System/Programs/Desktop.program', {isHidden = true})
		bedrock.DrawSpeed = 0.2
		bedrock.DefaultDrawSpeed = 0.2
		Indexer.RefreshIndex() --TODO: finish the search

		Helpers.OpenFile('System/Programs/Settings.program')
		--Helpers.OpenFile('Programs/LuaIDE.program')
		--Helpers.OpenFile('Programs/Test2.program')

	end)
end