Name = 'Text'

OnUse = function(artboard, event, side, x, y)
	local layer = artboard:GetCurrentLayer()
	if layer.Layer.LayerType ~= 'Normal' then
		layer.Bedrock:DisplayAlertWindow('Tool Not Supported!', "You cannot use the text tool on non-normal layers.", {'Ok'}, function()end)
	elseif side == 1 then
		layer.CursorPos = {x, y}
		layer.Bedrock:SetActiveObject(layer)
	elseif side == 2 then
		local pixels = layer:GetEffectedPixels(x, y, artboard.BrushSize, artboard.BrushShape, artboard.CorrectPixelRatio)
		for i, pixel in ipairs(pixels) do
			layer:SetPixel(pixel[1], pixel[2], nil, artboard.BrushColour)
		end
	end
end

OnStopUse = function(artboard)
	local layer = artboard:GetCurrentLayer()
	layer.Bedrock:SetActiveObject()
end