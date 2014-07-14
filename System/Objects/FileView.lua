Inherit = 'View'

BackgroundColour = colours.transparent
Path = ''
Width = 10
Height = 4

OnLoad = function(self)
	self.Width = 10
	self.Height = 4
	local image = self:AddObject({
		Type = 'ImageView',
		X = 4,
		Y = 1,
		Width = 4,
		Height = 3,
		Image = OneOS.Helpers.IconForFile(self.Path),
		Name = 'ImageView'..fs.getName(self.Path)
	})
	local label = self:AddObject({
		Type = 'Label',
		X = 1,
		Y = 4,
		Width = 10,
		Text = self.Bedrock.Helpers.TruncateString(self.Bedrock.Helpers.RemoveExtension(fs.getName(self.Path)), 10),
		Align = 'Center',
		Name = 'Label'..fs.getName(self.Path)
	})

	if self.Bedrock.Helpers.Extension(self.Path) == 'shortcut' then
		self:AddObject({
			Type = 'Label',
			X = 7,
			Y = 3,
			Width = 1,
			Text = '>',
			BackgroundColour=colours.white,
			Name = 'ShortcutLabel'
		})
	end
	local click = function(obj, event, side, x, y) self:OnClick(event, side, x, y, obj) end

	label.OnClick = click
	image.OnClick = click

end