Inherit = 'PageView'

TimeoutLength = 40

OnLoad = function(self)
	self:RemoveAllObjects()
	ScrollView.OnLoad(self)
	self:AddObject({
		X = '50%,-4',
		Y = '50%,-3',
		Type = 'LoadingIndicator',
	})
	self:AddObject({
		X = 1,
		Y = '50%,1',
		Width = '100%',
		Align = 'Center',
		Type = 'Label',
		TextColour = 'blue',
		Text = 'Downloading ' .. self.App.Name
	})
	self:FetchData()
end

OnDataLoad = function(self, url, data)
	local location, err = self.App:InstallData(data)
	if err then
		self.Success = false
		self.Failed = true
		self:OnDataFailed(nil, err)
		return
	end

	self:RemoveAllObjects()

	self:AddObject({
		X = 1,
		Y = '50%,-1',
		Width = '100%',
		Align = 'Center',
		Type = 'Label',
		TextColour = 'blue',
		Text = 'Installation Successful'
	})

	self:AddObject({
		X = 1,
		Y = '50%,0',
		Width = '100%',
		Align = 'Center',
		Type = 'Label',
		TextColour = 'lightBlue',
		Text = location
	})

	self:AddObject({
		X = 1,
		Y = '50%,2',
		X = '50%,-4',
		Type = 'Button',
		TextColour = 'white',
		BackgroundColour = 'blue',
		Text = 'Okay',
		OnClick = function()
			self.Bedrock:OpenPreviousPage()
		end
	})
end

DataURL = function(self, info)
	return self.Bedrock.AppStoreURL .. 'api/?command=application&subcommand=download&id=' .. textutils.urlEncode(self.App.ID)
end