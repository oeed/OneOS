Inherit = 'SnapWindow'
ContentViewName = 'layerswindow'

Title = 'Layers'

OnContentLoad = function(self)
	self:UpdateLayers()
end

UpdateLayers = function(self)
	self:GetObject('ScrollView'):RemoveAllObjects()
	local artboard = self.Bedrock:GetObject('Artboard')
	if artboard then
		for i, layer in ipairs(artboard.Children) do
			self:GetObject('ScrollView'):AddObject({
				Type = 'LayerView',
				X = 1,
				Y = 1 + (#artboard.Children - i) * LayerView.Height,
				Width = '100%',
				Layer = layer,
				LayerIndex = i
			})
		end
		local maxHeight = Drawing.Screen.Height - 4
		local height = #artboard.Children * LayerView.Height
		if height > maxHeight then
			height = maxHeight
		end

		self:GetObject('ContentView').Height = height
		self:GetObject('ScrollView').Height = height
		self:GetObject('ScrollView'):UpdateScroll()
		self.Height = 1 + height
	end
end

OrderLayers = function(self)
	local artboard = self.Bedrock:GetObject('Artboard')
	if artboard then
		local layers = {}
		for i, v in ipairs(self:GetObject('ScrollView').Children) do
			if v.Type == 'LayerView' then
				table.insert(layers, v.Layer.Layer)
			end
		end
		artboard.Layers = layers
		artboard:PushState()
	end
end

Rearrange = function(self, dragging, y)
	local artboard = self.Bedrock:GetObject('Artboard')
	if artboard then
		local children = self:GetObject('ScrollView').Children

		local scrollBar = self:GetObject('ScrollViewScrollBar')

		local newIndex = #children - (scrollBar and 1 or 0) - math.floor((dragging.Y + y - 2 ) / 4)
		if newIndex > #children then
			newIndex = #children
		elseif newIndex < 1 then
			newIndex = 1
		end
		local oldIndex = dragging.LayerIndex

		if newIndex ~= oldIndex then
			local newChildren = {}
			newChildren[newIndex] = dragging
			dragging.LayerIndex = newIndex

			for i, layer in ipairs(children) do
				if layer ~= dragging then
					table.insert(newChildren, layer)
					local index = #newChildren
					if index == newIndex then
						index = index - 1
					end
					layer.LayerIndex = index
					layer.Y = 1 + (#children - layer.LayerIndex) * 4
				end
			end
			self:GetObject('ScrollView').Children = newChildren
		end
	end
end