Inherit = 'PageView'

OnLoad = function(self)
	ScrollView.OnLoad(self)

	self:AddObject({
		X = 1,
		Y = '50%,-3',
		Width = '100%',
		Align = 'Center',
		TextColour = 'grey',
		Type = 'Label',
		Text = 'Search'
	})

	self:AddObject({
		X = 1,
		Y = '50%,-2',
		Width = '100%',
		Align = 'Center',
		TextColour = 'lightGrey',
		Type = 'Label',
		Text = 'Find that app you\'re looking for'
	})

	self:AddObject({
		X = '50%,-12',
		Y = '50%',
		Width = 21,
		Type = 'TextBox',
		Active = true,
		Placeholder = 'Search...',
		Name = 'SearchBox',
		OnChange = function(_, event, keychar)
			if keychar == keys.enter then
				self:GetObject('SearchButton'):OnClick()
			end
		end
	})

	self:AddObject({
		X = '50%,10',
		Y = '50%',
		Type = 'Button',
		BackgroundColour = 'blue',
		TextColour = 'white',
		Text = 'Go',
		Name = 'SearchButton',
		OnClick = function()
			local text = self:GetObject('SearchBox').Text

			if text ~= '' then
				self.Bedrock:OpenPage('SearchResultsPageView', {SearchTerm = text})
			end
		end
	})
end