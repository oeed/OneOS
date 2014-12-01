Inherit = 'View'
IsSleepMode = false

OnDraw = function(self, x, y)
	for _y, row in ipairs(Drawing.Buffer) do
		for _x, pixel in ipairs(row) do
			Drawing.WriteToBuffer(_x, _y, pixel[1], Drawing.FilterColour(pixel[2], Drawing.Filters.Greyscale), Drawing.FilterColour(pixel[3], Drawing.Filters.Greyscale))
		end
	end
end

TryUnlock = function(self, password)
	local secureTextBox = self:GetObject('SecureTextBox')
	secureTextBox.Text = ''
	if password ~= '' and Settings:CheckPassword(password) then
		Log.i('Password correct, unlocking.')
		self.Visible = false
		self.Bedrock:SetActiveObject()
		self:OnUnlock(self.IsSleepMode)
	else
		Log.i('Password incorrect.')
		local label = self:GetObject('Label')
		local secureStartX = secureTextBox.X
		local labelStartX = label.X
		local maxDelta = 4
		local steps = {
			-2,
			-4,
			-2,
			0,
			2,
			4,
			2,
			0,
			-1,
			-2,
			-1,
			0,
			1,
			2,
			1,
			0
		}
		if Settings:GetValues()['UseAnimations'] then
			self.Bedrock:SetActiveObject()
			local i = 1
			self.Bedrock:StartRepeatingTimer(function(newTimer)
				secureTextBox.X = secureStartX + steps[i]
				label.X = labelStartX + steps[i]
				i = i + 1
				if i > #steps then
					self.Bedrock:StopTimer(newTimer)
					self.Bedrock:SetActiveObject(secureTextBox)
				end
			end, 0.05)
		end
	end
end

Lock = function(self)
	if Settings:GetValues()['Password'] == nil then
		Log.i('No password, unlocking.')
		self.Visible = false
		if self.OnUnlock then
			self:OnUnlock(self.IsSleepMode)
		end
		return
	end
	self.Visible = true

	local secureTextBox = self:GetObject('SecureTextBox')
	secureTextBox.OnChange = function(_self, event, keychar)
		if keychar == keys.enter then
			self:TryUnlock(secureTextBox.Text)
		end
	end
	self.Bedrock:SetActiveObject(secureTextBox)

	self:GetObject('ExitButton').OnClick = function(_self, event, side, x, y)
		if self.IsSleepMode then
		else
			Shutdown(true)
		end
	end
end

OnClick = function(self, event, side, x, y)
end