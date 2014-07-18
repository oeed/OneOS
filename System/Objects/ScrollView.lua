Inherit = 'View'
ChildOffset = false
ContentWidth = 0
ContentHeight = 0

CalculateContentSize = function(self)
	local function calculateObject(obj)
		local pos = obj:GetPosition()
		local x2 = pos.X + obj.Width - 1
		local y2 = pos.Y + obj.Height - 1
		if obj.Children then
			for i, child in ipairs(obj.Children) do
				local _x2, _y2 = calculateObject(child)
				if _x2 > x2 then
					x2 = _x2
				end
				if _y2 > y2 then
					y2 = _y2
				end
			end
		end
		return x2, y2
	end

	local pos = self:GetPosition()
	local x2, y2 = calculateObject(self)
	self.ContentWidth = x2 - pos.X + 1
	self.ContentHeight = y2 - pos.Y + 1
end

UpdateScroll = function(self)
	self.ChildOffset.Y = 0
	self:CalculateContentSize()
	if self.ContentHeight > self.Height then
		if not self:GetObject('ScrollViewScrollBar') then
			local _scrollBar = self:AddObject({
				["Name"] = 'ScrollViewScrollBar',
				["Type"] = 'ScrollBar',
				["X"] = self.Width,
				["Y"] = 1,
				["Width"] = 1,
				["Height"] = self.Height,
				["Z"]=999
			})

			_scrollBar.OnChange = function(scrollBar)
				self.ChildOffset.Y = -scrollBar.Scroll
				for i, child in ipairs(self.Children) do
					child:ForceDraw()
				end
			end
		end
		self:GetObject('ScrollViewScrollBar').MaxScroll = self.ContentHeight - self.Height
	else
		self:RemoveObject('ScrollViewScrollBar')
	end
end

OnScroll = function(self, event, direction, x, y)
	if self:GetObject('ScrollViewScrollBar') then
		self:GetObject('ScrollViewScrollBar'):OnScroll(event, direction, x, y)
	end
end

OnLoad = function(self)
	if not self.ChildOffset or not self.ChildOffset.X or not self.ChildOffset.Y then
		self.ChildOffset = {X = 0, Y = 0}
	end
end