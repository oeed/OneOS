Inherit = 'ScrollView'

PageInfo = nil
Failed = false
Success = false
RequestURL = nil
TimeoutTimer = nil
TimeoutLength = 5
LoadingText = nil

OnLoad = function(self)
	self.Failed = false
	self.Success = false
	self:RemoveAllObjects()
	ScrollView.OnLoad(self)
	self:AddObject({
		X = '50%,-4',
		Y = '50%,-3',
		Type = 'LoadingIndicator',
	})
	self:FetchData()
end

FetchData = function(self)
	local url = self:DataURL(self.PageInfo)
	self.RequestURL = url
	local reason

	if not http then
		reason = 'NOHTTP'
	elseif http.checkURL and not http.checkURL(url) then
		reason = 'BLOCKED'
	end

	if not reason then
		local ok = http.request(url)
		if ok then
			self.TimeoutTimer = self.Bedrock:StartTimer(function()
				if not self.Failed and not self.Success then
					self.Failed = true
					self:OnDataFailed(url, 'TIMEOUT')
				end
			end, self.TimeoutLength)
		else
			reason = 'REQUEST'
		end
	end

	if reason then
		self.Failed = true
		self:OnDataFailed(url, reason)
	end
end

OnDataFailed = function(self, url, reason)
	self:RemoveAllObjects()
	self:AddObject({
		X = 1,
		Width = '100%',
		Align = 'Center',
		Y = '50%,-1',
		Type = 'Label',
		Text = 'Loading Failed '..reason,
		TextColour = 'red'
	})

	self:AddObject({
		X = 1,
		Y = '50%,1',
		X = '50%,-7',
		Type = 'Button',
		TextColour = 'white',
		BackgroundColour = 'red',
		Text = 'Back',
		OnClick = function()
			self.Bedrock:OpenPreviousPage()
		end
	})

	self:AddObject({
		X = 1,
		Y = '50%,1',
		X = '50%,1',
		Type = 'Button',
		TextColour = 'white',
		BackgroundColour = 'red',
		Text = 'Retry',
		OnClick = function()
			self:OnLoad()
		end
	})
end

OnDataLoaded = function()

end