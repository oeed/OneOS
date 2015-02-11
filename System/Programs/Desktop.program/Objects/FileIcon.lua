Inherit = 'View'
Width = 10
Height = 4
Selected = false

OnLoad = function(self)
	local click = function(_, event, side, x, y)
		if side == 1 then
			self.DragX = _.X + x  - 2
			self.DragY = _.Y + y - 2
			self.Bedrock.DragIcon = self
			if self.Selected then
				OneOS.OpenFile(self.Path, nil, self.X, self.Y)
			else
				self.Selected = not self.Selected
			end
		elseif side == 2 then
			self:ToggleMenu('filemenu', x, y)
		end
	end
	self:AddObject({
		X = '50%,-1',
		Y = 1,
		Width = 4,
		Height = 3,
		Type = 'ImageView',
		Image = OneOS.GetIcon(self.Path),
		OnClick = click
	})
	OneOS.Log.i(self.Bedrock.Helpers.RemoveExtension(self.Path))
	self:AddObject({
		X = 1,
		Y = '100%,0',
		Width = '100%',
		Align = 'Center',
		Type = 'Label',
		Name = 'NameLabel',
		Text = fs.getName(self.Bedrock.Helpers.RemoveExtension(self.Path)),
		OnClick = click
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

OnIconDrag = function(self, x, y)
	self.Selected = false
end