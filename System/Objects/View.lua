BackgroundColour = nil
Children = {}

OnDraw = function(self, x, y)
	if self.BackgroundColour then
		Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
	end
end

InitialiseFile = function(self, bedrock, file, name)
	local new = self:Initialise()
	new.X = 1
	new.Y = 1
	new.Width = Drawing.Screen.Width
	new.Height = Drawing.Screen.Height
	new.BackgroundColour = file.BackgroundColour
	new.Name = name
	new.Children = {}
	new.Bedrock = bedrock
	for i, obj in ipairs(file.Children) do
		local view = bedrock:ObjectFromFile(obj, new)
		if not view.Z then
			view.Z = i
		end
		view.Parent = new
		table.insert(new.Children, view)
	end
	return new
end

function CheckClick(self, object, x, y)
	local pos = self.Bedrock:GetAbsolutePosition(object)
	if pos.X <= x and pos.Y <= y and  pos.X + object.Width > x and pos.Y + object.Height > y then
		return true
	end
end

function DoClick(self, object, event, side, x, y)
	if object and self:CheckClick(object, x, y) then
		return object:Click(event, side, x - object.X + 1, y - object.Y + 1)
	end	
end

OnClick = function(self, event, side, x, y)
	for i, child in ipairs(self.Children) do
		if self:DoClick(child, event, side, x, y) then
			return
		end
	end
end