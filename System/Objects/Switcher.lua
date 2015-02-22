Inherit = 'View'

AnimationSpeed = 0.4
LastPrograms = {}
ProgramOrder = {}
LeftMargin = 0

OnLoad = function(self)
	self.BackgroundColour = colours.green

	self:AddObject({
		X = 1,
		Type = 'FilterLabel',
		Name = 'ProgramCloseButton',
		Text = 'x',
		Align = 'Center',
		Width = 3,
		AutoWidth = false,
		FilterName = 'Highlight',
		OnClick = function()
			local program = System.CurrentProgram()
			if program and program.Close then
				program:Close()
			end
		end
	})

	self:AddObject({
		X = 1,
		Width = 1,
		Visible = false,
		Type = 'FilterView',
		FilterName = 'Highlight'
	})

	-- self:AddObject({
	-- 	X = 1,
	-- 	Width = 5,
	-- 	Type = 'FilterView',
	-- 	NameType = 'OneButtonFilterView',
	-- 	FilterName = 'Darker'
	-- })

	self:AddObject({
		X = -4,
		Type = 'FilterLabel',
		Name = 'OneButton',
		Text = 'One',
		AutoWidth = false,
		Width = 5,
		Align = 'Center',
		Passes = 2,
		FilterName = 'Highlight'
	})

	self:AddObject({
		X = 1,
		Width = '100%',
		Align = 'Center',
		Type = 'FilterLabel',
		Name = 'OneLabel',
		Text = 'OneOS',
		FilterName = 'Highlight'
	})
end

OnUpdate = function(self, value)
	if value == 'LeftMargin' then
		local oneButton = self:GetObject('OneButton')
		if oneButton then
			oneButton:AnimateValue('X', nil, self.LeftMargin - 4, self.AnimationSpeed)
		end
	elseif value == 'BackgroundColour' and self.Bedrock.View then
		if self.Bedrock:GetObject('SplashView') then
			self.Bedrock:RemoveObject('SplashView')
		end
	end
end

SwitchBackground = function(self, from, to, direction)
	self.BackgroundColour = colours.black
	
	local margin = 5
	
	local one = self:AddObject({
		X = (self.Width + margin) * direction,
		BackgroundColour = to,
		Type = 'View',
		Width = self.Width
	}, nil, true)
	one:AnimateValue('X', (self.Width + margin) * direction, 1, self.AnimationSpeed)

	local two = self:AddObject({
		X = 1,
		BackgroundColour = from,
		Type = 'View',
		Width = self.Width
	}, nil, true)
	two:AnimateValue('X', 1, (self.Width + 1 + margin) * -direction, self.AnimationSpeed, function()
		self.Bedrock:RemoveObject(one)		
		self.Bedrock:RemoveObject(two)
		self.BackgroundColour = to
	end)
end

UpdateButtons = function(self)
	if System.CurrentProgram().Hidden then
		self.LeftMargin = 0
	else
		self.LeftMargin = self:GetObject('OneButton').Width
	end

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
					Type = 'FilterLabel',
					Align = 'Center',
					AutoWidth = false,
					FilterName = 'Highlight',
					Text = v.Title,
					ProgramView = v,
					OnClick = function(_, event, side)
						if side == 1 then
							v:MakeActive()
						elseif side == 3 then
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

	local buttonWidth = math.floor((self.Width - self.LeftMargin) / count)
	local activeButtonWidth = self.Width - self.LeftMargin - (buttonWidth * (count - 1))

	local x = 1 + self.LeftMargin
	local activeX
	local activeProgram = System.CurrentProgram()
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
			button:AnimateValue('Width', nil, newWidth, self.AnimationSpeed, function()
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
			filterView:AnimateValue('X', nil, activeX, self.AnimationSpeed)
			filterView:AnimateValue('Width', nil, activeButtonWidth, self.AnimationSpeed)
			closeButton:AnimateValue('X', nil, activeX, self.AnimationSpeed)
		end
		
	else
		self:GetObject('FilterView').Visible = false
		self:GetObject('ProgramCloseButton').Visible = false
		self:GetObject('FilterView').X = 1
	end
	
	if self.LeftMargin == 0 and count == 0 then
		self:GetObject('OneLabel').Visible = true
	else
		self:GetObject('OneLabel').Visible = false
	end

end