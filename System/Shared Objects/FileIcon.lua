Inherit = 'View'
Width = 10
Height = 4
Selected = false
ShowExtension = false
ClickCount = 0
ClickResetTimer = nil

OnLoad = function(self)
	self:AddObject({
		X = '50%,-1',
		Y = 1,
		Width = 4,
		Height = 3,
		Type = 'ImageView',
		Image = OneOS.GetIcon(self.Path),
		OnClick = function(_, event, side, x, y) self:OnClick(event, side, x, y, _) end
	})
	
	local fileName = fs.getName(self.Path)
	if not self.ShowExtension and fileName:sub(1,1) ~= '.' then
		fileName = self.Bedrock.Helpers.RemoveExtension(fileName)
	end

	self:AddObject({
		X = 1,
		Y = '100%,0',
		Width = '100%',
		Align = 'Center',
		Type = 'Label',
		Name = 'NameLabel',
		Text = fileName,
		Wrap = false,
		OnClick = function(_, event, side, x, y) self:OnClick(event, side, x, y, _) end
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

	self:OnUpdate('Selected')
end


OnUpdate = function(self, value)
	if value == 'Selected' then
		local label = self:GetObject('NameLabel')
		if label then
			label.BackgroundColour = (self.Selected and colours.blue or colours.transparent)
			label.TextColour = (self.Selected and colours.white or colours.black)
		end
	end
end

OnClick = function(self, event, side, x, y, _)
	if not _ then return end
	
	if side == 1 then
		self.ClickCount = self.ClickCount + 1

		if self.ClickCount >= 3 then
			self.Selected = false
			self.ClickCount = 0
		else
			OneOS.Log.i('Hi')
			OneOS.Log.i(_)
			self.DragX = _.X + x - 2
			self.DragY = _.Y + y - 2
			self.Bedrock.DragIcon = self
			if self.Selected then
				OneOS.OpenFile(self.Path, nil, self.X, self.Y)
			else
				self.Selected = not self.Selected
			end
		end
	elseif side == 2 then
		self:ToggleMenu('filemenu', x, y)
	end
end

OnIconDrag = function(self, x, y)
	self.Selected = false
end