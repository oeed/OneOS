Inherit = 'View'
BackgroundColour = colours.white
ToolBarColour = colours.grey
ToolBarTextColour = colours.white
ShadowColour = colours.grey
Title = ''
CanClose = true
DragX = nil
Z = 50

OnLoad = function(self)
	self:BringToFront()
	self:AddObject({
		X = 1, 
		Y = 1, 
		Width = 1, 
		Height = 1, 
		Type = 'Button', 
		BackgroundColour = colours.transparent,
		TextColour = colours.lightGrey, 
		Text = 'x', 
		Name = 'CloseButton', 
		OnClick = function(btn)
			if self.OnCloseButton then
				self:OnCloseButton()
			end
			self:Close()
		end
	})

	local view = self:AddObject({
		X = 1,
		Y = 2,
		InheritView = self.ContentViewName,
		Type = 'View',
		Name = 'ContentView'
	})

	if self.OnContentLoad then
		self:OnContentLoad()
	end
	
	self.Width = view.Width
	self.Height = view.Height + 1

	if self.Y + self.Height > Drawing.Screen.Height then
		self.Y = Drawing.Screen.Height - self.Height + 1
	end
end

OnWindowDrag = function(self, x, y)
	local old = self.Docked
	if x >= Drawing.Screen.Width - 2 then
		self.Docked = true
		self.Bedrock.DragWindow = nil
	else
		self.Docked = false
	end

	if old ~= self.Docked and self.OnDockChange then
		self:OnDockChange(self.Docked)
		if self.Y + self.Height > Drawing.Screen.Height then
			self.Y = Drawing.Screen.Height - self.Height + 1
		end
	end
end

OnDraw = function(self, x, y)
	Drawing.DrawBlankArea(x, y, self.Width, 1, self.ToolBarColour)
	local title = self.Bedrock.Helpers.TruncateString(self.Title, self.Width - 2)
	Drawing.DrawCharactersCenter(self.X, self.Y, self.Width, 1, title, self.ToolBarTextColour, self.ToolBarColour)
	Drawing.IgnoreConstraint = true
	Drawing.DrawBlankArea(x + 1, y + 1, self.Width, self.Height, self.ShadowColour)
	Drawing.IgnoreConstraint = false
end

BringToFront = function(self)
	for i = #self.Bedrock.View.Children, 1, -1 do
		local child = self.Bedrock.View.Children[i]

		if child.OnWindowDrag then
			self.Z = child.Z + 1
			break
		end
	end
	self.Bedrock:ReorderObjects()
end

Click = function(self, event, side, x, y, z)
	if self.Visible and not self.IgnoreClick then
		self:BringToFront()
		for i = #self.Children, 1, -1 do --children are ordered from smallest Z to highest, so this is done in reverse
			local child = self.Children[i]
			if self:DoClick(child, event, side, x, y) then
				if self.OnChildClick then
					self:OnChildClick(child, event, side, x, y)
				end
				return true
			end
		end
		if event == 'mouse_click' and self.OnClick and self:OnClick(event, side, x, y) ~= false then
			return true
		elseif event == 'mouse_drag' and self.OnDrag and self:OnDrag(event, side, x, y) ~= false then
			return true
		elseif event == 'mouse_scroll' and self.OnScroll and self:OnScroll(event, side, x, y) ~= false then
			return true
		else
			return false
		end
	else
		return false
	end
end

OnClick = function(self, event, side, x, y)
	if x ~= 1 and y == 1 then
		self.DragX = x
		self.Bedrock.DragWindow = self
		return true
	end
	return false
end

Close = function(self)
	self.Bedrock:RemoveObject(self)
	if self.OnClose then
		self:OnClose()
	end
end

OnUpdate = function(self, value)
	if value == 'Children' and self:GetObject('ContentView') then
		self.Width = self:GetObject('ContentView').Width
		self.Height = self:GetObject('ContentView').Height + 1
	end
end