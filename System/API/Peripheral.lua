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
				local isWireless = false
				if _type == 'modem' then
					if pcall(function()isWireless = peripheral.call(sSide, 'isWireless') end) then
						isWireless = true
					end     
					if isWireless then
						_type = 'wireless_modem'
						name = 'W '..name
					end
				end
				if not filterType or _type == filterType then
					table.insert(peripherals, {Name = name:sub(1,8) .. ' '..code, Fullname = name .. ' ('..Helpers.Capitalise(side)..')', Side = side, Type = _type, Wireless = isWireless})
				end
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