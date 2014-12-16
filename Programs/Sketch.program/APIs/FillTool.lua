Name = 'Fill'

OnUse = function(artboard, event, side, x, y)
	local layer = artboard:GetCurrentLayer()
	local pixels = layer.Layer.Pixels
	local replaceColour = pixels[x][y].BackgroundColour
	-- if side == 2 then
	-- 	replaceColour = pixels[x][y].TextColour
	-- end

	local colour = (side == 1 and artboard.BrushColour or artboard.SecondaryBrushColour)

	local nodes = {{X = x, Y = y}}

	while #nodes > 0 do
		local node = nodes[1]
		if pixels[node.X] and pixels[node.X][node.Y] then
			local replacing = pixels[node.X][node.Y].BackgroundColour
			-- if side == 2 then
			-- 	replacing = pixels[node.X][node.Y].TextColour
			-- end
			if replacing == replaceColour and replacing ~= colour then
				-- if side == 1 then
					layer:SetPixel(node.X, node.Y, colour)
				-- elseif side == 2 then
				-- 	layer:SetPixel(node.X, node.Y, nil, colour)
				-- end
				table.insert(nodes, {X = node.X, Y = node.Y + 1})
				table.insert(nodes, {X = node.X + 1, Y = node.Y})
				if x > 1 then
					table.insert(nodes, {X = node.X - 1, Y = node.Y})
				end
				if y > 1 then
					table.insert(nodes, {X = node.X, Y = node.Y - 1})
				end
			end
		end
		table.remove(nodes, 1)
	end
end
			