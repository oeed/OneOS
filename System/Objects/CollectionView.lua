Inherit = 'ScrollView'
UpdateDrawBlacklist = {['NeedsItemUpdate']=true}

TextColour = colours.black
BackgroundColour = colours.white
Items = false
NeedsItemUpdate = false
SpacingX = 2
SpacingY = 1

OnDraw = function(self, x, y)
	if self.NeedsItemUpdate then
		self:UpdateItems()
		self.NeedsItemUpdate = false
	end
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
end

local function MaxIcons(self, obj)
	local x, y = 2, 1
	if not obj.Height or not obj.Width then
		error('You must provide each object\'s height when adding to a CollectionView.')
	end
	local slotHeight = obj.Height + self.SpacingY
	local slotWidth = obj.Width + self.SpacingX
	local maxX = math.floor((self.Width - 2) / slotWidth)
	return x, y, maxX, slotWidth, slotHeight
end

local function IconLocation(self, obj, i)
	local x, y, maxX, slotWidth, slotHeight = MaxIcons(self, obj)
	local rowPos = ((i - 1) % maxX)
	local colPos = math.ceil(i / maxX) - 1
	x = x + (slotWidth * rowPos)
	y = y + colPos * slotHeight
	return x, y
end

local function AddItem(self, v, i)
	local toggle = false
	if not self.CanSelect then
		toggle = nil
	end
	local x, y = IconLocation(self, v, i)
	local item = {
		["X"]=x,
		["Y"]=y,
		["Name"]="CollectionViewItem",
		["Type"]="View",
		["TextColour"]=self.TextColour,
		["BackgroundColour"]=-1,
		OnClick = function(itm)
			if self.CanSelect then
				for i2, _v in ipairs(self.Children) do
					_v.Toggle = false
				end
				self.Selected = itm
			end
		end
    }
	for k, _v in pairs(v) do
		item[k] = _v
   	end
	self:AddObject(item)
end


UpdateItems = function(self)
	self:RemoveAllObjects()
	local groupMode = false
	for k, v in pairs(self.Items) do
		if type(k) == 'string' then
			groupMode = true
			break
		end
	end

	for i, v in ipairs(self.Items) do
		AddItem(self, v, i)
	end
	self:UpdateScroll()
end

OnUpdate = function(self, value)
	if value == 'Items' then
		self.NeedsItemUpdate = true
	end
end