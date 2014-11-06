BackgroundColour = colours.lightGrey
TextColour = colours.black
Text = 'Choose File...'
InputName = ''
FilePath = 'test'

OnInitialise = function(self, node)
	local attr = self.Attributes
	if attr.value then
		self.Text = attr.value
	end

	if attr.name then
		self.InputName = attr.name
	end

	if not attr.width then
		self.Width = #self.Text + 2
	end
end

UpdateValue = function(self, force)
	if self.FilePath then
		local f = fs.open(self.FilePath, 'r')
		if f then
			local content = f.readAll()
			self.Value = '{"name": "' .. fs.getName(self.FilePath):gsub('"', '\\"') .. '", "content": "' .. content:gsub('"', '\\"') .. '"}'
			f.close()
		end
	end
end

CreateObject = function(self, parentObject, y)
	return parentObject:AddObject({
		Element = self,
		Y = y,
		X = 1,
		Width = self.Width,
		Type = "Button",
		Text = self.Text,
		TextColour = self.TextColour,
		BackgroundColour = self.BackgroundColour,
		InputName = self.InputName,
		OnClick = function(_self, event, side, x, y)
			_self.Bedrock:DisplayOpenFileWindow(nil, function(success, path)
				if success then
					self.FilePath = path
					_self.Text = 'File: '..fs.getName(path)
					_self.Align = 'Left'
				end
			end)
		end
	})
end