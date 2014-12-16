BackgroundColour = colours.transparent
DrawnPixels = nil
UpdateDrawBlacklist = {['DrawnPixels']=true}
Ready = false
CursorPos = nil

OnLoad = function(self)
	-- self.LayerName = self.Layer.Nae
	-- self.Pixels = ParseNFT(self.Layer.Pixels)
	self.BackgroundColour = self.Layer.BackgroundColour
	self.Visible = self.Layer.Visible
	self.Ready = true
end

OnDraw = function(self, x, y)
	if self.Layer.LayerType == 'Normal' or self.Parent.ShowFilterMask then
		local drawnPixels = {}
		for _x, col in ipairs(self:GetZoomPixels(self.Width, self.Height, true)) do
			drawnPixels[_x] = {}
			for _y, pixel in ipairs(col) do
				if pixel.Character ~= ' ' or pixel.BackgroundColour ~= colours.transparent then
					drawnPixels[_x][_y] = pixel
					Drawing.WriteToBuffer(x + _x - 1, y + _y - 1, pixel.Character, pixel.TextColour, pixel.BackgroundColour)
				end
			end
		end
		self.DrawnPixels = drawnPixels

		if self.Bedrock:GetActiveObject() == self then
			self.Bedrock.CursorPos = {x + self.CursorPos[1] - 1, y + self.CursorPos[2] - 1}
			self.Bedrock.CursorColour = self.Parent.BrushColour
		else
			self.CursorPos = nil
		end
	elseif self.Layer.LayerType:sub(1, 7) == 'Filter:' then
		local drawnPixels = {}
		for _x, col in ipairs(self:GetZoomPixels(self.Width, self.Height)) do
			drawnPixels[_x] = {}
			for _y, pixel in ipairs(col) do
				if pixel.BackgroundColour == colours.white then
					local bgColour, txtColour, char = self.Parent:GetPixelBelowLayer(_x, _y, self.LayerIndex)
					local filter = Drawing.Filters[self.Layer.LayerType:sub(8)]
					if not filter then
						filter = Drawing.Filters.None
					end

					bgColour = Drawing.FilterColour(bgColour, filter)
					txtColour = Drawing.FilterColour(txtColour, filter)

					if txtColour == colors.transparent then
						txtColour = colours.black
						char = ' '
					end
					drawnPixels[_x][_y] = {Character = char, TextColour = txtColour, BackgroundColour = bgColour}
					Drawing.WriteToBuffer(x + _x - 1, y + _y - 1, char, txtColour, bgColour)
				end
			end
		end
		self.DrawnPixels = drawnPixels
	end
end

GetZoomPixels = function(self, width, height, preserveDetail)
	local pixels = {}
	local deltaX = #self.Layer.Pixels / width
	local deltaY = #self.Layer.Pixels[1] / height

	if deltaX == 1 and deltaY == 1 then
		return self.Layer.Pixels
	end

	for _x = 1, width do
		local x = self.Bedrock.Helpers.Round(1*deltaX + (_x - 1) * deltaX)
		if not self.Layer.Pixels[x] then
			if x < 1 then
				x = 1
			else
				x = #self.Layer.Pixels
			end
		end
		pixels[_x] = {}
		for _y = 1, height do
			local y = self.Bedrock.Helpers.Round(1*deltaY + (_y - 1) * deltaY)
			if not self.Layer.Pixels[x][y] then
				if y < 1 then
					y = 1
				else
					y = #self.Layer.Pixels[x]
				end
			end
			pixels[_x][_y] = self.Layer.Pixels[x][y]
			if not preserveDetail and pixels[_x][_y].Character ~= ' ' then
				pixels[_x][_y].Character = '-'
			end
		end
	end
	return pixels
end

