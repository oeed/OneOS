BackgroundColour = colours.lightGrey
BarColour = colours.lightBlue
Scroll = 0
MaxScroll = 0
ClickPoint = nil
Fixed = true

OnUpdate = function(self, value)
	if value == 'Text' and self.AutoWidth then
		self.Width = #self.Text + 2
	end
end

OnDraw = function(self, x, y)
	local barHeight = self.Height * (self.Height / (self.Height + self.MaxScroll))
    if barHeight < 3 then
      barHeight = 3
    end
    local percentage = (self.Scroll/self.MaxScroll)

    Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
    Drawing.DrawBlankArea(x, y + self.Bedrock.Helpers.Round(self.Height*percentage - barHeight*percentage), self.Width, barHeight, self.BarColour)
end

OnScroll = function(self, event, direction, x, y)
	if event == 'mouse_scroll' then
		direction = self.Bedrock.Helpers.Round(direction * 3)
	end
	if self.Scroll < 0 or self.Scroll > self.MaxScroll then
		return false
	end
	local old = self.Scroll
	self.Scroll = self.Bedrock.Helpers.Round(self.Scroll + direction)
	if self.Scroll < 0 then
		self.Scroll = 0
	elseif self.Scroll > self.MaxScroll then
		self.Scroll = self.MaxScroll
	end

	if self.Scroll ~= old and self.OnChange then
		self:OnChange()
	end
end

OnClick = function(self, event, side, x, y)
	if event == 'mouse_click' then
		self.ClickPoint = y
	else
		local gapHeight = self.Height - (self.Height * (self.Height / (self.Height + self.MaxScroll)))
		local barHeight = self.Height * (self.Height / (self.Height + self.MaxScroll))
		--local delta = (self.Height + self.MaxScroll) * ((y - self.ClickPoint) / barHeight)
		local delta = ((y - self.ClickPoint)/gapHeight)*self.MaxScroll
		--l(((y - self.ClickPoint)/gapHeight))
		--l(delta)
		self.Scroll = delta
		--l(self.Scroll)
		--l('----')
		if self.Scroll < 0 then
			self.Scroll = 0
		elseif self.Scroll > self.MaxScroll then
			self.Scroll = self.MaxScroll
		end
		if self.OnChange then
			self:OnChange()
		end
	end

	local relScroll = self.MaxScroll * ((y-1)/self.Height)
	if y == self.Height then
		relScroll = self.MaxScroll
	end
	self.Scroll = self.Bedrock.Helpers.Round(relScroll)


end

OnDrag = OnClick