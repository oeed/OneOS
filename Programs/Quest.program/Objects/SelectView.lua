Inherit = 'Button'
MenuItems = nil
Children = {}
Selected = nil

OnUpdate = function(self, value)
	if value == 'Height' and self.Height ~= 1 then
		self.Height = 1
	end
end

Select = function(self, index)
	if self.MenuItems[index] then
		local text = self.MenuItems[index].Text
		for i = 1, self.Width - 3 - #text do
			text = text .. ' '
		end
		text = text .. 'V'
		self.Text = text
		self.Selected = index
	end
end

OnInitialise = function(self)
	self:ClearMenuItems()
end

ClearMenuItems = function(self)
	self.MenuItems = {}
end

AddMenuItem = function(self, item)
	table.insert(self.MenuItems, item)
	if not self.Selected then
		if #self.MenuItems ~= 0 then
			self:Select(1)
		end
	end
end

OnClick = function(self, event, side, x, y)
	if self:ToggleMenu({
		Type = "Menu",
		HideTop = true,
		Children = self.MenuItems
	}, x, 1) then
		for i, child in ipairs(self.Bedrock.Menu.Children) do
			child.OnClick = function(_self, event, side, x, y)
				self:Select(i)
			end
		end
	end
end