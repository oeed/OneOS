Inherit = 'View'

TextColour = colours.black
BackgroundColour = colours.white
HideTop = false

OnDraw = function(self, x, y)
	Drawing.DrawBlankArea(x + 1, y + (self.HideTop and 0 or 1), self.Width, self.Height + 1, colours.grey)
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
end

OnLoad = function(self)
	local owner = self.Owner
	if type(owner) == 'string' then
		owner = self.Bedrock:GetObject(self.Owner)
	end

	if owner then
		local pos = owner:GetPosition()
		self.X = pos.X
		self.Y = pos.Y + owner.Height
		self.Owner = owner
	else
		self.Owner = nil
	end
end

OnUpdate = function(self, value)
	if value == 'Children' then
		self.Width = Helpers.LongestString(self.Children, 'Text') + 2
		self.Height = #self.Children + 1 + (self.HideTop and 0 or 1)

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
			v.X = 1
			v.Y = i
			v.Width = self.Width
			v.Height = 1
		end
		return true
	end
end

Close = function(self, isBedrockCall)
	self.Bedrock.Menu = nil
	self.Bedrock:RemoveObject(self.Name)

	if self.Owner and self.Owner.Toggle then
		self.Owner.Toggle = false
		self.Owner:ForceDraw()
	end
	self = nil
end

OnClick = function(self, event, side, x, y)
	--TODO: check if it works with hidetop == true
	if self.Children[y - (self.HideTop and 0 or 1)] then
		self.Children[y - (self.HideTop and 0 or 1)]:Click()
		self:Close()
	end
end