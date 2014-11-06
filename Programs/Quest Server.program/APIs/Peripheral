GetPeripheral = function(_type)
	for i, p in ipairs(GetPeripherals()) do
		if p.Type == _type then
			return p
		end
	end
end

Call = function(type, ...)
	local tArgs = {...}
	local p = GetPeripheral(type)
	peripheral.call(p.Side, unpack(tArgs))
end

local getNames = peripheral.getNames or function()
	local tResults = {}
	for n,sSide in ipairs( rs.getSides() ) do
		if peripheral.isPresent( sSide ) then
			table.insert( tResults, sSide )
			local isWireless = false
			if pcall(function()isWireless = peripheral.call(sSide, 'isWireless') end) then
				isWireless = true
			end     
			if peripheral.getType( sSide ) == "modem" and not isWireless then
				local tRemote = peripheral.call( sSide, "getNamesRemote" )
				for n,sName in ipairs( tRemote ) do
					table.insert( tResults, sName )
				end
			end
		end
	end
	return tResults
end

GetPeripherals = function(filterType)
	local peripherals = {}
	for i, side in ipairs(getNames()) do
		local name = peripheral.getType(side):gsub("^%l", string.upper)
		local code = string.upper(side:sub(1,1))
		if side:find('_') then
			code = side:sub(side:find('_')+1)
		end

		local dupe = false
		for i, v in ipairs(peripherals) do
			if v[1] == name .. ' ' .. code then
				dupe = true
			end
		end

		if not dupe then
			local _type = peripheral.getType(side)
			local formattedType = _type:sub(1, 1):upper() .. _type:sub(2, -1)
			local isWireless = false
			if _type == 'modem' then
				if not pcall(function()isWireless = peripheral.call(side, 'isWireless') end) then
					isWireless = true
				end     
				if isWireless then
					_type = 'wireless_modem'
					formattedType = 'Wireless Modem'
					name = 'W '..name
				end
			end
			if not filterType or _type == filterType then
				table.insert(peripherals, {Name = name:sub(1,8) .. ' '..code, Fullname = name .. ' ('..side:sub(1, 1):upper() .. side:sub(2, -1)..')', Side = side, Type = _type, Wireless = isWireless, FormattedType = formattedType})
			end
		end
	end
	return peripherals
end

GetSide = function(side)
	for i, p in ipairs(GetPeripherals()) do
		if p.Side == side then
			return p
		end
	end
end

PresentNamed = function(name)
	return peripheral.isPresent(name)
end

CallType = function(type, ...)
	local tArgs = {...}
	local p = GetPeripheral(type)
	return peripheral.call(p.Side, unpack(tArgs))
end

CallNamed = function(name, ...)
	local tArgs = {...}
	return peripheral.call(name, unpack(tArgs))
end

GetInfo = function(p)
	local info = {}
	local buttons = {}
	if p.Type == 'computer' then
		local id = peripheral.call(p.Side:lower(),'getID')
		if id then
			info = {
				ID = tostring(id)
			}
		else
			info = {}
		end
	elseif p.Type == 'drive' then
		local discType = 'No Disc'
		local discID = nil
		local mountPath = nil
		local discLabel = nil
		local songName = nil
		if peripheral.call(p.Side:lower(), 'isDiskPresent') then
			if peripheral.call(p.Side:lower(), 'hasData') then
				discType = 'Data'
				discID = peripheral.call(p.Side:lower(), 'getDiskID')
				if discID then
					discID = tostring(discID)
				else
					discID = 'None'
				end
				mountPath = '/'..peripheral.call(p.Side:lower(), 'getMountPath')..'/'
				discLabel = peripheral.call(p.Side:lower(), 'getDiskLabel')
			else
				discType = 'Audio'
				songName = peripheral.call(p.Side:lower(), 'getAudioTitle')
			end
		end
		if mountPath then
			table.insert(buttons, {Text = 'View Files', OnClick = function(self, event, side, x, y)GoToPath(mountPath)end})
		elseif discType == 'Audio' then
			table.insert(buttons, {Text = 'Play', OnClick = function(self, event, side, x, y)
				if self.Text == 'Play' then
					disk.playAudio(p.Side:lower())
					self.Text = 'Stop'
				else
					disk.stopAudio(p.Side:lower())
					self.Text = 'Play'
				end
			end})
		else
			diskOpenButton = nil
		end
		if discType ~= 'No Disc' then
			table.insert(buttons, {Text = 'Eject', OnClick = function(self, event, side, x, y)disk.eject(p.Side:lower()) sleep(0) RefreshFiles() end})
		end

		info = {
			['Disc Type'] = discType,
			['Disc Label'] = discLabel,
			['Song Title'] = songName,
			['Disc ID'] = discID,
			['Mount Path'] = mountPath
		}
	elseif p.Type == 'printer' then
		local pageSize = 'No Loaded Page'
		local _, err = pcall(function() return tostring(peripheral.call(p.Side:lower(), 'getPgaeSize')) end)
		if not err then
			pageSize = tostring(peripheral.call(p.Side:lower(), 'getPageSize'))
		end
		info = {
			['Paper Level'] = tostring(peripheral.call(p.Side:lower(), 'getPaperLevel')),
			['Paper Size'] = pageSize,
			['Ink Level'] = tostring(peripheral.call(p.Side:lower(), 'getInkLevel'))
		}
	elseif p.Type == 'modem' then
		info = {
			['Connected Peripherals'] = tostring(#peripheral.call(p.Side:lower(), 'getNamesRemote'))
		}
	elseif p.Type == 'monitor' then
		local w, h = peripheral.call(p.Side:lower(), 'getSize')
		local screenType = 'Black and White'
		if peripheral.call(p.Side:lower(), 'isColour') then
			screenType = 'Colour'
		end
		local buttonTitle = 'Use as Screen'
		if OneOS.Settings:GetValues()['Monitor'] == p.Side:lower() then
			buttonTitle = 'Use Computer Screen'
		end
		table.insert(buttons, {Text = buttonTitle, OnClick = function(self, event, side, x, y)
				self.Bedrock:DisplayAlertWindow('Reboot Required', "To change screen you'll need to reboot your computer.", {'Reboot', 'Cancel'}, function(value)
					if value == 'Reboot' then
						if buttonTitle == 'Use Computer Screen' then
							OneOS.Settings:SetValue('Monitor', nil)
						else
							OneOS.Settings:SetValue('Monitor', p.Side:lower())
						end
						OneOS.Reboot()
					end
				end)
			end
		})
		info = {
			['Type'] = screenType,
			['Width'] = tostring(w),
			['Height'] = tostring(h),
		}
	end
	info.Buttons = buttons
	return info
end