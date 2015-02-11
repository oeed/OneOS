Inherit = 'PageView'

OnDataLoad = function(self, url, data)
	self:RemoveAllObjects()

	local _data = textutils.unserialize(data)

	local function load(from)
		local to = {}
		for i, v in ipairs(from) do
			local app = App:Initialise(v, self.Bedrock)
			table.insert(to, app)
		end
		return to
	end

	local results = load(_data)

	self:AddObject({
		X = 1,
		Y = 1,
		Type = 'AppCollectionView',
		Width = '100%',
		Title = 'Search Results For: ' .. self.SearchTerm,
		Height = 2 + math.ceil(#results / 2) * 4,
		Name = 'SearchResultsCollectionView',
		Items = results
	})

	if #results == 0 then
		self:AddObject({
			X = 1,
			Y = '50%',
			Width = '100%',
			Align = 'Center',
			Type = 'Label',
			TextColour = 'grey',
			Text = 'No apps found'
		})
	end

	self:UpdateScroll()
end

DataURL = function(self, info)
	return self.Bedrock.AppStoreURL .. 'api/?command=application&subcommand=search&name=' .. textutils.urlEncode(self.SearchTerm)
end