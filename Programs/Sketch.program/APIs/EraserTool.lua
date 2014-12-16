Name = 'Eraser'

OnUse = function(artboard, event, side, x, y)
	local layer = artboard:GetCurrentLayer()
	local pixels = layer:GetEffectedPixels(x, y, artboard.BrushSize, artboard.BrushShape, artboard.CorrectPixelRatio)

	local colour = colours.transparent
	if layer.Layer.LayerType ~= 'Normal' then
		colour = colours.black
	else
		colour = layer.BackgroundColour
	end

	for i, pixel in ipairs(pixels) do
		if side == 1 then
			layer:SetPixel(pixel[1], pixel[2], colour)
		elseif side == 2 then
			layer:SetPixel(pixel[1], pixel[2], nil, colours.black, ' ')
		end
	end
end