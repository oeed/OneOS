Inherit = 'View'
FilterName = nil
TextFilterName = nil

OnLoad = function(self)
	self:OnUpdate('FilterName')
end

OnUpdate = function(self, value)
	if value == 'FilterName' then
		self.Filter = Drawing.Filters[self.FilterName or 'None']
	elseif value == 'TextFilter' then
		self.TextFilter = Drawing.Filters[self.TextFilterName]
	end
end

OnDraw = function(self, x, y)
	local filter = self.Filter
	local textFilter = self.TextFilter or filter
	for _x = 1, self.Width do
		for _y = 1, self.Height do
			if Drawing.Buffer[y + _y - 1] and Drawing.Buffer[y + _y - 1][x + _x - 1] then
				local px = Drawing.Buffer[y + _y - 1][x + _x - 1]
				Drawing.WriteToBuffer(x + _x - 1, y + _y - 1, px[1], Drawing.FilterColour(px[2], filter), Drawing.FilterColour(px[3], textFilter))
			end
		end
	end
end

Blah = function(self, event, side, x, y, z)
		OneOS.Log.i('clikging')
	if self.Visible and not self.IgnoreClick then
		for i = #self.Children, 1, -1 do --children are ordered from smallest Z to highest, so this is done in reverse
			local child = self.Children[i]
			OneOS.Log.i(child.Name .. ' ' .. self:CheckClick(child, x, y))
			if self:DoClick(child, event, side, x, y) then
				if self.OnChildClick then
					self:OnChildClick(child, event, side, x, y)
				end
				return true
			end
		end
		if event == 'mouse_click' and self.OnClick and self:OnClick(event, side, x, y) ~= false then
			return true
		elseif event == 'mouse_drag' and self.OnDrag and self:OnDrag(event, side, x, y) ~= false then
			return true
		elseif event == 'mouse_scroll' and self.OnScroll and self:OnScroll(event, side, x, y) ~= false then
			return true
		else
			return false
		end
	else
		return false
	end
end
