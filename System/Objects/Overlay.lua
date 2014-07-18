Inherit = 'View'

TextColour = colours.black
BackgroundColour = colours.white

OnDraw = function(self, x, y)
	if self.BackgroundColour then
		Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
	end
end

OnLoad = function(self)
	self:GetObject('OneButton').OnClick = function(btn)
		if btn:ToggleMenu('onemenu') then
			--TODO: updating
			self.Bedrock:GetObject('DesktopMenuItem').OnClick = function(itm)
				Current.Desktop:SwitchTo()
			end

			self.Bedrock:GetObject('AboutMenuItem').OnClick = function(itm)
				Helpers.OpenFile('System/Programs/About OneOS.program')
			end

			self.Bedrock:GetObject('SettingsMenuItem').OnClick = function(itm)
				Helpers.OpenFile('System/Programs/Settings.program')
			end

			self.Bedrock:GetObject('RestartMenuItem').OnClick = function(itm)
				Restart()
			end

			self.Bedrock:GetObject('ShutdownMenuItem').OnClick = function(itm)
				Shutdown()
			end
		end
	end

	self:GetObject('SearchButton').OnClick = function(btn, event, side, x, y, toggle)
		if toggle then
			Search.Open()
		end
	end

	self:UpdateButtons()
end

UpdateButtons = function(self)
	if Current.Program then
		if Current.Program.Environment.OneOS.ToolBarColor ~= colours.white then
			self.BackgroundColour = Current.Program.Environment.OneOS.ToolBarColor
		else
			self.BackgroundColour = Current.Program.Environment.OneOS.ToolBarColour
		end
		
		if Current.Program.Environment.OneOS.ToolBarTextColor ~= colours.black then
			self.TextColour = Current.Program.Environment.OneOS.ToolBarTextColor
		else
			self.TextColour = Current.Program.Environment.OneOS.ToolBarTextColour
		end
	else
		self.BackgroundColour = colours.white
		self.TextColour = colours.black
	end

	for i, v in ipairs(self.Children) do
		if v.TextColour then
			v.TextColour = self.TextColour
		end
	end

	--TODO: make this more efficient
	self:RemoveObjects('ProgramButton')

	local x = 6
	for i, program in ipairs(Current.Programs) do
		if program and not program.Hidden then
			local bg = self.BackgroundColour
			local tc = self.TextColour
			local button = ''
			if Current.Program and Current.Program == program then
				bg = colours.lightBlue
				tc = colours.white
				button = 'x '
			end

			local object = self:AddObject({
		      ["Y"]=1,
		      ["X"]=x,
		      ["Name"]="ProgramButton",
		      ["Type"]="Button",
		      ["Text"]=button..program.Title,
		      ["TextColour"]=tc,
		      ["BackgroundColour"]=bg
		    })
		    x = x + object.Width

			object.Program = program

		    object.OnClick = function(obj, event, side, x, y)
		    	if side == 3 then
		    		obj.Program:Close()
		    	elseif button == 'x ' then
		    		if x == 2 then
		    			obj.Program:Close()
		    		end
		    	else
		    		obj.Program:SwitchTo()
		    	end
				self:UpdateButtons()
		   	end
		end
	end
	if not self.Bedrock.IsDrawing then
		self:ForceDraw()
	end
end