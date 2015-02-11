Inherit = 'View'

Items = nil
Title = nil

OnSeeMore = nil

OnLoad = function(self)
	self:OnUpdate('Items')
end

OnUpdate = function(self, value)
	if value == 'Items' then
		self:RemoveAllObjects()

		self:AddObject({
			X = 2,	
			Y = 2,
			Type = 'Label',
			Text = self.Title,
			TextColour = colours.lightGrey
		})

		if self.OnSeeMore then
			self:AddObject({
				X = 3 + #self.Title,	
				Y = 2,
				Type = 'Label',
				Text = 'See More >',
				TextColour = colours.blue,
				OnClick = self.OnSeeMore
			})
		end

		local xStart = 2 + math.floor((self.Width % AppView.Width) / 2)
		local x = xStart
		local y = 4
		for i, app in ipairs(self.Items) do
			self:AddObject({
				X = x,	
				Y = y,
				Type = 'AppView',
				App = app
			})

			x = x + AppView.Width
			if x + AppView.Width > self.Width then
				x = xStart
				y = y + AppView.Height
			end
		end
	end
end