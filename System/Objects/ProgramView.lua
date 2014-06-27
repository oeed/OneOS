	OnUpdate = function(self, value)
		if value == 'Width' then
			--self.Width = #self.Text + 2
			--self:UpdateEvokers()
			--return true
		end
	end

	OnDraw = function(self, x, y)
		Drawing.DrawBlankArea(x, y, self.Width, self.Height, colours.grey)
		if Current.Program then
			for _y, row in ipairs(Current.Program.AppRedirect.Buffer) do
				for _x, pixel in pairs(row) do
					Drawing.WriteToBuffer(x+_x-1, y+_y-1, pixel[1], pixel[2], pixel[3])
				end
			end
		end
	end

	OnClick = function(self, event, side, x, y)
		if Current.Program then
			Current.Program:Click(event, side, x, y)
		end
	end