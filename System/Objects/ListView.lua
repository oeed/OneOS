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

OnDraw = function(self, x, y)
	if self.NeedsItemUpdate then
		self:UpdateItems()
		self.NeedsItemUpdate = false
	end
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
end

local function AddItem(self, v, x, y, group)
	local toggle = false
	if not self.CanSelect then
		toggle = nil
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

	if not groupMode then
		for i, v in ipairs(self.Items) do
			AddItem(self, v, 1, i)
		end
	else
		local y = 1
		for k, v in pairs(self.Items) do
			y = y + 1
			AddItem(self, {Text = k, TextColour = self.HeadingColour, IgnoreClick = true}, 0, y)
			for i, _v in ipairs(v) do
				y = y + 1
				AddItem(self, _v, 1, y, k)
			end
			y = y + 1
		end
	end
	self:UpdateScroll()
end

OnUpdate = function(self, value)
	if value == 'Items' then
		self.NeedsItemUpdate = true
	end
end