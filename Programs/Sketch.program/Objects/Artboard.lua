Inherit = 'View'
X = 2
Y = 3
Tool = nil
BrushSize = 1
BrushColour = nil
SecondaryBrushColour = nil
BrushShape = 'Circle'
CorrectPixelRatio = false

DragStart = nil
DragTimer = nil
Zoom = 1
CurrentLayer = nil
ShowFilterMasks = false
History = {}
HistoryPosition = 0
SavedState = nil
PushStateDelay = nil
Selection = {}
SelectionIsBlack = false
SelectionTimer = nil
UpdateDrawBlacklist = {['SelectionTimer']=true}

OnDraw = function(self, x, y)
	Drawing.IgnoreConstraint = true
	Drawing.DrawBlankArea(x + 1, y + 1, self.Width, self.Height, colours.grey)
	Drawing.IgnoreConstraint = false
	
	for _x = 1, self.Width do
		local odd = (_x % 2) == 1
		for _y = 1, self.Height do
			if odd then
				Drawing.WriteToBuffer(x + _x - 1, y + _y - 1, ":", colours.lightGrey, colours.white)
			else
				Drawing.WriteToBuffer(x + _x - 1, y + _y - 1, ":", colours.white, colours.lightGrey)
			end
			odd = not odd
		end
	end
end

OnPostChildrenDraw = function(self, x, y)
	if self.Selection and self.Selection[1] and self.Selection[2] then
		local point1 = {
			X = self.Selection[1].X * self.Zoom,
			Y = self.Selection[1].Y * self.Zoom
		}
		local point2 = {
			X = self.Selection[2].X * self.Zoom,
			Y = self.Selection[2].Y * self.Zoom
		}

		local size = {
			X = point2.X - point1.X,
			Y = point2.Y - point1.Y
		}

		local isBlack = self.SelectionIsBlack

		local function c()
			local c = colours.white
			if isBlack then
				c = colours.black
			end
			isBlack = not isBlack
			return c
		end

		function horizontal(y)
			Drawing.WriteToBuffer(self.X - 1 + point1.X, self.Y - 1 + y, '+', c(), colours.transparent)
			if size.X > 0 then
				for i = 1, size.X - 1 do
					Drawing.WriteToBuffer(self.X - 1 + point1.X + i, self.Y - 1 + y, '-', c(), colours.transparent)
				end
			else
				for i = 1, (-1 * size.X) - 1 do
					Drawing.WriteToBuffer(self.X - 1 + point1.X - i, self.Y - 1 + y, '-', c(), colours.transparent)
				end
			end

			Drawing.WriteToBuffer(self.X - 1 + point1.X + size.X, self.Y - 1 + y, '+', c(), colours.transparent)
		end

		function vertical(x)
			if size.Y < 0 then
				for i = 1, (-1 * size.Y) - 1 do
					Drawing.WriteToBuffer(self.X - 1 + x, self.Y - 1 + point1.Y  - i, '|', c(), colours.transparent)
				end
			else
				for i = 1, size.Y - 1 do
					Drawing.WriteToBuffer(self.X - 1 + x, self.Y - 1 + point1.Y  + i, '|', c(), colours.transparent)
				end
			end
		end

		horizontal(point1.Y)
		vertical(point1.X)
		horizontal(point1.Y + size.Y)
		vertical(point1.X + size.X)

		self.SelectionTimer = self.Bedrock:StartTimer(function(_, timer)
			if timer == self.SelectionTimer then
				self.SelectionIsBlack = not self.SelectionIsBlack
			end
		end, 0.5)
	end
end

CreateLayer = function(self, name, backgroundColour, _type, pixels, visible)
	if not pixels then
		self:PushState()
		pixels = {}

		for x = 1, self.Width do
			pixels[x] = {}
			for y = 1, self.Height do
				pixels[x][y] = {
					BackgroundColour = backgroundColour,
					TextColour = colours.black,
					Character = ' '
				}
			end
		end
	elseif #pixels ~= self.Width or #pixels[1] ~= self.Height then
		for x = 1, self.Width do
			if not pixels[x] then
				pixels[x] = {}
			end
			for y = 1, self.Height do
				if not pixels[x][y] then
					pixels[x][y] = {
						BackgroundColour = backgroundColour,
						TextColour = colours.black,
						Character = ' '
					}
				end
			end
		end
	end

	local layer = {
		Name = name,
		Pixels = pixels,
		BackgroundColour = backgroundColour or colours.transparent,
		Visible = (visible ~= nil and visible or true),
		Index = #self.Layers + 1,
		LayerType = _type or 'Normal'
	}
	table.insert(self.Layers, layer)

	self:UpdateLayers()
	self:PushState()
	return layer
end


