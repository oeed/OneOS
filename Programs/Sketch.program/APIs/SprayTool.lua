Name = 'Spray'

OnUse = function(artboard, event, side, x, y)
	local layer = artboard:GetCurrentLayer()
	-- artboard.BrushSize
	local pixels = layer:GetEffectedPixels(x, y, artboard.BrushSize, artboard.BrushShape, artboard.CorrectPixelRatio)

	local colour = (side == 1 and artboard.BrushColour or artboard.SecondaryBrushColour)
	if layer.Layer.LayerType ~= 'Normal' then
		if colour == colours.transparent then
			colour = colours.black
		end
		colour = Drawing.FilterColour(colour, Drawing.Filters.BlackWhite)
	end

	for i, pixel in ipairs(pixels) do
		if math.random(0, 3) == 0 then
			if side == 1 then
				layer:SetPixel(pixel[1], pixel[2], colour)
			elseif side == 3 then
				layer:SetPixel(pixel[1], pixel[2], nil, colour)
			end
		end
	end
end