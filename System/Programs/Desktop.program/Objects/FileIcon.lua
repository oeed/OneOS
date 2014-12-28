Inherit = 'View'
Width = 10
Height = 4
Selected = false

OnLoad = function(self)
	self:AddObject({
		X = '50%,-1',
		Y = 1,
		Width = 4,
		Height = 3,
		Type = 'ImageView',
		Image = OneOS.GetIcon(self.Path)
	})

	self:AddObject({
		X = 1,
		Y = '100%,0',
		Width = '100%',
		Align = 'Center',
		Type = 'Label',
		Name = 'NameLabel',
		Text = fs.getName(self.Bedrock.Helpers.RemoveExtension(self.Path))
	})

	if self.Bedrock.Helpers.Extension(self.Path) == 'shortcut' then
		self:AddObject({
			Type = 'Label',
			X = '50%,2',
			Y = 3,
			Text = '>',
			BackgroundColour =colours.white
		})
	end
end

OnClick = function(self, event, side, x, y)
	if side == 1 then
		if self.Selected then
			OneOS.OpenFile(self.Path)
		else
			self.Selected = not self.Selected
		end
	elseif side == 2 then
		self:ToggleMenu('filemenu', x, y)
	end
end