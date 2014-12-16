Inherit = 'View'

Value = 1
Minimum = 1
Maximum = 99
BackgroundColour = colours.lightGrey
TextBoxTimer = nil
Width = 7

OnLoad = function(self)
	self:AddObject({
		X = self.Width - 1,
		Y = 1,
		Width = 1,
		AutoWidth = false,
		Text = '-',
		Type = 'Button',
		Name = 'AddButton',
		BackgroundColour = colours.transparent,
		OnClick = function()
			self:ShiftValue(-1)
		end
	})

	self:AddObject({
		X = self.Width,
		Y = 1,
		Width = 1,
		AutoWidth = false,
		Text = '+',
		Type = 'Button',
		Name = 'SubButton',
		BackgroundColour = colours.transparent,
		OnClick = function()
			self:ShiftValue(1)
		end
	})

	self:AddObject({
		X = 1,
		Y = 1,
		Width = self.Width - 2,
		Text = tostring(self.Value),
		Align = 'Center',
		Type = 'TextBox',
		BackgroundColour = colours.transparent,
		OnChange = function(_self, event, keychar)
			if keychar == keys.enter then
				self:SetValue(tonumber(_self.Text))
				self.TextBoxTimer = nil
			end
			if self.TextBoxTimer then
				self.Bedrock:StopTimer(self.TextBoxTimer)
			end

			self.TextBoxTimer = self.Bedrock:StartTimer(function(_, timer)
				if timer and timer == self.TextBoxTimer then
					self:SetValue(tonumber(_self.Text))
					self.TextBoxTimer = nil
				end
			end, 2)
		end
	})
end

OnScroll = function(self, event, dir, x, y)
	self:ShiftValue(-dir)
end

ShiftValue = function(self, delta)
	local val = tonumber(self:GetObject('TextBox').Text) or self.Minimum
	self:SetValue(val + delta)
end

SetValue = function(self, newValue)
	newValue = newValue or 0
	if self.Maximum and newValue > self.Maximum then
		newValue = self.Maximum
	elseif self.Minimum and newValue < self.Minimum then
		newValue = self.Minimum
	end
	self.Value = newValue
	if self.OnChange then
		self:OnChange()
	end
end

OnUpdate = function(self, value)
	if value == 'Value' then
		local textbox = self:GetObject('TextBox')
		if textbox then
			textbox.Text = tostring(self.Value)
		end
	end
end