Inherit = 'SnapWindow'
ContentViewName = 'filterswindow'

Title = 'Filters'

OnContentLoad = function(self)
	self:GetObject('ScrollView'):UpdateScroll()
end