GetEffectedPixels = function(self, x, y, brushSize, brushShape, correctPixelRatio)
	if brushSize == 1 then
		return {
			{x, y}
		}
	elseif brushShape == 'Square' then
		local pixels = {}
		local cornerX = math.ceil(x - brushSize/2)
		local cornerY = math.ceil(y - brushSize/2)
		for _x = 1, brushSize do
			for _y = 1, brushSize do
				if self.Layer.Pixels[cornerX + _x] and self.Layer.Pixels[cornerX + _x][cornerY + _y] then
					table.insert(pixels, {cornerX + _x, cornerY + _y})
				end
			end
		end
		return pixels
	elseif brushShape == 'Circle' then

		-- this circle algorithm looks terrible on odd values (try 5 and 3)

		local pixels = {{x, y}}
		local rSquared = math.pow(brushSize/2, 2)

		local round = self.Bedrock.Helpers.Round
		-- thanks to theoriginalbit for this (slightly modified) snippet
		-- local radius = brushSize / 2
  --       local radStep = 1/(1.5*radius)
  --       for angle = 1 + radStep, math.pi+radStep, radStep do
  --               local pX = math.cos( angle ) * radius * (correctPixelRatio and 1.5 or 1)
  --               local pY = math.sin( angle ) * radius

  --               local centreOffset =  1 - (brushSize % 2)

		-- 		table.insert(pixels, {round(x + pX) + centreOffset, round(y + pY)})
		-- 		table.insert(pixels, {round(x - pX), round(y + pY)})

		-- 		table.insert(pixels, {round(x + pX) + centreOffset, round(y - pY) + centreOffset})
		-- 		table.insert(pixels, {round(x - pX), round(y - pY) + centreOffset})
  --       end


	-- 	local Ys = {}
	-- 	for _y = 1, math.floor(brushSize/2) do
	-- 		Ys[_y] = math.sqrt(rSquared - math.pow(_y-1, 2))
	-- 	end
	-- 	local round = self.Bedrock.Helpers.Round

	-- print(' ')
		for _y = -brushSize/2, brushSize/2 do
			_y = round(_y)
			local _x = round(math.sqrt(math.abs(rSquared - math.pow(_y, 2))) * (correctPixelRatio and 1.5 or 1))
			-- print(_x..', '.._y)
			-- local xLeft = math.floor(x + (_x - 1))-- - 1 + (brushSize % 2))
			-- local xLeft = round(x + -1 * (_x - 1))
			-- local yTop = round(y + -1 * (_y - 1) )
			-- local yBottom = round(y + (_y - 1) - 1 + (brushSize % 2))
			local xLeft = x - _x
			local xRight = x + _x

			for xPixel = xLeft, xRight do
				table.insert(pixels, {xPixel, y + _y})
			end
			-- table.insert(pixels, {x - _x, y + _y})


			-- for xPixel = xLeft, xRight do
			-- 	table.insert(pixels, {xPixel, yBottom})
			-- 	table.insert(pixels, {xPixel, yTop})
			-- end

			-- table.insert(pixels, {xRight, })
			-- table.insert(pixels, {xLeft,  round(y + (_y - 1) + 1)})

			-- table.insert(pixels, {round(x + (_x - 1) + 1), round(y + -1*(_y - 1))})
			-- table.insert(pixels, {round(x + -1*(_x - 1)), round(y + -1*(_y - 1))})
		end
	-- print('.')


		-- for _y, _x in ipairs(Ys) do
		-- 	local xRight = math.floor(x + (_x - 1))-- - 1 + (brushSize % 2))
		-- 	local xLeft = round(x + -1 * (_x - 1))
		-- 	local yTop = round(y + -1 * (_y - 1) )
		-- 	local yBottom = round(y + (_y - 1) - 1 + (brushSize % 2))

		-- 		table.insert(pixels, {xLeft, yTop})


		-- 	-- for xPixel = xLeft, xRight do
		-- 	-- 	table.insert(pixels, {xPixel, yBottom})
		-- 	-- 	table.insert(pixels, {xPixel, yTop})
		-- 	-- end

		-- 	-- table.insert(pixels, {xRight, })
		-- 	-- table.insert(pixels, {xLeft,  round(y + (_y - 1) + 1)})

		-- 	-- table.insert(pixels, {round(x + (_x - 1) + 1), round(y + -1*(_y - 1))})
		-- 	-- table.insert(pixels, {round(x + -1*(_x - 1)), round(y + -1*(_y - 1))})
		-- end


		-- for a = -1, 1 do
		-- 	if a ~= 0 then
		-- 		for b = -1, 1 do
		-- 			if b ~= 0 then
		-- 				for _y, _x in ipairs(Ys) do
		-- 					table.insert(pixels, {round(x + a * (_x - 1)), round(y + b * (_y - 1))})
		-- 				end
		-- 			end
		-- 		end	
		-- 	end
		-- end

		-- -- thanks to theoriginalbit for this (slightly modified) snippet
		-- local radius = brushSize / 2
  --       local radStep = 1/(1.5*radius)
  --       for angle = 1, math.pi+radStep, radStep do
  --               local pX = math.cos( angle ) * radius-- * 1.5
  --               local pY = math.sin( angle ) * radius

  --                       	print(pX .. '@'..pY)
  --                       	sleep(0.5)

  --               for i=-1,1,2 do
  --                       for j=-1,1,2 do
  --                       	-- for _x = 0, pX do
  --                       		local _x = pX
		-- 						table.insert(pixels, {round(x + i*_x), round(y + j*pY)})
  --                       	-- end
  --                       end
  --               end
  --       end


		return pixels
	end
