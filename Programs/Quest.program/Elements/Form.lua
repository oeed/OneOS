Submit = function(self, onEnter)
	local values = {}
	
	local node = false
	node = function(elem)
		if (elem.Tag == 'input' or elem.Tag == 'select') and elem.InputName then
			local findSubmit = (onEnter and elem.Attributes and elem.Attributes.type == 'submit')
			if elem.UpdateValue then
				elem:UpdateValue(findSubmit)
			end

			if findSubmit then
				onEnter = false
			end

			if elem.Value then
				values[elem.InputName] = elem.Value
			end
		end

		if elem.Children then
			for i, child in ipairs(elem.Children) do
				node(child)
			end
		end
	end

	node(self)

	local url = false
	if self.Attributes.action and #self.Attributes.action > 0 then
		url = resolveFullUrl(self.Attributes.action) --TODO: this needs to show the fake url to the user
	else
		url = getCurrentFakeUrl()
	end
	local data = ''
	for k, v in pairs(values) do
		data = data .. textutils.urlEncode(k) .. '=' .. textutils.urlEncode(v) .. '&'
	end
	data = data:sub(1, #data - 1)

	if self.Attributes.method and self.Attributes.method:lower() == 'post' then
		goToUrl(url, data)
	else
		goToUrl(url .. '?' .. data)
	end
end

OnCreateObject = function(self, parentObject, y)
	return {
		Element = self,
		Y = y,
		X = 1,
		Width = "100%",
		Height = self.Height,
		Type = "FormView"
	}
end