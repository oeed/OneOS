Name = 'Move'

OnUse = function(artboard, event, side, x, y)
	if event == 'mouse_click' then
		artboard.MoveHandle = {
			X = x,
			Y = y
		}
	elseif event == 'mouse_drag' then
		if artboard.MoveHandle and artboard.MoveHandle.X and artboard.MoveHandle.Y then
			artboard:GetCurrentLayer():Move(x - artboard.MoveHandle.X, y - artboard.MoveHandle.Y)
			artboard.MoveHandle = {
				X = x,
				Y = y
			}
		end
	end
end