BackgroundColour = colours.lightGrey
ActiveBackgroundColour = colours.blue
ActiveTextColour = colours.white
TextColour = colours.black
DisabledTextColour = colours.lightGrey
Text = ""
Toggle = nil
Momentary = true
AutoWidth = true
Align = 'Center'
Enabled = true

OnUpdate = function(self, value)
	if value == 'Text' and self.AutoWidth then
		self.Width = #self.Text + 2
	end
end

OnDraw = function(self, x, y)
	local bg = self.BackgroundColour

	if self.Toggle then
		bg = self.ActiveBackgroundColour
	end

	local txt = self.TextColour
	if self.Toggle then
		txt = self.ActiveTextColour
	end
	if not self.Enabled then
		txt = self.DisabledTextColour
	end
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, bg)

	local _x = 1
    if self.Align == 'Right' then
        _x = self.Width - #self.Text - 1
    elseif self.Align == 'Center' then
        _x = math.floor((self.Width - #self.Text) / 2)
    end
	Drawing.DrawCharacters(x + _x, y, self.Text, txt, bg)

	if self.Momentary and self.Toggle ~= false then
		self.Toggle = false
	end
end

OnLoad = function(self)
	if self.Toggle ~= nil then
		self.Momentary = false
	end
end

Click = function(self, event, side, x, y)
	if self.Visible and not self.IgnoreClick and self.Enabled then
		if self.OnClick then
			local newToggle = not self.Toggle
			if self:OnClick(event, side, x, y, not self.Toggle) ~= false and self.Toggle ~= nil then
				self.Toggle = newToggle
			end
		else
			self.Toggle = not self.Toggle
		end
		return true
	else
		return false
	end
end