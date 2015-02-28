Inherit = 'PageView'

OnPageLoad = function(self)
	self:GetObject('ComputerNameTextBox').Text = os.getComputerLabel() or ''
	self:GetObject('AutomaticUpdatesSwitch').Toggle = OneOS.System.Settings.AutomaticUpdates
	self:GetObject('UsePreReleasesSwitch').Toggle = OneOS.System.Settings.UsePreReleases
	self:GetObject('StartupProgramLabel').Text = OneOS.System.Settings.StartupProgram or 'None'

	self:GetObject('ComputerNameTextBox').OnChange = function(_)
		os.setComputerLabel(_.Text)
	end

	self:GetObject('AutomaticUpdatesSwitch').OnChange = function(_, value)
		OneOS.System.Settings.AutomaticUpdates = value
	end

	self:GetObject('UpdateNowButton').OnClick = function()
		OneOS.System.CheckUpdates(true)
	end

	self:GetObject('UsePreReleasesSwitch').OnChange = function(_, value)
		OneOS.System.Settings.UsePreReleases = value
	end

	self:GetObject('SelectStartupProgramButton').OnClick = function(_, event, side, x , y)
		self.Bedrock:DisplayOpenFileWindow('Startup File/Program', function(ok, path)
			if ok then
				OneOS.System.Settings.StartupProgram = path
				self:GetObject('StartupProgramLabel').Text = path
			end
		end)
	end

	self:GetObject('NoneStartupProgramButton').OnClick = function(_, event, side, x , y)
		OneOS.System.Settings.StartupProgram = nil
		self:GetObject('StartupProgramLabel').Text = 'None'
	end

end