-- copied from SO
local function recursive_compare(t1,t2)
  if t1==t2 then return true end
  if (type(t1)~="table") then return false end
  local mt1 = getmetatable(t1)
  local mt2 = getmetatable(t2)
  if( not recursive_compare(mt1,mt2) ) then return false end
  for k1,v1 in pairs(t1) do
  	if not t2[k1] then return false end
    local v2 = t2[k1]
    if( not recursive_compare(v1,v2) ) then return false end
  end
  for k2,v2 in pairs(t2) do
  	if not t1[k2] then return false end
    local v1 = t1[k2]
    if( not recursive_compare(v1,v2) ) then return false end
  end
  return true  
end

StatesEqual = function(self, one, two)
	return recursive_compare(one, two)
end

-- copied from Lua docs
local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

PushState = function(self)
	if #self.History == 0 or not self:StatesEqual(self.History[self.HistoryPosition], self.Layers) then
		self.PushStateDelay = nil
		table.insert(self.History, self.HistoryPosition + 1, deepcopy(self.Layers))
		self.HistoryPosition = self.HistoryPosition + 1
		self:UpdateUndoRedoMenuItems()
	end
end

DelayedPushState = function(self)
	if not self.PushStateDelay then
		self.PushStateDelay = self.Bedrock:StartTimer(function()
			self:PushState()
		end, 1)
	end
end

GoToHistoryPosition = function(self, position)
	if position ~= self.HistoryPosition and position >= 1 and position <= #self.History then
		self.HistoryPosition = position
		self.Layers = deepcopy(self.History[self.HistoryPosition])
		self:SetZoom(self.Zoom)
		self:UpdateLayers()
		self:ForceDraw()
		self:UpdateUndoRedoMenuItems()
	end
end

Undo = function(self)
	self:GoToHistoryPosition(self.HistoryPosition - 1)
end

Redo = function(self)
	self:GoToHistoryPosition(self.HistoryPosition + 1)
end

EraseSelection = function(self)
	return (self:GetCurrentLayer():GetSelectedPixels(true) ~= nil)
end

Copy = function(self)
	Clipboard.Copy(deepcopy(self:GetCurrentLayer():GetSelectedPixels()), 'sketchpixels')
	self.Selection = nil
	self:UpdateSelectionMenuItems()
	self:UpdateClipboardMenuItems()
end

Cut = function(self)
	Clipboard.Cut(deepcopy(self:GetCurrentLayer():GetSelectedPixels(true)), 'sketchpixels')
	self.Selection = nil
	self:UpdateSelectionMenuItems()
	self:UpdateClipboardMenuItems()
end

Paste = function(self)
	local pixels, t = Clipboard.Paste()
	if pixels and t == 'sketchpixels' then
		self:SetCurrentLayer(nil)
		self:CreateLayer('Pasted Content', colours.transparent, 'Normal', pixels)
		-- self:UpdateLayers()
	end
	self:UpdateClipboardMenuItems()
end

DuplicateLayer = function(self, layer)
	local newLayer = deepcopy(layer)
	newLayer.Name = newLayer.Name .. ' Copy'
	table.insert(self.Layers, newLayer)
	self:UpdateLayers()
	self:PushState()
end

UpdateUndoRedoMenuItems = function(self)
	self.Bedrock:GetObject('RedoMenuItem').Enabled = self.HistoryPosition < #self.History
	self.Bedrock:GetObject('UndoMenuItem').Enabled = self.HistoryPosition > 1
end

UpdateSelectionMenuItems = function(self)
	local selection = (self.Selection ~= nil and self.Selection[1] ~= nil and self.Selection[2] ~= nil)
	self.Bedrock:GetObject('CutMenuItem').Enabled = selection
	self.Bedrock:GetObject('CopyMenuItem').Enabled = selection
	self.Bedrock:GetObject('CropMenuItem').Enabled = selection
	self.Bedrock:GetObject('EraseMenuItem').Enabled = selection
	local window = self.Bedrock:GetObject('InfoWindow')
	if window then
		window:UpdateInfo()
	end
end

UpdateClipboardMenuItems = function(self)
	self.Bedrock:GetObject('PasteMenuItem').Enabled = (Clipboard.Content ~= nil and Clipboard.Type == 'sketchpixels')
end

Modified = function(self, layers)
	return not self:StatesEqual(self.History[self.HistoryPosition], self.SavedState)
end

SetBrushColour = function(self, value)
	self.BrushColour = value
	self.Bedrock:GetObject('PrimaryColourView').BackgroundColour = self.BrushColour
	self:PushState()
end

SetSecondaryBrushColour = function(self, value)
	self.SecondaryBrushColour = value
	self.Bedrock:GetObject('SecondaryColourView').BackgroundColour = self.SecondaryBrushColour
	self:PushState()
end

