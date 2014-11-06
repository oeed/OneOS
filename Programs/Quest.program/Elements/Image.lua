URL = nil
Format = nil

OnInitialise = function(self, node)
	local attr = self.Attributes
	if attr.src then
		self.URL = attr.src
	end

	if attr.type then
		self.Format = attr.type
	end

	if attr.height then
		self.Height = attr.height
	end

	if attr.width then
		self.Width = attr.width
	end
end

OnCreateObject = function(self, parentObject, y)
	return {
		Element = self,
		Y = y,
		X = 1,
		Width = self.Width,
		Height = self.Height,
		URL = self.URL,
		Format = self.Format,
		Type = "WebImageView"
	}
end