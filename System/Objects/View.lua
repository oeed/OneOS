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
	local _new = {}
	_new.X = 1
	_new.Y = 1
	_new.Width = Drawing.Screen.Width
	_new.Height = Drawing.Screen.Height
	_new.BackgroundColour = file.BackgroundColour
	_new.Name = name
	_new.Children = {}
	_new.Bedrock = bedrock
	local new = self:Initialise(_new)
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
	local offset = {X = 0, Y = 0}
	if not object.Fixed and self.ChildOffset then
		offset = self.ChildOffset
	end
	if object.X + offset.X <= x and object.Y + offset.Y <= y and  object.X + offset.X + object.Width > x and object.Y + offset.Y + object.Height > y then
		return true
	end
end

function DoClick(self, object, event, side, x, y)
	if object then
		if self:CheckClick(object, x, y) then
			local offset = {X = 0, Y = 0}
			if not object.Fixed and self.ChildOffset then
				offset = self.ChildOffset
			end
			return object:Click(event, side, x - object.X - offset.X + 1, y - object.Y + 1 - offset.Y)
		end
	end	
end

Click = function(self, event, side, x, y, z)
	if self.Visible and not self.IgnoreClick then
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

OnRemove = function(self)
	if self == self.Bedrock:GetActiveObject() then
		self.Bedrock:SetActiveObject()
	end
	for i, child in ipairs(self.Children) do
		child:OnRemove()
	end
end

local function findObjectNamed(view, name, minI)
	local minI = minI or 0
	if view and view.Children then
		for i, child in ipairs(view.Children) do
			if child.Name == name or child == name then
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
	if self.Bedrock.View then
		self.Bedrock:ReorderObjects()
	end
	self:ForceDraw()
	return view
end

function GetObject(self, name)
	return findObjectNamed(self, name)
end

local function findObjects(view, name)
	local objects = {}
	if view and view.Children then
		for i, child in ipairs(view.Children) do
			if child.Name == name or child == name then
				table.insert(objects, child)
			elseif child.Children then
				local objs = findObjects(child, name)
				if objs then
					for i2, v in ipairs(objs) do
						table.insert(objects, v)
					end
				end
			end
		end
	end
	return objects
end

function GetObjects(self, name)
	return findObjects(self, name)
end

function RemoveObject(self, name)
	local obj, index, view = findObjectNamed(self, name, minI)
	if index then
		view.Children[index]:OnRemove()
		table.remove(view.Children, index)
		if view.OnUpdate then
			view:OnUpdate('Children')
		end
		return true
	end
	return false
end

function RemoveObjects(self, name)
	local i = 1
	while self:RemoveObject(name) and i < 100 do
		i = i + 1
	end
	
end

function RemoveAllObjects(self)
	for i, child in ipairs(self.Children) do
		child:OnRemove()
		self.Children[i] = nil
	end
	self:ForceDraw()
end