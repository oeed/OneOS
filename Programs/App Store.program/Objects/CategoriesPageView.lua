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

	local y = 1
	for category, programs in pairs(categories) do
		local apps = load(programs)

		self:AddObject({
			X = 1,
			Y = y,
			Type = 'AppCollectionView',
			Width = '100%',
			Title = 'Top ' .. category .. ' Programs',
			Height = 2 + math.ceil(#apps / 2) * 4,
			Name = category .. 'AppCollectionView',
			Items = apps,
			OnSeeMore = function()
				self.Bedrock:OpenPage('CategoryPageView', {
					CategoryName = category
				})
			end
		})

		y = y + 4 + #apps * 2
	end

	self:UpdateScroll()
end

DataURL = function(self, info)
	return self.Bedrock.AppStoreURL .. 'api/?command=application&subcommand=categories'
end