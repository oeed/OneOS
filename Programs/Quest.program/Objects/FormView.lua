Inherit = 'View'

OnTab = function(self)
	local active = self.Bedrock:GetActiveObject()
	local selected = nil
	local selectNext = false
	local function node(tree)
		for i, v in ipairs(tree) do
			if selectNext then
				if v.Type == 'TextBox' or v.Type == 'SecureTextBox' then
					selected = v
					return
				end
			elseif v == active then
				selectNext = true
			end
			if v.Children then
				node(v.Children)
			end
		end
	end
	node(self.Children)

	if selected then
		self.Bedrock:SetActiveObject(selected)
	end
end