Inherit = 'View'

AnimationSpeed = 0.2
LastPrograms = {}
ProgramOrder = {}
TextColour = colours.white

OnLoad = function(self)
	self:AddObject({
		X = 1,
		Type = 'Button',
		Name = 'ProgramCloseButton',
		Text = 'x',
		TextColour = self.TextColour,
		BackgroundColour = colours.transparent,
		ActiveBackgroundColour = colours.transparent,
		OnClick = function()
			Log.i('click')
			local program = self.Bedrock:GetActiveObject()
			if program and program.Close then
			Log.i('close')
				program:Close()
			end
		end
	})

	self:AddObject({
		X = 1,
		Width = 1,
		Visible = false,
		Type = 'FilterView',
		FilterName = 'Lighter'
	})

	-- self:AddObject({
	-- 	X = 1,
	-- 	Width = 5,
	-- 	Type = 'FilterView',
	-- 	NameType = 'OneButtonFilterView',
	-- 	FilterName = 'Darker'
	-- })

	self:AddObject({
		X = 1,
		Type = 'Button',
		Name = 'OneButton',
		Text = 'One',
		TextColour = self.TextColour,
		BackgroundColour = colours.transparent,
		ActiveBackgroundColour = colours.transparent
	})
end

OnUpdate = function(self, value)
	if value == 'BackgroundColour' and self:GetObject('FilterView') then
		if self.BackgroundColour == colours.white then
			self.TextColour = colours.grey
		else
			self.TextColour = colours.orange
		end
		if Drawing.FilterColour(self.BackgroundColour, Drawing.Filters['Lighter']) == colours.white then
			self:GetObject('FilterView').FilterName = 'Darker'
		else
			self:GetObject('FilterView').FilterName = 'Lighter'
		end
	elseif value == 'TextColour' then
		for i, v in ipairs(self.Children) do
			if v.Name == 'OneButton' then
				v.TextColour = Drawing.FilterColour(self.TextColour, Drawing.Filters[self:GetObject('FilterView').FilterName])
			else
				v.TextColour = self.TextColour
			end
		end
	end
end

UpdateButtons = function(self)
	self.BackgroundColour = colours.red
	local count = 0
	local newPrograms = {}
	for i, v in ipairs(self.Bedrock:GetObjects('ProgramView')) do
		if not v.Hidden then
			local name = tostring(v)
			newPrograms[name] = v
			count = count + 1
			if not self.LastPrograms[name] then
				self:AddObject({
					Name = 'ProgramButton:' .. name,
					Type = 'Button',
					Align = 'Center',
					AutoWidth = false,
					BackgroundColour = colours.transparent,
					ActiveBackgroundColour = colours.transparent,
					Text = v.Title,
					TextColour = self.TextColour,
					OnClick = function(_, event, side)
						if side == 1 then
							v:MakeActive()
						elseif side == 3 then
							Log.i('hi')
							v:Close()
						end
					end
				}, nil, true)
				table.insert(self.ProgramOrder, name)
			end
		end
	end

	for name, v in pairs(self.LastPrograms) do
		if not newPrograms[name] then
			self:RemoveObject('ProgramButton:'..name)
			for i, n in ipairs(self.ProgramOrder) do
				if n == name then
					table.remove(self.ProgramOrder, i)
					break
				end
			end
		end
	end
	self.LastPrograms = newPrograms

	local buttonWidth = math.floor((self.Width - 5) / count)
	local activeButtonWidth = self.Width - 5 - (buttonWidth * (count - 1))

	local x = 6
	local activeX
	local activeProgram = self.Bedrock:GetActiveObject()
	for i, name in pairs(self.ProgramOrder) do
		local program = newPrograms[name]
		local button = self:GetObject('ProgramButton:'..name)
		local isActive = (program == activeProgram)

		local newWidth = (isActive and activeButtonWidth - 2 or buttonWidth)
		local newX = (isActive and x + 2 or x)

		if button.X == 1 then
			button.Width = newWidth
			button.X = newX
		else
			Log.i('start anm1')
			Log.i(self.Bedrock.AnimationEnabled)
			button:AnimateValue('Width', nil, newWidth, self.AnimationSpeed, function()
				Log.i('done')
				end)
			button:AnimateValue('X', nil, newX, self.AnimationSpeed)
		end
		button.Text = self.Bedrock.Helpers.TruncateString(program.Title, newWidth - 2)

		if isActive then
			activeX = x
		end
		x = x + (isActive and activeButtonWidth or buttonWidth)
	end

	if activeX then
		local filterView = self:GetObject('FilterView')
		local closeButton = self:GetObject('ProgramCloseButton')
		if not filterView.Visible then
			filterView.X = activeX
			filterView.Width = activeButtonWidth
			filterView.Visible = true
			closeButton.Visible = true
			closeButton.X = activeX
		else
			Log.i('start anm2')
			filterView:AnimateValue('X', nil, activeX, self.AnimationSpeed)
			filterView:AnimateValue('Width', nil, activeButtonWidth, self.AnimationSpeed)
			closeButton:AnimateValue('X', nil, activeX, self.AnimationSpeed)
		end
		
	else
		Log.i('NONONONON')
		self:GetObject('FilterView').Visible = false
		self:GetObject('ProgramCloseButton').Visible = false
		self:GetObject('FilterView').X = 1
	end

end