	X = 1
	Y = 1
	Width = 0
	Height = 0
	BackgroundColour = colours.white
	Children = {}
	Parent = nil
	Name = nil

	Draw = function(self)
		local pos = self.Bedrock:GetAbsolutePosition(self)
		Drawing.DrawBlankArea(pos.X, pos.Y, self.Width, self.Height, self.BackgroundColour)

		for i, child in ipairs(self.Children) do
			child:Draw()
		end
	end

	Initialise = function(self, x, y, width, height, backgroundColour, name, children)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		new.Width = width
		new.Height = height
		new.Y = y
		new.X = x
		new.BackgroundColour = backgroundColour
		new.Name = name
		new.Children = children
		return new
	end

	InitialiseFile = function(self, bedrock, file, name)
		local new = self:Initialise(1, 1, Drawing.Screen.Width, Drawing.Screen.Height, file.BackgroundColour, name, {})
		new.Bedrock = bedrock
		for i, obj in ipairs(file.Children) do
			local view = bedrock:ObjectFromFile(obj, new)
			if not view.Z then
				view.Z = i
			end

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

	function DoClick(self, event, object, side, x, y)
		if object and self:CheckClick(object, x, y) then
			return object:Click(event, side, x - object.X + 1, y - object.Y + 1)
		end	
	end

	Click = function(self, event, side, x, y)
		for i, child in ipairs(self.Children) do
			if self:DoClick(event, child, side, x, y) then
				return true
			end		
		end
	end