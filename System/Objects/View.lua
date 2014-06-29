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
			child:ForceDraw()
			return
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
			error('Error is opening object: '..info)
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
	view.Parent = self
	table.insert(self.Children, view)
	self.Bedrock:ReorderObjects()
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
	local object, index = findObjectNamed(self, name)
	table.remove(self.Children, index)
end

function RemoveObjects(self, name)
	while true do
		local obj, index = findObjectNamed(self, name)
		if not obj then
			break
		end
		table.remove(self.Children, index)
	end
end