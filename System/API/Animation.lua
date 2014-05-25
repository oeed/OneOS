Animations = {
	
}

HandleTimer = function(timer)
	for i, animation in ipairs(Animations) do
		if animation.timer == timer then
			if  animation.step <= animation.maxstep then
				animation.step = animation.step + 1
				animation.func()
				if animation.step == animation.maxstep + 1 then
					if animation.canDraw or animation.canDraw == nil then
						Current.CanDraw = true
					end
					animation.done()
					Drawing.TryRestore = false
					--MainDraw()
				else
					animation.timer = os.startTimer(animation.interval)
				end
				Animations[i] = animation
			end
			return true
		end
	end
	return false
end

RectangleSize = function(centerX, centerY, startWidth, startHeight, doneWidth, doneHeight, colour, time, done)
	if not Settings:GetValues()['UseAnimations'] then
		done()
		return
	end
	Drawing.TryRestore = true
	Restore()
	doneHeight = doneHeight + 2
	doneWidth = doneWidth + 2
	Current.CanDraw = false
	centerX = math.ceil(centerX)
	centerY = math.ceil(centerY)

	local fps = 30
	local steps = fps * time

	local w = 1
	local h = 1
	local deltaW = (doneWidth - startWidth) / steps
	local deltaH = (doneHeight - startHeight) / steps

	local timer = os.startTimer(1 / fps)

	table.insert(Animations, {step = 1, maxstep = steps, interval = 1 / fps, timer = timer, done = function() Drawing.Clear(colours.black) done() end, func = function(self)
		w = w + deltaW
		h = h + deltaH
		Drawing.DrawArea(centerX - (w / 2), centerY - (h / 2), w, h, " ", colours.white, colour)
		Drawing.DrawBuffer()
	end})
end

SwipeProgram = function(currentProgram, newProgram, direction)
	local done = function()
		Drawing.Clear(colours.black)
		Current.CanDraw = true
		Current.Program = newProgram
		Current.Program.AppRedirect:Draw()
		Overlay.UpdateButtons()
		MainDraw()
	end
	if not Settings:GetValues()['UseAnimations'] then
		done()
		return
	end
	Drawing.TryRestore = true
	Restore()
	local fps = 20
	local steps = fps * 0.2
	local deltaX = ((Drawing.Screen.Width + 4) / steps) * direction

	local timer = os.startTimer(1 / fps)
	local currentOffset = 0
	local newOffset = Drawing.Screen.Width + 4

	local currentBuffer = currentProgram.AppRedirect.Buffer
	local newBuffer = newProgram.AppRedirect.Buffer
	local blankOffset = Drawing.Screen.Width
	if direction == -1 then
		blankOffset = -5
		newOffset = -(Drawing.Screen.Width + 4)
	end

	Current.CanDraw = false
	table.insert(Animations, {step = 1, maxstep = steps, interval = 1 / fps, timer = timer, done = done, func = function(self)
		currentOffset = currentOffset - deltaX
		newOffset = newOffset - deltaX
		Drawing.DrawBlankArea(currentOffset + blankOffset, 2, 5, Drawing.Screen.Height-1, colours.black)
		for y, row in ipairs(currentBuffer) do
			for x, pixel in pairs(row) do
				Drawing.WriteToBuffer(x + math.ceil(currentOffset), y+1, pixel[1], pixel[2], pixel[3])
			end
		end
		for y, row in ipairs(newBuffer) do
			for x, pixel in pairs(row) do
				Drawing.WriteToBuffer(x + math.ceil(newOffset), y+1, pixel[1], pixel[2], pixel[3])
			end
		end

		Drawing.DrawBuffer()
	end})
end

SearchToggle = function(isActivate, done)
	local currentOffset = 0
	if not isActivate then
		currentOffset = -1*Search.Width
	end
	if not Settings:GetValues()['UseAnimations'] then
		Restore()
		local endOffset = -1*Search.Width 
		if not isActivate then
			endOffset = 0
		end
		for y, row in ipairs(Search.Buffer) do
			for x, pixel in pairs(row) do
				Drawing.WriteToBuffer(x + math.ceil(endOffset), y, pixel[1], pixel[2], pixel[3])
			end
		end
		Drawing.DrawBuffer()
		done()
		return
	end
	Restore()
	Drawing.TryRestore = true
	local direction = 1
	if isActivate then
		direction = -1
	end
	local fps = 20
	local steps = fps * 0.2
	local deltaX = (Search.Width / steps) * direction

	local timer = os.startTimer(1 / fps)

	Current.CanDraw = false
	table.insert(Animations, {step = 1, maxstep = steps, interval = 1 / fps, timer = timer, done = done, canDraw = not isActivate, func = function(self)
		currentOffset = currentOffset + deltaX
		for y, row in ipairs(Search.Buffer) do
			for x, pixel in pairs(row) do
				Drawing.WriteToBuffer(x + math.ceil(currentOffset), y, pixel[1], pixel[2], pixel[3])
			end
		end

		Drawing.DrawBuffer()
	end})
end