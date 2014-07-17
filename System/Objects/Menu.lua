Inherit = 'View'

TextColour = colours.black
BackgroundColour = colours.white
HideTop = false

OnDraw = function(self, x, y)
	Drawing.IgnoreConstraint = true
	Drawing.DrawBlankArea(x + 1, y + (self.HideTop and 0 or 1), self.Width, self.Height + (self.HideTop and 1 or 0), colours.grey)
	Drawing.IgnoreConstraint = false
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
end

OnLoad = function(self)
	local owner = self.Owner
	if type(owner) == 'string' then
		owner = self.Bedrock:GetObject(self.Owner)
	end

	if owner then
		if self.X == 0 and self.Y == 0 then
			local pos = owner:GetPosition()
			self.X = pos.X
			self.Y = pos.Y + owner.Height
		end
		self.Owner = owner
	else
		self.Owner = nil
	end
end

OnUpdate = function(self, value)
	if value == 'Children' then
		self.Width = self.Bedrock.Helpers.LongestString(self.Children, 'Text') + 2
		self.Height = #self.Children + 1 + (self.HideTop and 0 or 1)
		if not self.BaseY then
			self.BaseY = self.Y
		end

		for i, v in ipairs(self.Children) do
			if v.TextColour then
				v.TextColour = self.TextColour
			end
			if v.BackgroundColour then
				v.BackgroundColour = colours.transparent
			end
			if v.Colour then
				v.Colour = colours.lightGrey
			end
			v.Align = 'Left'
			v.X = 1
			v.Y = i + (self.HideTop and 0 or 1)
			v.Width = self.Width
			v.Height = 1
		end

		self.Y = self.BaseY
		local pos = self:GetPosition()
		if pos.Y + self.Height + 1 > Drawing.Screen.Height then
			self.Y = self.BaseY - ((self.Height +  pos.Y) - Drawing.Screen.Height)
		end
		
		if pos.X + self.Width > Drawing.Screen.Width then
			self.X = Drawing.Screen.Width - self.Width
		end
	end
end

Close = function(self, isBedrockCall)
	self.Bedrock.Menu = nil
	self.Parent:RemoveObject(self)
	if self.Owner and self.Owner.Toggle then
		self.Owner.Toggle = false
	end
	self.Parent:ForceDraw()
	self = nil
end

OnChildClick = function(self, child, event, side, x, y)
	self:Close()
end