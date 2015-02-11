Inherit = 'View'

App = nil

OnLoad = function(self)
	self:AddObject({
		X = 3,
		Y = 2,
		Width = 4,
		Height = 3,
		Type = 'ImageView',
	})

	self:AddObject({
		X = 8,
		Y = 2,
		Type = 'Label',
		Name = 'NameLabel',
		Text = ''
	})

	self:AddObject({
		X = 8,
		Y = 3,
		Type = 'Label',
		Name = 'AuthorLabel',
		Text = '',
		TextColour = 'lightGrey'
	})

	self:AddObject({
		X = 8,
		Y = 4,
		Type = 'Label',
		Name = 'CategoryLabel',
		Text = '',
		TextColour = 'grey'
	})

	self:AddObject({
		X = '100%,-10',
		Y = 2,
		Type = 'Button',
		Name = 'InstallButton',
		Text = 'Install',
		TextColour = 'white',
		BackgroundColour = 'blue',
		-- Visible = false
	})

	self:AddObject({
		X = 3,
		Y = 6,
		Type = 'Label',
		Text = 'Description',
		TextColour = 'lightGrey'
	})

	self:AddObject({
		X = 3,
		Y = 7,
		Width = '100%,-4',
		Type = 'Label',
		Name = 'DescriptionLabel',
		Text = 'No description',
		TextColour = 'grey'
	})

	self:AddObject({
		X = 3,
		Y = 6,
		Type = 'Label',
		Text = 'Description',
		TextColour = 'lightGrey'
	})


	self:OnUpdate('App')
end

OnUpdate = function(self, value)
	if value == 'App' and self.App then
		self:GetObject('NameLabel').Text = self.App.Name
		self:GetObject('AuthorLabel').Text = self.App.Author
		self:GetObject('CategoryLabel').Text = self.App.Category
		self:GetObject('ImageView').Path = 'Resources/'..self.App.Name
		-- self:GetObject('InstallButton').X = 10 + math.max(#self.App.Name, #self.App.Author, #self.App.Category)

		self:GetObject('DescriptionLabel').Text = self.App.Description

	end
end
