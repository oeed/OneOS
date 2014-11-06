Inherit = 'View'
Log = nil

SaveLog = function(self)
	local str = table.concat(self.Log, '\n')
	local f = fs.open('QuestServer.log', 'w')
	if f then
		f.write(str)
		f.close()
	end
end

AddItem = function(self, str, level)
	local messageColours = {
		Info 	= colours.blue,
		Success	= colours.green,
		Warning = colours.orange,
		Error 	= colours.red,
	}
	table.insert(self.Log, str)

	local y = 1

	for i, v in ipairs(self.Children) do
		y = y + v.Height
	end

	self:AddObject({
		X = 1,
		Y = y,
		Width = "100%",
		Type = 'Label',
		Text = str,
		TextColour = messageColours[level]
	})
	
	self:SaveLog()
end

OnLoad = function(self)
	self.Log = {}
end