SetTool = function(self, value)
	if not value.OnSelect or value.OnSelect(self) then
		if self.Tool and self.Tool.OnStopUse then
			self.Tool.OnStopUse(self)
		end

		self.Tool = value
		self.Bedrock:GetObject('CurrentToolLabel').Text = self.Tool.Name
		self:PushState()
	end
end

SetZoom = function(self, value)
	if value > 0 and value <= 4 then
		self.Zoom = value
		local pixels = self:GetCurrentLayer().Layer.Pixels
		local width = self.Bedrock.Helpers.Round(self.Zoom * #pixels)
		local height = self.Bedrock.Helpers.Round(self.Zoom * #pixels[1])
		if width < 1 then
			width = 1
		end
		if height < 1 then
			height = 1
		end

		self.X = self.Bedrock.Helpers.Round(self.X + (self.Width - width)/2)
		self.Y = self.Bedrock.Helpers.Round(self.Y + (self.Height - height)/2)

		self.Width = width
		self.Height = height
	end
end

UpdateLayers = function(self)
	self.CurrentLayer = nil
	self:RemoveAllObjects()

	for i, v in ipairs(self.Layers) do
		self:AddObject({
			Type = "Layer",
			Layer = v,
			Width = self.Width,
			Height = self.Height,
			LayerIndex = i
		})
	end
	self:GetCurrentLayer()

	local window = self.Bedrock:GetObject('LayersWindow')
	if window then
		window:UpdateLayers()
	end
end

GetPixelBelowLayer = function(self, x, y, layerIndex)
	local bgColour = colours.transparent
	local txtColour = colours.transparent
	local char = ' '

	for i = 1, layerIndex - 1 do
		if self.Children[i].Visible then
			local p = self.Children[i].DrawnPixels[x][y]
			if p then
				if p.BackgroundColour ~= colours.transparent then
					bgColour = p.BackgroundColour
				end

				if p.TextColour ~= colours.transparent and p.Character ~= ' ' then
					txtColour = p.TextColour
					char = p.Character
				end
			end
		end
	end
	return bgColour, txtColour, char
end

GetBackgroundColour = function(self)
	for i = #self.Layers, 1, -1 do --children are ordered from smallest Z to highest, so this is done in reverse
		if self.Layers[i].BackgroundColour ~= colours.transparent then
			return self.Layers[i].BackgroundColour
		end
	end
	return colours.transparent
end

GetFlattenedPixels = function(self)
	local pixels = {}
	local bg = self:GetBackgroundColour()
	for x = 1, self.Width do
		pixels[x] = {}
		for y = 1, self.Height do
			pixels[x][y] = {
				BackgroundColour = bg,
				TextColour = colours.black,
				Character = ' '
			}
		end
	end

	self:Draw()
	for i, v in ipairs(self.Children) do
		for x, col in pairs(v.DrawnPixels) do
			for y, pixel in pairs(col) do
				if pixel then
					if pixel.BackgroundColour ~= colours.transparent then
						pixels[x][y].BackgroundColour = pixel.BackgroundColour
					end

					if pixel.Character ~= ' ' then
						pixels[x][y].Character = pixel.Character
						pixels[x][y].TextColour = pixel.TextColour
					end
				end
			end
		end
	end
	return pixels
end

FlattenImage = function(self)
	local pixels = self:GetFlattenedPixels()
	self.Layers = {}
	self:CreateLayer('Background', self:GetBackgroundColour(), 'Normal', pixels)
	self:PushState()
end

Resize = function(self, width, height, keepTextDetail)
	for i, layer in ipairs(self.Layers) do
		self.Layers[i].Pixels = self.Children[i]:GetZoomPixels(width, height, keepTextDetail)
	end
	self.Width = width
	self.Height = height
	self.X = self.Bedrock.Helpers.Round((Drawing.Screen.Width - self.Width - 3) / 2)
	self.Y = self.Bedrock.Helpers.Round((Drawing.Screen.Height - self.Height) / 2)
	self:PushState()
	self:UpdateLayers()
	self:ForceDraw()
end

ChangeCanvasSize = function(self, width, height, anchor, top, bottom, left, right)
	top = top or 0
	bottom = bottom or 0
	left = left or 0
	right = right or 0

	if anchor then
		if anchor == 2 or anchor == 5 or anchor == 8 then
			left = math.floor((width - self.Width) / 2)
			right = math.ceil((width - self.Width) / 2)
		elseif anchor == 1 or anchor == 4 or anchor == 7 then
			right = width - self.Width
		elseif anchor == 3 or anchor == 6 or anchor == 9 then
			left = width - self.Width
		end

		if anchor / 3 <= 1 then
			bottom = height - self.Height
		elseif anchor / 3 <= 2 then
			top = math.floor((height - self.Height) / 2)
			bottom = math.ceil((height - self.Height) / 2)
		else
			top = height - self.Height
		end
	end

	for i, layer in ipairs(self.Layers) do
		if left < 0 then
			for x = 1, -left do
				table.remove(layer.Pixels, 1)
			end
		end

		if right < 0 then
			for x = 1, -right do
				table.remove(layer.Pixels, #layer.Pixels)
			end
		end

		if top < 0 then
			for y = 1, -top do
				for x = 1, self.Width do
					if layer.Pixels[x] then
						table.remove(layer.Pixels[x], 1)
					end
				end
			end
		end

		if bottom < 0 then
			for y = 1, -bottom do
				for x = 1, self.Width do
					if layer.Pixels[x] then
						table.remove(layer.Pixels[x], #layer.Pixels[x])
					end
				end
			end
		end

		for x = 1, left do
			table.insert(layer.Pixels, 1, {})
			for y = 1, height do
				layer.Pixels[1][y] = {BackgroundColour = layer.BackgroundColour, TextColour = colours.black, Character = ' '}
			end
		end

		for x = 1, right do
			table.insert(layer.Pixels, {})
			for y = 1, height do
				layer.Pixels[#layer.Pixels][y] = {BackgroundColour = layer.BackgroundColour, TextColour = colours.black, Character = ' '}
			end
		end

		for y = 1, top do
			for x = 1, width do
				table.insert(layer.Pixels[x], 1, {})
				layer.Pixels[x][1] = {BackgroundColour = layer.BackgroundColour, TextColour = colours.black, Character = ' '}
			end
		end

		for y = 1, bottom do
			for x = 1, width do
				table.insert(layer.Pixels[x], {})
				layer.Pixels[x][#layer.Pixels[x]] = {BackgroundColour = layer.BackgroundColour, TextColour = colours.black, Character = ' '}
			end
		end
	end

	self.Width = width
	self.Height = height
	self.X = self.Bedrock.Helpers.Round((Drawing.Screen.Width - self.Width - 3) / 2)
	self.Y = self.Bedrock.Helpers.Round((Drawing.Screen.Height - self.Height) / 2)
	self:PushState()
	self:UpdateLayers()
	self:ForceDraw()
end

Crop = function(self)
	if self.Selection and self.Selection[1] and self.Selection[2] then
		local top = 0
		local left = 0
		local bottom = 0
		local right = 0
		if self.Selection[1].X < self.Selection[2].X then
			left = self.Selection[1].X - 1
			right = self.Width - self.Selection[2].X
		else
			left = self.Selection[2].X - 1
			right = self.Width - self.Selection[1].X
		end
		if self.Selection[1].Y < self.Selection[2].Y then
			top = self.Selection[1].Y - 1
			bottom = self.Height - self.Selection[2].Y
		else
			top = self.Selection[2].Y - 1
			bottom = self.Height - self.Selection[1].Y
		end
		self:ChangeCanvasSize(self.Width - left - right, self.Height - top - bottom, nil, -top, -bottom, -left, -right)
		self.Selection = {}
	end
end

SetSavedState = function(self)
	self.SavedState = deepcopy(self.History[self.HistoryPosition])
end

OnLoad = function(self)
	self:UpdateLayers()
	self:SetTool(PencilTool)
	self:SetBrushColour(colours.lightBlue)
	self:SetSecondaryBrushColour(colours.magenta)
	self.BrushSize = 1

	self:PushState()
	self:SetSavedState()

	self.Bedrock.OnArtboardOpen(self)
	self:UpdateUndoRedoMenuItems()
	self:UpdateSelectionMenuItems()
	self:UpdateClipboardMenuItems()
end

OnDeleteLayer = function(self, layer)
	if layer == self.CurrentLayer then
		self.CurrentLayer = self.Children[#self.Children]
	end
	self:PushState()
end

GetCurrentLayer = function(self)
	if not self.CurrentLayer then
		self:SetCurrentLayer(self.Children[#self.Children])
	end
	return self.CurrentLayer
end

SetCurrentLayer = function(self, layer)
	self.CurrentLayer = layer

	local window = self.Bedrock:GetObject('LayersWindow')
	if window then
		window:UpdateLayers()
	end
end

OnUpdate = function(self, value)
	if value == 'Layers' or value == 'Width' or value == 'Height' then
		self:UpdateLayers()
	elseif value == 'Selection' then
		self:UpdateSelectionMenuItems()
	end
end

OnClick = function(self, event, side, x, y)
	if self.Tool then
		self.Tool.OnUse(self, event, side, x, y)
	end
end

OnRemove = function(self)
	self.Bedrock.OnArtboardClose(self)
end

OnDrag = OnClick

NewLayer = function(self)
	self.Bedrock:DisplayTextBoxWindow('New Layer', "Enter the name for the new layer.", function(success, name)
		if success then
			self:CreateLayer(name, colours.transparent)
		end
	end)
end