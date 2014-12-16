Name = 'Select'

OnUse = function(artboard, event, side, x, y)
	if event == 'mouse_click' then
		artboard.Selection = {
			{
				X = x,
				Y = y
			},
			nil
		}
	elseif event == 'mouse_drag' then
		if artboard.Selection and artboard.Selection[1] then
			artboard.Selection = {
				artboard.Selection[1],
				{
					X = x,
					Y = y
				}
			}
		end
	end
end