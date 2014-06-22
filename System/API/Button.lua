	X = 1
	Y = 1
	Width = 0
	Height = 0
	BackgroundColour = colours.white
	ActiveBackgroundColour = colours.blue
	ActiveTextColour = colours.white
	TextColour = colours.black
	Text = ""
	Parent = nil
	_Click = nil
	Toggle = nil
	Momentary = false
	Visible = true
	Name = nil
	AutoWidth = false

	DrawCache = {}

	local function drawCache()
		local UNSET = false
		return {
			--any aspects that, if changed, require redrawing
			Evokers = {
				X = UNSET,
				Y = UNSET,
				Width = UNSET,
				Height = UNSET,
				BackgroundColour = UNSET,
				ActiveBackgroundColour = UNSET,
				ActiveTextColour = UNSET,
				TextColour = UNSET,
				Text = UNSET,
				Parent = UNSET,
				Toggle = UNSET,
				Momentary = UNSET
			},
			NeedsDraw = true,
			AlwaysDraw = false,
			Buffer = {}
		}
	end
	
	NeedsDraw = function(self)
		if not self.DrawCache.Buffer or self.DrawCache.AlwaysDraw or self.DrawCache.NeedsDraw then 
			return true
		end
			term.setTextColour(colours.red)
		for k, v in pairs(self.DrawCache.Evokers) do
			if self[k] ~= v then
				return true
			end
		end
	end

	UpdateEvokers = function(self)
		local evokers = {}
		for k, v in pairs(self.DrawCache.Evokers) do
			evokers[k] = self[k]
		end
		self.DrawCache.Evokers = evokers
	end

	Draw = function(self)
		if not self.Visible then
			return
		end

		if self.AutoWidth then
			self.Width = #self.Text + 2
		end

		if self:NeedsDraw() then
			local bg = self.BackgroundColour

			if self.Toggle then
				bg = self.ActiveBackgroundColour
			end
			if type(bg) == 'function' then
				bg = bg()
			end

			local txt = self.TextColour
			if self.Toggle then
				txt = self.ActiveTextColour
			end
			if type(txt) == 'function' then
				txt = txt()
			end
			local pos = nil
			if GetAbsolutePosition then
				pos = GetAbsolutePosition(self)
			else
				pos = self.Bedrock:GetAbsolutePosition(self)
			end
			Drawing.StartCopyBuffer()
			Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, bg)
			Drawing.DrawCharactersCenter(pos.X, pos.Y, self.Width, self.Height, self.Text, txt, bg)
			self.DrawCache.Buffer = Drawing.EndCopyBuffer()
			self.DrawCache.NeedsDraw = false
		else
			Drawing.DrawCachedBuffer(self.DrawCache.Buffer)
			-- local pos = GetAbsolutePosition(self)
			-- Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, colours.lime)
		end

		if self.Momentary then
			self.Toggle = false
		end

		self:UpdateEvokers()

		RegisterClick(self)
	end

	Initialise = function(self, x, y, width, height, backgroundColour, textColour, activeBackgroundColour, activeTextColour, parent, click, text,  toggle, name)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		height = height or 1
		new.AutoWidth = not width
		if text then
			width = width or #text + 2
		elseif not width then
			width = 2
		end
		new.Width = width
		new.Height = height
		new.Y = y
		new.X = x
		if toggle == 3 then
			new.Momentary = true
			new.Toggle = false
		else
			new.Toggle = toggle
		end
		new.Text = text or ""
		new.BackgroundColour = backgroundColour or self.BackgroundColour
		new.TextColour = textColour or self.TextColour
		new.ActiveBackgroundColour = activeBackgroundColour or self.ActiveBackgroundColour
		new.ActiveTextColour = activeTextColour or self.ActiveTextColour
		new.Parent = parent
		new._Click = click
		new.Visible = true
		new.Name = name
		new.DrawCache = drawCache()
		new:UpdateEvokers()
		return new
	end

	Register = function(self)
		RegisterElement(self)
		return self
	end

	Click = function(self, side, x, y)
		if self.Visible and self._Click then
			if self:_Click(side, x, y, not self.Toggle) ~= false and self.Toggle ~= nil then
				self.Toggle = not self.Toggle
			end
			return true
		else
			return false
		end
	end