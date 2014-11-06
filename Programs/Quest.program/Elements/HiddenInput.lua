InputName = ''

OnInitialise = function(self, node)
	local attr = self.Attributes
	if attr.value then
		self.Value = attr.value
	end

	if attr.name then
		self.InputName = attr.name
	end
end