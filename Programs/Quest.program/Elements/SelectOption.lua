Value = nil

OnInitialise = function(self, node)
	if attr.value then
		new.Value = attr.value
	end
end

OnCreateObject = function(self, parentObject, y)
	if parentObject.AddMenuItem then
		parentObject:AddMenuItem({
			Value = self.Value,
			Text = self.Text,
			Type = "Button"
		})
	end
end