end

SetPixel = function(self, x, y, backgroundColour, textColour, character)
	if self.Layer.Pixels and self.Layer.Pixels[x] and self.Layer.Pixels[x][y] then
		if backgroundColour then
			self.Layer.Pixels[x][y].BackgroundColour = backgroundColour
		end
		if textColour then
			self.Layer.Pixels[x][y].TextColour = textColour
		end
		if character then
			self.Layer.Pixels[x][y].Character = character
		end
		self:ForceDraw()
		self.Parent:DelayedPushState()
	end
end

DeleteLayer = function(self, force)
	if #self.Parent.Layers > 1 then
		local function delete()
			for i, v in ipairs(self.Parent.Layers) do
				if v == self.Layer then
					table.remove(self.Parent.Layers, i)
					self.Parent:SetCurrentLayer(nil)
					self.Parent:OnDeleteLayer(v)
					self.Parent:UpdateLayers()
					local window = self.Bedrock:GetObject('LayersWindow')
					if window then
						window:UpdateLayers()
					end
				end
			end
		end
		if force then
			delete()
		else
			self.Bedrock:DisplayAlertWindow('Delete Layer?', "Are you sure you want to delete the layer '"..self.Layer.Name.."'", {'Delete', 'Cancel'}, function(button)
				if button == 'Delete' then
					delete()
				end
			end)
		end
	else
		self.Bedrock:DisplayAlertWindow('Cannot delete layer!', "You cannot delete the last layer of an image! Make another layer to delete this one.", {'Ok'}, function()end)
	end
end

GetSelectionBoundaries = function(self)
	if self.Parent.Selection and self.Parent.Selection[1] and self.Parent.Selection[2] then
		local selection = self.Parent.Selection
		local left
		local right
		local top
		local bottom
		if selection[1].X > selection[2].X then
			right = selection[1].X
			left = selection[2].X
		else
			left = selection[1].X
			right = selection[2].X
		end

		if selection[1].Y > selection[2].Y then
			bottom = selection[1].Y
			top = selection[2].Y
		else
			top = selection[1].Y
			bottom = selection[2].Y
		end
		return left, right, top, bottom
	end
end

GetSelectedPixels = function(self, cut)
	local pixels = {}
	local bg = self.Parent:GetBackgroundColour()
	if self.Parent.Selection and self.Parent.Selection[1] and self.Parent.Selection[2] then
		local left, right, top, bottom = self:GetSelectionBoundaries()
		local x = 1
		local y = 1
		for x = left, right do
			pixels[x] = {}
			for y = top, bottom do
				if self.Layer.Pixels[x] and self.Layer.Pixels[x][y] then
					pixels[x][y] = self.Layer.Pixels[x][y]
					if cut then
						self.Layer.Pixels[x][y] = {
							BackgroundColour = bg,
							TextColour = colours.black,
							Character = ' '
						}
					end
				end
				y = y + 1
			end
			x = x + 1
		end
	end
	self.Parent:PushState()
	return pixels
end

Move = function(self, deltaX, deltaY)
	local pixels = {}
	local bg = self.Parent:GetBackgroundColour()
	if self.Parent.Selection and self.Parent.Selection[1] and self.Parent.Selection[2] then
		for x = 1, self.Width do
			pixels[x] = {}
			for y = 1, self.Height do
				pixels[x][y] = self.Layer.Pixels[x][y]
			end
		end

		local left, right, top, bottom = self:GetSelectionBoundaries()

		for x = left, right do
			for y = top, bottom do
				if self.Layer.Pixels[x] and self.Layer.Pixels[x][y] and pixels[x] and pixels[x][y] then
					pixels[x][y] = {
						BackgroundColour = bg,
						TextColour = colours.black,
						Character = ' '
					}
				end
			end
		end

		for x = left, right do
			for y = top, bottom do
				if self.Layer.Pixels[x] and self.Layer.Pixels[x][y] and pixels[x + deltaX] and pixels[x + deltaX][y + deltaY] then
					pixels[x + deltaX][y + deltaY] = self.Layer.Pixels[x][y]
				end
			end
		end

		selection[1].X = selection[1].X + deltaX
		selection[1].Y = selection[1].Y + deltaY
		selection[2].X = selection[2].X + deltaX
		selection[2].Y = selection[2].Y + deltaY
	else
		for x = 1, self.Width do
			pixels[x] = {}
			for y = 1, self.Height do
				if self.Layer.Pixels[x - deltaX] and self.Layer.Pixels[x - deltaX][y - deltaY] then
					pixels[x][y] = self.Layer.Pixels[x - deltaX][y - deltaY]
				else
					pixels[x][y] = {
						BackgroundColour = bg,
						TextColour = colours.black,
						Character = ' '
					}
				end
			end
		end
	end
	self.Layer.Pixels = pixels
