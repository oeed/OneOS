--OSInterfaceEntities--

	list = {}

	add = function(entity)
		table.insert(OSInterfaceEntities.list, entity)
	end

	remove = function(_entity)
		for i = 1, #OSInterfaceEntities.list do
			local entity = OSInterfaceEntities.list[i]
			if entity == _entity then
				--remove the entity
				OSInterfaceEntities.list[i]=nil
				OSServices.compactArray(OSInterfaceEntities.list)
			end
		end
	end