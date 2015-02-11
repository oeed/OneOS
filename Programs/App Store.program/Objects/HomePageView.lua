Inherit = 'PageView'

OnDataLoad = function(self, url, data)
	self:RemoveAllObjects()

	local categories = textutils.unserialize(data)

	local function load(from)
		local to = {}
		for i, v in ipairs(from) do
			local app = App:Initialise(v, self.Bedrock)
			table.insert(to, app)
		end
		return to
	end

	local topcharts = load(categories.topcharts)

	local newest = load(categories.newest)

	local featured = load(categories.featured)

	self:AddObject({
		X = 1,
		Y = 1,
		Type = 'AppCollectionView',
		Width = '100%',
		Title = 'Most Popular Apps',
		Height = 2 + math.ceil(#topcharts / 2) * 4,
		Name = 'PopularAppCollectionView',
		Items = topcharts
	})

	self:AddObject({
		X = 1,
		Y = 4 + #topcharts * 2,
		Type = 'AppCollectionView',
		Width = '100%',
		Title = 'Featured Apps',
		Height = 2 + math.ceil(#featured / 2) * 4,
		Name = 'FeaturedAppCollectionView',
		Items = featured
	})

	self:AddObject({
		X = 1,
		Y = 7 + #topcharts * 2 + #featured * 2,
		Type = 'AppCollectionView',
		Width = '100%',
		Title = 'Most Recently Added Apps',
		Height = 2 + math.ceil(#newest / 2) * 4,
		Name = 'RecentAppCollectionView',
		Items = newest
	})

	self:UpdateScroll()
end

DataURL = function(self, info)
	return self.Bedrock.AppStoreURL .. 'api/?command=application&subcommand=home'
end