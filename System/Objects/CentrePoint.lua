Inherit = 'View'


OnLoad = function(self)
	self:GetObject('AboutButton').OnClick = function(itm)
		Helpers.OpenFile('System/Programs/About OneOS.program')
	end

	self:GetObject('SettingsButton').OnClick = function(itm)
		Helpers.OpenFile('System/Programs/Settings.program')
	end

	self:GetObject('UpdateButton').OnClick = function(itm)
		CheckAutoUpdate(true)
	end

	self:GetObject('RestartButton').OnClick = function(itm)
		Restart()
	end

	self:GetObject('ShutdownButton').OnClick = function(itm)
		Shutdown()
	end
	self.Visible = false
end

local oldProgram = nil
Show = function(self)
	-- self:UpdatePreviews()
	self:UpdatePrograms()
	oldProgram = Current.Program
	Current.Program = nil
	self.Bedrock:GetObject('Overlay').CenterPointMode = true
	self.Bedrock:GetObject('Overlay'):GetObject('OneButton').Toggle = true
	UpdateOverlay()
	self.Visible = true
end

UpdatePrograms = function(self)
	self:AddObject({
		X = 10,
		Y = 8,
		Type = 'ProgramPreview',
		Program = Current.Program
	})
end

Hide = function(self)
	-- self:UpdatePreviews()
	
	self.Visible = false
	self.Bedrock:GetObject('Overlay').CenterPointMode = false
	self.Bedrock:GetObject('Overlay'):GetObject('OneButton').Toggle = false
	if oldProgram and oldProgram.Running then
		oldProgram:SwitchTo()
	else
		Current.Desktop:SwitchTo()
	end
end