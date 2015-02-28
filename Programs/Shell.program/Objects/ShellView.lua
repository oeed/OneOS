Inherit = 'ScrollView'

CurrentPosition = 4

OnLoad = function(self)
	-- self.__index.OnLoad(self)

	self:AddObject({
		X = 2,
		Y = 2,
		Type = 'Label',
		Text = 'OneOS Shell',
		TextColour = 'blue'
	})

	self:AddObject({
		X = 14,
		Y = 2,
		Type = 'Label',
		Text = '',
		Name = 'FuckYouLabel',
		TextColour = 'lightBlue'
	})

	self:StartInput()
end

StartInput = function(self)
	self:AddObject({
		X = 2,
		Y = CurrentPosition,
		Type = 'Label',
		Text = '>',
		TextColour = 'lightBlue'
	})

	self:AddObject({
		X = 3,
		Y = CurrentPosition,
		Type = 'ShellTextBox',
		Width = '100%, -2',
		Active = true,
		OnChange = function()
		end
	})
end