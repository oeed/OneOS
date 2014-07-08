Inherit = 'View'

ToolBarColour = colours.lightGrey
ToolBarTextColour = colours.black
ShadowColour = colours.grey
Title = ''
Flashing = false
CanClose = true
OnCloseButton = nil

OnLoad = function(self)
	--self:GetObject('View') = self.Bedrock:ObjectFromFile({Type = 'View',Width = 10, Height = 5, BackgroundColour = colours.red}, self)
end

LoadView = function(self)
	local view = self:GetObject('View')
	if view.ToolBarColour then
		window.ToolBarColour = view.ToolBarColour
	end
	if view.ToolBarTextColour then
		window.ToolBarTextColour = view.ToolBarTextColour
	end
	view.X = 1
	view.Y = 2

	view:ForceDraw()
	self:OnUpdate('View')
	if self.OnViewLoad then
		self.OnViewLoad(view)
	end
	self.Bedrock:SetActiveObject(view)
end

SetView = function(self, view)
	self:RemoveObject('View')
	table.insert(self.Children, view)
	view.Parent = self
	self:LoadView()
end

Flash = function(self)
	self.Flashing = true
	self:ForceDraw()
	self.Bedrock:StartTimer(function()self.Flashing = false end, 0.4)
end

OnDraw = function(self, x, y)
	local toolBarColour = (self.Flashing and colours.white or self.ToolBarColour)
	local toolBarTextColour = (self.Flashing and colours.black or self.ToolBarTextColour)
	if toolBarColour then
		Drawing.DrawBlankArea(x, y, self.Width, 1, toolBarColour)
	end
	if toolBarTextColour then
		local title = self.Bedrock.Helpers.TruncateString(self.Title, self.Width - 2)
		Drawing.DrawCharactersCenter(self.X, self.Y, self.Width, 1, title, toolBarTextColour, toolBarColour)
	end
	Drawing.IgnoreConstraint = true
	Drawing.DrawBlankArea(x + 1, y + 1, self.Width, self.Height, self.ShadowColour)
	Drawing.IgnoreConstraint = false
end

Close = function(self)
	self.Bedrock.Window = nil
	self.Bedrock:RemoveObject(self)
	if self.OnClose then
		self:OnClose()
	end
	self = nil
end

OnUpdate = function(self, value)
	if value == 'View' and self:GetObject('View') then
		self.Width = self:GetObject('View').Width
		self.Height = self:GetObject('View').Height + 1
		self.X = math.ceil((Drawing.Screen.Width - self.Width) / 2)
		self.Y = math.ceil((Drawing.Screen.Height - self.Height) / 2)
	elseif value == 'CanClose' then
		self:RemoveObject('CloseButton')
		if self.CanClose then
			local button = self:AddObject({X = 1, Y = 1, Width = 1, Height = 1, Type = 'Button', BackgroundColour = colours.red, TextColour = colours.white, Text = 'x', Name = 'CloseButton'})
			button.OnClick = function(btn)
				if self.OnCloseButton then
					self:OnCloseButton()
				end
				self:Close()
			end
		end
	end
end