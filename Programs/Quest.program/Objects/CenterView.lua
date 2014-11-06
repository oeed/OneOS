Inherit = 'View'

OnUpdate = function(self, value)
	if value == 'Children' or value == 'Width' then
		local y = 1
		for i, v in ipairs(self.Children) do
			v.Y = y
			y = y + v.Height
			v.X = math.floor((self.Width - v.Width) / 2) + 1
		end
		self.Height = y - 1
	end
end