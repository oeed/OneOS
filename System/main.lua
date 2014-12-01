-- Bedrock.Helpers = Helpers
local bedrock = Bedrock:Initialise('/System')
bedrock.ViewPath ='/System/Views/'
-- _G.Helpers = Helpers
-- error(Helpers.IconForFile)
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
	Bedrock = bedrock,
	SearchActive = true
}

function UpdateOverlay()
	bedrock:GetObject('Overlay'):UpdateButtons()
end

bedrock.OnKeyChar = function(self, event, keychar)
	if isDebug and keychar == '\\' then
		--Restart()
		AnimateShutdown(true)
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

bedrock:RegisterEvent('modem_message', function(self, event, side, channel, replyChannel, message, distance)
	if pocket and channel == Wireless.Channels.UltimateDoorlockPing then
		message = textutils.unserialize(message)
		if message then
			message.content = textutils.unserialize(message.content)
			if message.content then
				Wireless.SendMessage(Wireless.Channels.UltimateDoorlockRequest, fingerprint, Wireless.Channels.UltimateDoorlockRequestReply, nil, message.senderID)
				return true
			end
		end
	end
	Current.Program:QueueEvent(event, side, channel, replyChannel, message, distance)
end)

bedrock.EventHandler = function(self)
	for i, program in ipairs(Current.Programs) do
		for i, event in ipairs(program.EventQueue) do
			program:Resume(unpack(event))
		end
		program.EventQueue = {}
	end
	local event = { os.pullEventRaw() }

	local s = 'Event: '
	for i, v in ipairs(event) do
		s = s..tostring(v)..', '
	end
	Log.i(s)

	if self.EventHandlers[event[1]] then
		for i, e in ipairs(self.EventHandlers[event[1]]) do
			e(self, unpack(event))
		end
	else
		Current.Program:QueueEvent(unpack(event))
	end
end

function Shutdown(force, restart, animate)
	Log.i(bedrock.View.Name)
	if bedrock.View.Name == 'firstsetup' then
		os.reboot()
	end
	Log.i('Trying to shutdown/restart. Restart: '..tostring(restart))
	local success = true
	if not force then
		for i, program in ipairs(Current.Programs) do
			if not program.Hidden and not program:Close() then
				success = false
			end
		end
	end

	if success then
		AnimateShutdown(restart, animate)
	else
		Log.w('Shutdown/restart aborted')
		Current.Desktop:SwitchTo()
		local shutdownLabel = (restart and 'restart' or 'shutdown')
		local shutdownLabelCaptital = (restart and 'Restart' or 'Shutdown')

		bedrock:DisplayAlertWindow("Programs Still Open", "You have unsaved work. Save your work and close the program or click 'Force "..shutdownLabelCaptital.."'.", {'Force '..shutdownLabelCaptital, 'Cancel'}, function(value)
			if value ~= 'Cancel' then
				AnimateShutdown(restart, animate)
			end
		end)
	end
end

function AnimateShutdown(restart, animate)
	Log.w('System safely stopping.')
	if Settings:GetValues()['UseAnimations'] and animate then
		Log.i('Animating')
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
		Log.i('Done animation')
	end

	term.setBackgroundColour(colours.black)
	term.clear()
	if restart then
		sleep(0.2)
		Log.i('Rebooting now.')
		os.reboot()
	else
		Log.i('Shutting down now.')
		os.shutdown()
	end
end

function Restart(force, animate)
	Shutdown(force, true, animate)
end

function StartDoorWireless()
	if pocket and Wireless.Present() then
		Wireless.Open(Wireless.Channels.UltimateDoorlockPing)
		Wireless.Open(Wireless.Channels.UltimateDoorlockRequest)
		if fs.exists('/System/.fingerprint') then
			local h = fs.open('/System/.fingerprint', 'r')
			if h then
				fingerprint = h.readAll()
				h.close()
			end
		else
			local function GenerateFingerprint()
			    local str = ""
			    for _ = 1, 256 do
			        local char = math.random(32, 126)
			        str = str .. string.char(char)
			    end
			    return str
			end
			fingerprint = GenerateFingerprint()
			local h = fs.open('/System/.fingerprint', 'w')
			if h then
				h.write(fingerprint)
				h.close()
			end
		end
	end
end

local checkAutoUpdateArg = nil

