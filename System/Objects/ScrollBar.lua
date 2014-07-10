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
    local barHeight = self.Height - self.MaxScroll
    if barHeight < 3 then
      barHeight = 3
    end
    local percentage = (self.Scroll/self.MaxScroll)

    Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
    Drawing.DrawBlankArea(x, y + self.Bedrock.Helpers.Round(self.Height*percentage - barHeight*percentage), self.Width, barHeight, self.BarColour)
end

OnScroll = function(self, event, direction, x, y)
	direction = self.Bedrock.Helpers.Round(direction * 3)
	if self.Scroll < 0 or self.Scroll > self.MaxScroll then
		return false
	end
	self.Scroll = self.Scroll + direction
	if self.Scroll < 0 then
		self.Scroll = 0
	elseif self.Scroll > self.MaxScroll then
		self.Scroll = self.MaxScroll
	end

	if self.OnChange then
		self:OnChange()
	end
end

OnClick = function(self, event, side, x, y)
	local percentage = (self.Scroll/self.MaxScroll)
	local barHeight = (self.Height - self.MaxScroll)
	if barHeight < 3 then
		barHeight = 3
	end
	local relScroll = (self.MaxScroll*(y + barHeight*percentage)/self.Height)
	if event == 'mouse_click' then
		self.ClickPoint = self.Scroll - relScroll + 1
	end

	if self.Scroll-1 ~= relScroll then
		self:OnScroll('mouse_scroll', (relScroll-self.Scroll-1 + self.ClickPoint)/3)
	end
end

OnDrag = OnClick