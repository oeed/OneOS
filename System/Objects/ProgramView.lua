UpdateDrawBlacklist = {['CachedProgram']=true, ['CachedIndex']=true}
CachedProgram = false
CachedIndex = false
Animation = false

OnUpdate = function(self, value)
	--TODO: resize the buffer
	if value == 'Width' then
	end
end

local function getProgramIndex(program)
	for i, _program in ipairs(Current.Programs) do
		if program == _program then
			return i
		end
	end
	return 1
end

OnDraw = function(self, x, y)
	local currentIndex = getProgramIndex(Current.Program)

	if Current.Program == nil and #Current.Programs > 1 then
		if Current.Programs[self.CachedIndex] then
			Current.Program = Current.Programs[self.CachedIndex]
		elseif Current.Programs[self.CachedIndex-1] then
			Current.Program = Current.Programs[self.CachedIndex-1]
		end
	end

	if not self.Animation then
		self.Bedrock.DrawSpeed = self.Bedrock.DefaultDrawSpeed
	end

	if self.Animation then
		self:DrawAnimation()
	elseif (#Current.Programs == 1 or (Current.Program and Current.Program.Hidden)) and self.CachedProgram and not self.CachedProgram.Hidden then
		--closing a program
		UpdateOverlay()
		local centerX = math.ceil(self.Width / 2)
		local centerY = math.ceil(self.Height / 2)

		local w = self.Width
		local h = self.Height
		local deltaW = w / 5
		local deltaH = h / 5

		local colour = colours.white
		if self.CachedProgram.Environment.OneOS.ToolBarColor ~= colours.white then
			colour = self.CachedProgram.Environment.OneOS.ToolBarColor
		elseif self.CachedProgram.Environment.OneOS.ToolBarColour then
			colour = self.CachedProgram.Environment.OneOS.ToolBarColour
		end

		self.Animation = {
			Count = 5,
			Function = function(i)
				self:DrawProgram(Current.Desktop, x, y)
				w = w - deltaW
				h = h - deltaH
				Drawing.DrawBlankArea(x + centerX - (w / 2), y + centerY - (h / 2), w, h, colour)
			end
		}
		self:DrawAnimation()

		Current.Desktop:SwitchTo()
	elseif Current.Program and not Current.Program.Hidden and self.CachedProgram and self.CachedProgram.Hidden then
		--opening a program
		UpdateOverlay()
		local centerX = math.ceil(self.Width / 2)
		local centerY = math.ceil(self.Height / 2)

		local deltaW = self.Width / 5
		local deltaH = self.Height / 5
		local w = 0
		local h = 0
		local colour = colours.white
		if Current.Program.Environment.OneOS.ToolBarColor ~= colours.white then
			colour = Current.Program.Environment.OneOS.ToolBarColor
		elseif Current.Program.Environment.OneOS.ToolBarColour then
			colour = Current.Program.Environment.OneOS.ToolBarColour
		end

		self.Animation = {
			Count = 5,
			Function = function(i)
				self:DrawProgram(Current.Desktop, x, y)
				w = w + deltaW
				h = h + deltaH
				Drawing.DrawBlankArea(x + centerX - (w / 2) - 2, y + centerY - (h / 2), w, h, colour)
			end
		}
		self:DrawAnimation()
	elseif Current.Program and self.CachedProgram and Current.Program ~= self.CachedProgram and not Current.Program.Hidden and not self.CachedProgram.Hidden then
		--switching program
		UpdateOverlay()
		local direction = 1
		local isPos = 0
		local isNeg = 1
		if getProgramIndex(Current.Program) >= self.CachedIndex then
			direction = -1
			isPos = 1
			isNeg = 0
		end
		local delta = (self.Width + 4) / 5
		self.Animation = {
			Count = 5,
			Function = function(i)
				local offset = x + ((5-i) * delta * direction)
				self:DrawProgram(self.CachedProgram, x + offset - 1, y)
				Drawing.DrawBlankArea(x + offset + isPos * (self.Width) - isNeg * 4 - 1, y, 4, self.Height, colours.black)
				self:DrawProgram(Current.Program, x + offset - isNeg * 2 - direction * (3 + self.Width), y)
			end
		}
		self:DrawAnimation()
	elseif Current.Program then
		if Current.Overlay and self.CachedProgram and self.CachedProgram.Environment and (Current.Program.Environment.OneOS.ToolBarColor ~= Current.Overlay.BackgroundColour or Current.Program.Environment.OneOS.ToolBarColour ~= Current.Overlay.BackgroundColour  or Current.Program.Environment.OneOS.ToolBarTextColor ~= Current.Overlay.TextColour  or Current.Program.Environment.OneOS.ToolBarTextColour ~= Current.Overlay.TextColour) then
			UpdateOverlay()
		end

		self:DrawProgram(Current.Program, x, y)
		self.CachedProgram = Current.Program
		self.CachedIndex = currentIndex
		if self.Bedrock:GetActiveObject() == self then
			if Current.Program.AppRedirect.CursorBlink then
				self.Bedrock.CursorPos = {x + Current.Program.AppRedirect.CursorPos[1] - 1, y + Current.Program.AppRedirect.CursorPos[2] - 1}
				self.Bedrock.CursorColour = Current.Program.AppRedirect.TextColour
			else
				self.Bedrock.CursorPos = nil
			end
		end
	else
		Drawing.DrawBlankArea(x, y, self.Width, self.Height, colours.grey)
		Drawing.DrawCharactersCenter(nil,-1,nil,nil, 'Something went wrong :(', colours.white, colours.transparent)
		Drawing.DrawCharactersCenter(nil,1,nil,nil, 'The desktop crashed or something bugged out.', colours.lightGrey, colours.transparent)
		Drawing.DrawCharactersCenter(nil,2,nil,nil, 'Try restarting.', colours.lightGrey, colours.transparent)
	end
end

DrawAnimation = function(self)
	self.Animation.Function(self.Animation.Count)
	self.Animation.Count = self.Animation.Count - 1
	if self.Animation.Count <= 0 then
		self.Animation = nil
		self.CachedProgram = Current.Program
		self.CachedIndex = currentIndex
	end
	self:ForceDraw()
	--self.Bedrock:Draw()
end

DrawProgram = function(self, program, x, y)
	if program then
		for _y, row in ipairs(program.AppRedirect.Buffer) do
			for _x, pixel in pairs(row) do
				Drawing.WriteToBuffer(x+_x-1, y+_y-1, pixel[1], pixel[2], pixel[3])
			end
		end
	end
end

OnClick = function(self, event, side, x, y)
	if Current.Program then
		Current.Program:Click(event, side, x, y)
	end
end

OnKeyChar = function(self, event, keychar)
	if Current.Program then
		Current.Program:QueueEvent(event, keychar)
	end
end

OnDrag = OnClick
OnScroll = OnClick


--[[
for i, program in ipairs(Current.Programs) do
			if program == self then
				table.remove(Current.Programs, i)

				if Current.Programs[i] then
					--Current.Program = Current.Programs[i]
					Animation.SwipeProgram(self, Current.Programs[i], 1)
				elseif Current.Programs[i-1] then
					--Current.Program = Current.Programs[i-1]
					Animation.SwipeProgram(self, Current.Programs[i-1], -1)
				end
				break
			end
		end

		if Desktop then
			Desktop:RefreshFiles()
		UpdateOverlay()
		if Current.Program then
			Drawing.Clear(colours.black)
			Drawing.DrawBuffer()
			os.queueEvent('oneos_draw')
		else
			if Desktop then
				--Desktop:Draw()
			end
		end
]]--