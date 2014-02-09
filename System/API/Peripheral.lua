
	GetPeripherals = function()
		local peripherals = {}
		for i, side in ipairs(peripheral.getNames()) do
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
				local isWireless = false
				if _type == 'modem' then
					isWireless = peripheral.call(side, 'isWireless')
					if isWireless then
						_type = 'wireless_modem'
						name = 'W '..name
					end
				end
				
				table.insert(peripherals, {Name = name:sub(1,8) .. ' '..code, Side = side, Type = _type, Wireless = isWireless})
			end
		end
		return peripherals
	end

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