Inherit = 'PageView'

OnDataLoad = function(self, url, data)
	self:RemoveAllObjects()

	local programs = textutils.unserialize(data)

	local function load(from)
		local to = {}
		for i, v in ipairs(from) do
			local app = App:Initialise(v, self.Bedrock)
			table.insert(to, app)
		end
		return to
	end

	local apps = load(programs)

	self:AddObject({
		X = 1,
		Y = 1,
		Type = 'AppCollectionView',
		Width = '100%',
		Title = 'All ' .. self.CategoryName .. ' Programs',
		Height = 2 + math.ceil(#apps / 2) * 4,
		Name = self.CategoryName .. 'AppCollectionView',
		Items = apps
	})

	self:UpdateScroll()
end

DataURL = function(self, info)
	return self.Bedrock.AppStoreURL .. 'api/?command=application&subcommand=category&name=' .. textutils.urlEncode(self.CategoryName)
end