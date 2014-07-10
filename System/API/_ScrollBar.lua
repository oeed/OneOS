X = 1
Y = 1
Width = 1
Height = 1
BackgroundColour = colours.grey
BarColour = colours.lightBlue
Parent = nil
Change = nil
Scroll = 0
MaxScroll = 0
ClickPoint = nil

local round = function(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

Register = function(self)
	RegisterElement(self)
	return self
end

Draw = function(self)
	if self.MaxScroll == 0 then
		return
	end
	local pos = GetAbsolutePosition(self)
    local barHeight = self.Height - self.MaxScroll
    if barHeight < 3 then
      barHeight = 3
    end
    local percentage = (self.Scroll/self.MaxScroll)

    Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, self.BackgroundColour)
    Drawing.DrawBlankArea(pos.X, pos.Y + round(self.Height*percentage - barHeight*percentage), self.Width, barHeight, self.BarColour)
end

Initialise = function(self, x, y, height, maxScroll, backgroundColour, barColour, parent, change)
	local new = {}    -- the new instance
	setmetatable( new, {__index = self} )
	new.Width = 1
	new.Height = height
	new.Y = y
	new.X = x
	new.BackgroundColour = backgroundColour or colours.grey
	new.BarColour = barColour or colours.lightBlue
	new.Parent = parent
	new.Change = change or function()end
	new.MaxScroll = maxScroll
	new.Scroll = 0
	return new
end

DoScroll = function(self, amount)
	term.setTextColour(colours.black)
	amount = round(amount)
	if self.Scroll < 0 or self.Scroll > self.MaxScroll then
		return false
	end
	self.Scroll = self.Scroll + amount
	if self.Scroll < 0 then
		self.Scroll = 0
	elseif self.Scroll > self.MaxScroll then
		self.Scroll = self.MaxScroll
	end
	self.Change()
	return true
end

Click = function(self, side, x, y, drag)
	local percentage = (self.Scroll/self.MaxScroll)
	local barHeight = (self.Height - self.MaxScroll)
	if barHeight < 3 then
		barHeight = 3
	end
	local relScroll = (self.MaxScroll*(y + barHeight*percentage)/self.Height)
	if not drag then
		self.ClickPoint = self.Scroll - relScroll + 1
	end

	if self.Scroll-1 ~= relScroll then
		self:DoScroll(relScroll-self.Scroll-1 + self.ClickPoint)
	end
	return true
end