function CheckAutoUpdate(arg)
	Log.i('Checking for updates...')
	checkAutoUpdateArg = arg
	if http then
		if checkAutoUpdateArg then
			bedrock:DisplayAlertWindow("Update OneOS", "Checking for updates, this may take a moment.", {'Ok'})
		end
		http.request('https://api.github.com/repos/oeed/OneOS/releases#')
	elseif arg then
		Log.e('Update failed. HTTP is not enabled.')
		bedrock:DisplayAlertWindow("HTTP Not Enabled!", "Turn on the HTTP API to update.", {'Ok'})		
	else
		Log.e('Update failed. HTTP is not enabled.')
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

function AutoUpdateFail(self, event, url, data)
	if url == 'https://api.github.com/repos/oeed/OneOS/releases#' then
		Log.w('Auto update failed. (http_failure)')
		if checkAutoUpdateArg then
			if bedrock.Window then
				bedrock.Window:Close()
			end
			bedrock:DisplayAlertWindow("Update Check Failed", "Check your connection and try again.", {'Ok'})
		end
	else
		Current.Program:QueueEvent(event, url, data)
	end
end

function AutoUpdateResponse(self, event, url, data)
	if url == 'https://api.github.com/repos/oeed/OneOS/releases#' then
		os.loadAPI('/System/JSON')
		if not data then
			Log.w('Auto update failed. (no)')
			return
		end
		local releases = JSON.decode(data.readAll())
		os.unloadAPI('JSON')
		if not releases or not releases[1] or not releases[1].tag_name then
			Log.w('Auto update failed. (misformatted)')
			if checkAutoUpdateArg then
				if bedrock.Window then
					bedrock.Window:Close()
				end
				bedrock:DisplayAlertWindow("Update Check Failed", "Check your connection and try again.", {'Ok'})
			end
			return
		end
		local latestReleaseTag = releases[1].tag_name

		if not Settings:GetValues()['DownloadPrereleases'] then
			Log.i('Not downloading prereleases')
			for i, v in ipairs(releases) do
				if not v.prerelease then
					latestReleaseTag = v.tag_name
					break
				end
			end
		end
		Log.i('Latest tag: '..latestReleaseTag)

		local h = fs.open('/System/.version', 'r')
		local version = h.readAll()
		h.close()

		if version == latestReleaseTag then
			--using latest version
			Log.i('OneOS is up to date.')
			if checkAutoUpdateArg then
				if bedrock.Window then
					bedrock.Window:Close()
				end
				bedrock:DisplayAlertWindow("Up to date!", "OneOS is up to date!", {'Ok'})
			end
			return
		elseif SematicVersionIsNewer(GetSematicVersion(latestReleaseTag), GetSematicVersion(version)) then			
			Log.i('New version of OneOS available. (from '..version..' to '..latestReleaseTag..')')
			if bedrock.Window then
				bedrock.Window:Close()
			end
			bedrock:DisplayAlertWindow("Update OneOS", "There is a new version of OneOS available, do you want to update?", {'Yes', 'No'}, function(value)
				if value == 'Yes' then
					Helpers.OpenFile('System/Programs/Update OneOS.program')
				end
			end)
		else
			Log.i('OneOS is neither up to date or behind. (.version probably edited)')
		end
	else
		Current.Program:QueueEvent(event, url, data)
	end
end

bedrock:RegisterEvent('http_success', AutoUpdateResponse)
bedrock:RegisterEvent('http_failure', AutoUpdateFail)

function FirstSetup()
	bedrock:Run(function()
		Log.i('Reached First Setup GUI')
		bedrock:LoadView('firstsetup', false)
		Log.i('First Setup GUI Loaded')
		
		Current.ProgramView = bedrock:GetObject('ProgramView')
		Helpers.OpenFile('System/Programs/First Setup.program', {isHidden = true})
	end)
end

function Initialise()
	bedrock:Run(function()
		Log.i('Reached GUI')
		bedrock:LoadView('main', false)
		Log.i('GUI Loaded')

		Current.ProgramView = bedrock:GetObject('ProgramView')
		Current.LoginView = bedrock:GetObject('LoginView')
		Current.Overlay = bedrock:GetObject('Overlay')
		Indexer.RefreshIndex()

		bedrock:GetObject('ClickCatcherView').OnClick = function()
			if Current.SearchActive then
				Search.Close()
			end
		end

		Current.Desktop = Helpers.OpenFile('System/Programs/Desktop.program', {isHidden = true})

		Current.LoginView.OnUnlock = function(self, sleepMode)
			if not sleepMode then
				if Settings:GetValues()['StartupProgram'] then
					Helpers.OpenFile('Programs/'..Settings:GetValues()['StartupProgram'])
					UpdateOverlay()
				end
				UpdateOverlay()
				StartDoorWireless()
				CheckAutoUpdate()
			end
		end
		Current.LoginView:Lock()
	end)
end