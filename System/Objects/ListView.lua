Inherit = 'ScrollView'
UpdateDrawBlacklist = {['NeedsItemUpdate']=true}

TextColour = colours.black
BackgroundColour = colours.white
HeadingColour = colours.lightGrey
SelectionBackgroundColour = colours.blue
SelectionTextColour = colours.white
Items = false
CanSelect = false
Selected = nil
NeedsItemUpdate = false
ItemMargin = 1
HeadingMargin = 0
TopMargin = 0

OnDraw = function(self, x, y)
	if self.NeedsItemUpdate then
		self:UpdateItems()
	end
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
end

local function AddItem(self, v, x, y, group)
	local toggle = false
	if not self.CanSelect then
		toggle = nil
	elseif v.Selected then
		toggle = true
	end
	local item = {
		["Width"]=self.Width,
		["X"]=x,
		["Y"]=y,
		["Name"]="ListViewItem",
		["Type"]="Button",
		["TextColour"]=self.TextColour,
		["BackgroundColour"]=-1,
		["ActiveTextColour"]=self.SelectionTextColour,
		["ActiveBackgroundColour"]=self.SelectionBackgroundColour,
		["Align"]='Left',
		["Toggle"]=toggle,
		["Group"]=group,
		OnClick = function(itm)
			if self.CanSelect then
				for i2, _v in ipairs(self.Children) do
					_v.Toggle = false
				end
				self.Selected = itm
			end
		end
    }
    if type(v) == 'table' then
    	for k, _v in pairs(v) do
    		item[k] = _v
    	end
    else
		item.Text = v
    end
	
	local itm = self:AddObject(item)
	if v.Selected then
		self.Selected = itm
	end
end

UpdateItems = function(self)
	if not self.Items or type(self.Items) ~= 'table' then
		self.Items = {}
	end
	self.Selected = nil
	self:RemoveAllObjects()
	local groupMode = false
	for k, v in pairs(self.Items) do
		if type(k) == 'string' then
			groupMode = true
			break
		end
	end

	if not groupMode then
		for i, v in ipairs(self.Items) do
			AddItem(self, v, self.ItemMargin, i)
		end
	else
		local y = self.TopMargin
		for k, v in pairs(self.Items) do
			y = y + 1
			AddItem(self, {Text = k, TextColour = self.HeadingColour, IgnoreClick = true}, self.HeadingMargin, y)
			for i, _v in ipairs(v) do
				y = y + 1
				AddItem(self, _v, 1, y, k)
			end
			y = y + 1
		end
	end
	self:UpdateScroll()
	self.NeedsItemUpdate = false
end

OnKeyChar = function(self, event, keychar)
	if keychar == keys.up or keychar == keys.down then
		local n = self:GetIndex(self.Selected)
		if keychar == keys.up then
			n = n - 1
		else
			n = n + 1
		end
		local new = self:GetNth(n)
		if new then
			self:SelectItem(new)
		end
	elseif keychar == keys.enter and self.Selected then
		self.Selected:Click('mouse_click', 1, 1, 1)
	end
end

--returns the index/'n' of the given item
GetIndex = function(self, obj)
	local n = 1
	for i, v in ipairs(self.Children) do
		if not v.IgnoreClick then
			if obj == v then
				return n
			end
			n = n + 1
		end
	end
end

--gets the 'nth' list item (does not include headings)
GetNth = function(self, n)
	local _n = 1
	for i, v in ipairs(self.Children) do
		if not v.IgnoreClick then
			if n == _n then
				return v
			end
			_n = _n + 1
		end
	end
end

SelectItem = function(self, item)
	for i, v in ipairs(self.Children) do
		v.Toggle = false
	end
	self.Selected = item
	item.Toggle = true
end

OnUpdate = function(self, value)
	if value == 'Items' then
		self.NeedsItemUpdate = true
	end
end