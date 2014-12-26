FilterName = nil
TextFilterName = nil

OnLoad = function(self)
	self:OnUpdate('FilterName')
end

OnUpdate = function(self, value)
	if value == 'FilterName' then
		Log.i('filterup')
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