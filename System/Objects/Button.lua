	BackgroundColour = colours.lightGrey
	ActiveBackgroundColour = colours.blue
	ActiveTextColour = colours.white
	TextColour = colours.black
	Text = ""
	Toggle = nil
	Momentary = false
	AutoWidth = false

	OnUpdate = function(self, value)
		if value == 'Text' and self.AutoWidth then
			self.Width = #self.Text + 2
			self:UpdateEvokers()
			return true
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

		Drawing.DrawBlankArea(x, y, self.Width, self.Height, bg)
		Drawing.DrawCharactersCenter(x, y, self.Width, self.Height, self.Text, txt, bg)

		if self.Momentary then
			self.Toggle = false
		end
	end

	Click = function(self, side, x, y)
		if self.Visible and self.OnClick then
			if self:OnClick(side, x, y, not self.Toggle) ~= false and self.Toggle ~= nil then
				self.Toggle = not self.Toggle
			end
			return true
		else
			return false
		end
	end