Inherit = 'View'

BackgroundColour = colours.transparent

OnLoad = function(self)
	self.Width = 10
	self.Height = 4
	local image = self:AddObject({
		Type = 'ImageView',
		X = 3,
		Y = 1,
		Width = 4,
		Height = 3,
		Image = OneOS.Helpers.IconForFile(self.Path),
		Name = 'ImageView'
	})

	local label = self:AddObject({
		Type = 'Label',
		X = 1,
		Y = 4,
		Width = 10,
		Text = self.Bedrock.Helpers.TruncateString(self.Bedrock.Helpers.RemoveExtension(fs.getName(self.Path)), 10),
		Align = 'Center',
		Name = 'Label'
	})

	local function click(_, event, side, x, y)
			print('hiiiiii')
			sleep(1)
		if side == 1 then
			OneOS.Helpers.OpenFile(self.Path)
		elseif side == 2 then

		end
	end

	label.OnClick = click
	image.OnClick = click
end