end

MergeWith = function(self, other)
	for x, col in pairs(other.DrawnPixels) do
		for y, pixel in pairs(col) do
			if pixel then
				if pixel.BackgroundColour ~= colours.transparent then
					self.Layer.Pixels[x][y].BackgroundColour = pixel.BackgroundColour
				end

				if pixel.Character ~= ' ' then
					self.Layer.Pixels[x][y].Character = pixel.Character
					self.Layer.Pixels[x][y].TextColour = pixel.TextColour
				end
			end
		end
	end
	other:DeleteLayer(true)
	self.Parent:PushState()
end

MergeDown = function(self)
	if self.LayerIndex - 1 >= 1 then
		local below = self.Parent.Children[self.LayerIndex - 1]
		if self.Layer.LayerType == below.Layer.LayerType then
			below:MergeWith(self)
		else
			self.Bedrock:DisplayAlertWindow('Cannot merge layer!', "You can't merge layers of different types.", {'Ok'}, function()end)
		end
	else
		self.Bedrock:DisplayAlertWindow('Cannot merge layer!', "There isn't a layer below this layer!", {'Ok'}, function()end)
	end
end

RenameLayer = function(self)
	self.Bedrock:DisplayTextBoxWindow('Rename Layer', "Enter the new name for the layer '"..self.Layer.Name.."'", function(success, newName)
		if success then
			self.Layer.Name = newName
			self.Parent:UpdateLayers()
		end
	end, self.Layer.Name, #self.Layer.Name)
end

OnUpdate = function(self, value)
	if value == 'Visible' and self.Ready then
		self.Layer.Visible = self.Visible
	end
end

OnKeyChar = function(self, event, keychar)
	local function updateCharPos()
		if self.CursorPos[1] > #self.Layer.Pixels then
			self.CursorPos[1] = 1
			self.CursorPos[2] = self.CursorPos[2] + 1
		elseif self.CursorPos[1] < 1 then
			self.CursorPos[1] = #self.Layer.Pixels 
			self.CursorPos[2] = self.CursorPos[2] - 1
		end

		if self.CursorPos[2] > #self.Layer.Pixels[1] then
			self.CursorPos = {1, 1}
		elseif self.CursorPos[2] < 1 then
			self.CursorPos = {#self.Layer.Pixels, #self.Layer.Pixels[1]}
		end
	end
	if event == 'char' then
		if keychar == 'nil' then
			return
		end
		self.Layer.Pixels[self.CursorPos[1]][self.CursorPos[2]].Character = keychar
		self.Layer.Pixels[self.CursorPos[1]][self.CursorPos[2]].TextColour = self.Parent.BrushColour

		self.CursorPos[1] = self.CursorPos[1] + 1
		updateCharPos()
		self:ForceDraw()
		return false
	elseif event == 'key' then
		if keychar == keys.enter then
			self.CursorPos[2] = self.CursorPos[2] + 1
		elseif keychar == keys.left then
			self.CursorPos[1] = self.CursorPos[1] - 1
		elseif keychar == keys.right then
			self.CursorPos[1] = self.CursorPos[1] + 1
		elseif keychar == keys.up then
			self.CursorPos[2] = self.CursorPos[2] - 1
		elseif keychar == keys.down then
			self.CursorPos[2] = self.CursorPos[2] + 1
		elseif keychar == keys.backspace then
			self.CursorPos[1] = self.CursorPos[1] - 1
			updateCharPos()
			self.Layer.Pixels[self.CursorPos[1]][self.CursorPos[2]].Character = ' '
			self.Layer.Pixels[self.CursorPos[1]][self.CursorPos[2]].TextColour = colours.black
		elseif keychar == keys.home then
			self.CursorPos[1] = 1
		elseif keychar == keys.delete then
			self.Layer.Pixels[self.CursorPos[1]][self.CursorPos[2]].Character = ' '
			self.Layer.Pixels[self.CursorPos[1]][self.CursorPos[2]].TextColour = colours.black
			self.CursorPos[1] = self.CursorPos[1] + 1
		elseif keychar == keys["end"] then
			self.CursorPos[1] = #self.Layer.Pixels
		else
			return false
		end
		updateCharPos()
		self:ForceDraw()
	end
end