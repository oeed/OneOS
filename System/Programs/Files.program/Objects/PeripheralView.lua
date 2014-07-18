Inherit = 'View'

BackgroundColour = colours.transparent
Side = false

OnUpdate = function(self, value)
	if value == 'Side' then
		self:RemoveAllObjects()
		if self.Side and #self.Side ~= 0 then
			local p = Peripheral.GetSide(self.Side)
			local path = 'Images/'..p.Type
			if not fs.exists(path) then
				path = 'Images/unknown'
			end
			self:AddObject({
				Type = 'ImageView',
				X = 3,
				Y = 2,
				Width = 5,
				Height = 4,
				Path = path,
				Name = 'PeripheralImageView'
			})
			self:AddObject({
				Type = 'Label',
				X = 10,
				Y = 2,
				Text = p.FormattedType,
				Name = 'NameLabel'
			})
			self:AddObject({
				Type = 'Label',
				X = 10,
				Y = 3,
				Text = self.Bedrock.Helpers.Capitalise(p.Side),
				Name = 'SideLabel',
				TextColour = colours.grey
			})
			local info = Peripheral.GetInfo(p)

			local btnX = 10
			for i, v in ipairs(info.Buttons) do
				self:AddObject({
					Type = 'Button',
					X = btnX,
					Y = 5,
					Text = v.Text,
					Name = 'InfoButton',
					OnClick = v.OnClick
				})
				btnX = btnX + #v.Text + 3
			end


			local x = self.Bedrock.Helpers.LongestString(info, nil, true) + 5
			local y = 7
			for k, v in pairs(info) do
				if k ~= 'Buttons' then
					self:AddObject({
						Type = 'Label',
						X = 3,
						Y = y,
						Text = k,
						Name = 'InfoKeyLabel'..k,
						TextColour = colours.grey
					})
					self:AddObject({
						Type = 'Label',
						X = x,
						Y = y,
						Text = v,
						Name = 'InfoValueLabel'..k,
					})
					y = y + 1
				end
			end
		end
	end
end


	-- Drawing.DrawCharacters(Current.SidebarWidth+10, 6, Current.Peripheral.Type, colours.black, colours.white)
	-- Drawing.DrawCharacters(Current.SidebarWidth+10, 7, Current.Peripheral.Side, colours.grey, colours.white)
	-- Drawing.DrawImage(Current.SidebarWidth+3, 6, Current.Peripheral.Image, 5, 4)
	-- local y = 11
	-- local x = Helpers.LongestString(Current.Peripheral.Info, nil, true) + 5
	-- for k, v in pairs(Current.Peripheral.Info) do
	-- 	Drawing.DrawCharacters(Current.SidebarWidth+3, y, k, colours.grey, colours.white)
	-- 	Drawing.DrawCharacters(Current.SidebarWidth+x, y, v, colours.black, colours.white)
	-- 	y = y + 1
	-- end
	-- if diskOpenButton then
	-- 	diskOpenButton:Draw()
	-- end