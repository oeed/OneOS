BackgroundColour = colours.transparent
Children = {}

OnDraw = function(self, x, y)
	if self.BackgroundColour then
		Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
	end
end

OnInitialise = function(self)
	self.Children = {}
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
	if object.X <= x and object.Y <= y and  object.X + object.Width > x and object.Y + object.Height > y then
		return true
	end
end

function DoClick(self, object, event, side, x, y)
	if object then
		if self:CheckClick(object, x, y) then
			return object:Click(event, side, x - object.X + 1, y - object.Y + 1)
		end
	end	
end

Click = function(self, event, side, x, y)
	if self.Visible then
		for i, child in ipairs(self.Children) do
			if self:DoClick(child, event, side, x, y) then
				child:ForceDraw()
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
		else
			return false
		end
	else
		return false
	end
end

OnRemove = function(self)
	if self == self.Bedrock:GetActiveObject() then
		self.Bedrock:SetActiveObject()
	else
		for i, child in ipairs(self.Children) do
			child:OnRemove()
		end
	end
end

local function findObjectNamed(view, name, minI)
	local minI = minI or 0
	if view and view.Children then
		for i, child in ipairs(view.Children) do
			if child.Name == name then
				return child, i, view
			elseif child.Children then
				local found, index, foundView = findObjectNamed(child, name)
				if found and minI <= index then
					return found, index, foundView
				end
			end
		end
	end
end

function AddObject(self, info, extra)
	if type(info) == 'string' then
		local h = fs.open(self.Bedrock.ViewPath..info..'.view', 'r')
		if h then
			info = textutils.unserialize(h.readAll())
			h.close()
		else
			error('Error in opening object: '..info)
		end
	end

	if extra then
		for k, v in pairs(extra) do
			if v then
				info[k] = v
			end
		end
	end

	local view = self.Bedrock:ObjectFromFile(info, self)
	if not view.Z then
		view.Z = #self.Children + 1
	end
	
	table.insert(self.Children, view)
	self.Bedrock:ReorderObjects()
	self:ForceDraw()
	return view
end

function GetObject(self, name)
	return findObjectNamed(self, name)
end

function GetObjects(self, name)
	local objects = {}
	local minI = 0
	while true do
		local obj, index = findObjectNamed(self, name, minI)
		if not obj then
			break
		end
		table.insert(objects, obj)
		minI = index
	end
	return objects
end

function RemoveObject(self, name)
	if type(name) == 'string' then
		local object, index = findObjectNamed(self, name)
		if index then
			self.Children[index]:OnRemove()
			table.remove(self.Children, index)
			self:ForceDraw()
			return true
		else
			return false
		end
	else
		local found = false
		for i, child in ipairs(self.Children) do
			if name == child then
				child:OnRemove()
				table.remove(self.Children, i)
				found = true
			end
		end

		if found then
			self:ForceDraw()
			return true
		else
			return false
		end
	end
end

function RemoveObjects(self, name)
	while true do
		local obj, index = findObjectNamed(self, name)
		if not obj then
			break
		end
		self.Children[index]:OnRemove()
		table.remove(self.Children, index)
	end
		self:ForceDraw()
	
end