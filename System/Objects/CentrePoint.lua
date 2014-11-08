Inherit = 'View'

local oldProgram = nil
local oldActive = nil
local oldProgramPosition = nil

OnLoad = function(self)
	self:GetObject('AboutButton').OnClick = function(itm)
		oldProgram = Current.Desktop
		Helpers.OpenFile('System/Programs/About OneOS.program')
	end

	self:GetObject('SettingsButton').OnClick = function(itm)
		oldProgram = Current.Desktop
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

Show = function(self)
	-- self:UpdatePreviews()
	oldProgram = Current.Program
	self:UpdatePrograms()
	oldActive = self.Bedrock:GetActiveObject()
	Current.Program = nil
	self.Bedrock:GetObject('Overlay').CenterPointMode = true
	self.Bedrock:GetObject('Overlay'):GetObject('OneButton').Toggle = true
	self.Bedrock:SetActiveObject(nil)
	UpdateOverlay()
	self.Visible = true
	self:AnimateEntry()
end

function AnimateEntry(self)
	local animatePreview = self:GetObject('AnimateProgramPreview')
	if Settings:GetValues()['UseAnimations'] then
		animatePreview.Visible = true
		animatePreview.X = 1
		animatePreview.Y = 1
		animatePreview.Width = self.Width
		animatePreview.Height = self.Height
		animatePreview.Program = oldProgram
		animatePreview:UpdatePreview()

		local steps = 5
		local deltaW = (self.Width - ProgramPreview.PreviewWidth) / steps
		local deltaH = (self.Height - ProgramPreview.PreviewHeight) / steps
		local deltaX = deltaW 
		local deltaY = deltaH 
		if oldProgramPosition then
			deltaX = (self.X - oldProgramPosition.X) / steps
			deltaY = (self.Y - oldProgramPosition.Y - 1) / steps
		end

		self.Bedrock:GetObject('Overlay'):Draw()
		for i = 1, steps do
			animatePreview.X = animatePreview.X - deltaX
			animatePreview.Y = animatePreview.Y - deltaY
			animatePreview.Width = animatePreview.Width - deltaW
			animatePreview.Height = animatePreview.Height - deltaH
			animatePreview:UpdatePreview()
			self:Draw()
			Drawing.DrawBuffer()
		end
		self.Bedrock:Draw()
	end
	animatePreview.Visible = false
end

function AnimateExit(self)
	local animatePreview = self:GetObject('AnimateProgramPreview')
	Current.Program = oldProgram
	Current.ProgramView.CachedProgram = nil
	Current.ProgramView:ForceDraw()
	if Settings:GetValues()['UseAnimations'] then
		local previews = self:GetObjects('ProgramPreview')

		for i, v in ipairs(previews) do
			if v.Program == oldProgram then
				oldProgramPosition = self.Bedrock:GetAbsolutePosition(v)
			end
		end

		animatePreview.Visible = true
		animatePreview.X = oldProgramPosition.X
		animatePreview.Y = oldProgramPosition.Y
		animatePreview.Width = ProgramPreview.PreviewWidth
		animatePreview.Height = ProgramPreview.PreviewHeight
		animatePreview.Program = oldProgram
		animatePreview:UpdatePreview()

		local steps = 5
		local deltaW = (ProgramPreview.PreviewWidth - self.Width - 1) / steps
		local deltaH = (ProgramPreview.PreviewHeight - self.Height - 1) / steps
		local deltaX = deltaW 
		local deltaY = deltaH 
		if oldProgramPosition then
			deltaX = (oldProgramPosition.X - 1) / steps
			deltaY = (oldProgramPosition.Y - 1) / steps
		end

		for i = 1, steps do
			animatePreview.X = animatePreview.X - deltaX
			animatePreview.Y = animatePreview.Y - deltaY
			animatePreview.Width = animatePreview.Width - deltaW
			animatePreview.Height = animatePreview.Height - deltaH
			if i == steps then
				animatePreview.X = 1
				animatePreview.Y = 1
				animatePreview.Width = self.Width
				animatePreview.Height = self.Height
				self.Bedrock:GetObject('Overlay'):UpdateButtons()
				self.Bedrock:GetObject('Overlay'):Draw()
			end
			animatePreview:UpdatePreview()
			self:Draw()
			Drawing.DrawBuffer()
		end
		self.Bedrock:Draw()
	end
	animatePreview.Visible = false
end

UpdatePrograms = function(self)
	self:RemoveObjects('ProgramPreview')

	local maxCols = math.floor(self.Width / (2 + ProgramPreview.Width))
	local currentY = 3

	local rows = {}
	for i, program in ipairs(Current.Programs) do
		local row = math.ceil(i / maxCols)
		Log.i(row)
		if not rows[row] then
			rows[row] = {}
		end
		table.insert(rows[row], program)
	end

	local scrollView = self:GetObject('ScrollView')
	for i, row in ipairs(rows) do
		local currentX = math.ceil((self.Width - (#row * (2 + ProgramPreview.Width)) + 2)/2)
		for i2, program in ipairs(row) do
			local obj = scrollView:AddObject({
				X = currentX,
				Y = currentY,
				Type = 'ProgramPreview',
				Program = program,
				OnClick = function(prv, event, side, x, y)
					if not prv.Program.Hidden and ((x == 1 and y == 1) or side == 3) then
						prv.Program:Close()
						prv.Bedrock:GetObject('CentrePoint'):UpdatePrograms()
					else
						oldProgram = prv.Program
						prv.Bedrock:GetObject('CentrePoint'):Hide()
						-- prv.Program:SwitchTo()
					end
				end
			})
			if program == oldProgram then
				oldProgramPosition = self.Bedrock:GetAbsolutePosition(obj)
			end
			currentX = currentX + 2 + ProgramPreview.Width
		end
		currentY = currentY + ProgramPreview.Height + 1
	end
	scrollView:UpdateScroll()
end

Hide = function(self)
	self.Bedrock:GetObject('Overlay').CenterPointMode = false
	self.Bedrock:GetObject('Overlay'):GetObject('OneButton').Toggle = false
	self:AnimateExit()
	self.Visible = false
	self.Bedrock:SetActiveObject(oldActive)
	if oldProgram and oldProgram.Running then
		oldProgram:SwitchTo()
	else
		Current.Desktop:SwitchTo()
	end
end