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
		reason = 'Please enabled HTTP'
	elseif http.checkURL and not http.checkURL(url) then
		reason = 'Please set HTTP whitelist to "*"'
	end

	if not reason then
		local ok, err = http.request(url)
		if ok ~= false then -- on earlier versions ok will be nil regardless
			self.TimeoutTimer = self.Bedrock:StartTimer(function()
				if not self.Failed and not self.Success then
					self.Failed = true
					self:OnDataFailed(url, 'Request timeout')
				end
			end, 0)
		else
			if err then
				reason = err
			else
				reason = 'HTTP request error'
			end
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
		Y = '50%,-2',
		Type = 'Label',
		Text = 'Loading Failed',
		TextColour = 'red'
	})

	self:AddObject({
		X = 1,
		Width = '100%',
		Align = 'Center',
		Y = '50%,-1',
		Type = 'Label',
		Text = reason,
		TextColour = 'orange'
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