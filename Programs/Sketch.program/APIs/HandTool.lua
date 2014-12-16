Name = 'Hand'

OnUse = function(artboard, event, side, x, y)
	if event == 'mouse_click' then
		artboard.DragStart = {x, y}
	elseif event == 'mouse_drag' and artboard.DragStart then
		local deltaX = x - artboard.DragStart[1]
		local deltaY = y - artboard.DragStart[2]
		artboard.X = artboard.X + deltaX
		artboard.Y = artboard.Y + deltaY
	else return
	end

	artboard.DragTimer = artboard.Bedrock:StartTimer(function(_, timer)
		if timer == artboard.DragTimer then
			artboard.DragStart = nil
			artboard.DragTimer = nil
		end
	end, 1)
end