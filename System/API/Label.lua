	X = 1
	Y = 1
	Width = 0
	Height = 0
	BackgroundColour = colours.transparent
	TextColour = colours.black
	Text = ""
	Parent = nil
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
				TextColour = UNSET,
				Text = UNSET,
				Parent = UNSET,
				AutoWidth = UNSET,
				Wrapping = UNSET
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

	local wrapText = function(text, maxWidth)
		local lines = {''}
	    for word, space in text:gmatch('(%S+)(%s*)') do
            local temp = lines[#lines] .. word .. space:gsub('\n','')
            if #temp > maxWidth then
                    table.insert(lines, '')
            end
            if space:find('\n') then
                    lines[#lines] = lines[#lines] .. word
                    
                    space = space:gsub('\n', function()
                            table.insert(lines, '')
                            return ''
                    end)
            else
                    lines[#lines] = lines[#lines] .. word .. space
            end
	    end
		return lines
	end

	Draw = function(self)
		if not self.Visible then
			return
		end

		if self.AutoWidth then
			self.Width = #self.Text
		end

		if self:NeedsDraw() then
			local pos = self.Bedrock:GetAbsolutePosition(self)
			Drawing.StartCopyBuffer()

			for i, v in ipairs(wrapText(self.Text, self.Width)) do
				Drawing.DrawCharacters(pos.X, pos.Y + i - 1, v, self.TextColour, self.BackgroundColour)
			end
			self.DrawCache.Buffer = Drawing.EndCopyBuffer()
			self.DrawCache.NeedsDraw = false
		else
			Drawing.DrawCachedBuffer(self.DrawCache.Buffer)
		end

		if self.Momentary then
			self.Toggle = false
		end

		self:UpdateEvokers()

		RegisterClick(self)
	end

	Initialise = function(self, x, y, width, height, backgroundColour, textColour, parent, click, text, name)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		height = height or 1
		new.AutoWidth = not width
		if text then
			width = width or #text
		else
			width = 0
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