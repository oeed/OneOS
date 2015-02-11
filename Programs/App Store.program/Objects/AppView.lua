Inherit = 'View'

Width = 24
Height = 4
App = nil

OnLoad = function(self)
	self:AddObject({
		X = 1,
		Y = 1,
		Width = 4,
		Height = 3,
		Type = 'ImageView',
		-- Path = '/Resources/Ink'
	})

	self:AddObject({
		X = 6,
		Y = 1,
		Type = 'Label',
		Name = 'NameLabel',
		Text = ''
	})

	self:AddObject({
		X = 6,
		Y = 2,
		Type = 'Label',
		Name = 'AuthorLabel',
		Text = '',
		TextColour = 'lightGrey'
	})

	self:AddObject({
		X = 6,
		Y = 3,
		Type = 'Label',
		-- Name = 'AuthorLabel',
		Text = 'Install >',
		TextColour = 'blue',
		OnClick = function()
			if self.App then
				self.App:Install()
			end
		end
	})

	self:OnUpdate('App')
end



OnUpdate = function(self, value)
	if value == 'App' then
		self:GetObject('NameLabel').Text = self.Bedrock.Helpers.TruncateString(self.App.Name, self.Width - 6)
		self:GetObject('AuthorLabel').Text = self.Bedrock.Helpers.TruncateString(self.App.Author, self.Width - 6)
		self:GetObject('ImageView').Image = self.App.Icon
	end
end