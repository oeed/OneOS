Inherit = 'View'

BackgroundColour = colours.transparent
Path = ''

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

	local function click(obj, event, side, x, y)
		if side == 1 then
			OneOS.Helpers.OpenFile(self.Path)
		elseif side == 2 then
			--TODO: menu
			if obj:ToggleMenu('filemenu', x, y) then
				self.Bedrock:GetObject('OpenMenuItem').OnClick = function(itm)
					OneOS.Helpers.OpenFile(self.Path)
				end

				self.Bedrock:GetObject('RenameMenuItem').OnClick = function(itm)
					OneOS.Helpers.RenameFile(self.Path, ReloadFiles, self.Bedrock)
				end

				self.Bedrock:GetObject('DeleteMenuItem').OnClick = function(itm)
					OneOS.Helpers.DeleteFile(self.Path, ReloadFiles, self.Bedrock)
				end

				self.Bedrock:GetObject('NewFolderMenuItem').OnClick = function(itm)
					OneOS.Helpers.NewFolder('/Desktop/', ReloadFiles, self.Bedrock)
				end

				self.Bedrock:GetObject('NewFileMenuItem').OnClick = function(itm)
					OneOS.Helpers.NewFile('/Desktop/', ReloadFiles, self.Bedrock)
				end

				self.Bedrock:GetObject('RefreshMenuItem').OnClick = function(itm)
					ReloadFiles()
				end
			end
		end
	end

	label.OnClick = click
	image.OnClick = click

end