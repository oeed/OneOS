	Defaults = {
		ComputerName = {
			Type = 'Text',
			Label = 'Computer Name',
			Default = 'OneOS Computer'
		},
		DesktopColour = {
			Type = 'Colour',
			Label = 'Desktop Colour',
			Default = colours.cyan,
			Controls = {}
		},
		UseAnimations = {
			Type = 'Bool',
			Label = 'Use Animations',
			Default = true,
		},
		StartupProgram = {
			Type = 'Program',
			Label = 'Startup Program',
			Default = nil,
		},
		Monitor = {
			Type = 'Side',
			Label = 'Monitor Side',
			Default = nil
		}
	}
--[[

	function WriteDefaults(self)
		local file = fs.open('/System/.OneOS.settings', 'w')
		local defaults = {}
		for k, v in pairs(self.Defaults) do
			defaults[k] = v.Default
			UpdateInterfaceForKey(k, v)
		end
		file.write(textutils.serialize(defaults))
		file.close()
	end

]]--
	function GetValues(self)
		if not fs.exists('/System/.OneOS.settings') then
			local defaults = {}
			for k, v in pairs(self.Defaults) do
				defaults[k] = v.Default
			end
			return defaults
		end

		local file = fs.open('/System/.OneOS.settings','r')
		local values = textutils.unserialize(file.readAll())
		if not values then
			local defaults = {}
			for k, v in pairs(self.Defaults) do
				defaults[k] = v.Default
			end
			return defaults
		end
		
		for k, v in pairs(self.Defaults) do
			if values[k] == nil then
				values[k] = v.Default
			end
		end
		file.close()
		return values
	end

	function UpdateInterfaceForKey(key, value)
		if key == 'DesktopColour' then
			if Desktop then
				Desktop.RefreshFiles()
			end
		elseif key == 'ComputerName' then
			os.setComputerLabel(value)
		end
	end

	function SetValue(self, key, value)
		local currentValues = self:GetValues()
		currentValues[key] = value
		local file = fs.open('/System/.OneOS.settings', 'w')
		file.write(textutils.serialize(currentValues))
		file.close()
		UpdateInterfaceForKey(key, value)
	end