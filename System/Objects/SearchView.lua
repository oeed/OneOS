Inherit = 'View'

BackgroundColour = colours.grey

OnLoad = function(self)
	local searchBox = self:AddObject({
		["X"]=2,
		["Y"]=2,
		["Width"]="100%,-2",
		["Type"]="TextBox",
		["Name"]="SearchTextBox",
		["Placeholder"]="Search...",
	})

	self:AddObject({
		["X"]=1,
		["Y"]=4,
		["Width"]="100%",
		["Height"]="100%,-3",
		["BackgroundColour"]=-1,
		["Type"]="ListView",
		["Name"]="SearchListView",
		["TextColour"]=colours.white,
		["HeadingMargin"]=1,
		["CanSelect"]=true
	})

	searchBox.OnChange = function(box, event, keychar)
		if keychar == keys.up or keychar == keys.down or keychar == keys.enter then
			self:GetObject('SearchListView'):OnKeyChar('key', keychar)
		else
			self:UpdateSearch()
		end
	end
end

local function safePairs( _t )
  local tKeys = {}
  for key in pairs(_t) do
    table.insert(tKeys, key)
  end
  local currentIndex = 0
  return function()
    currentIndex = currentIndex + 1
    local key = tKeys[currentIndex]
    return key, _t[key]
  end
end

function ItemClick(self, event, side, x, y)
	if side == 1 then
		Search.Close()
		Helpers.OpenFile(self.Path)
	elseif self:ToggleMenu('searchmenu', x, y) then
		self.Bedrock:GetObject('OpenMenuItem').OnClick = function()Search.Close() Helpers.OpenFile(self.Path)end
		self.Bedrock:GetObject('ShowInFilesMenuItem').OnClick = function()Search.Close() Helpers.OpenFile('/System/Programs/Files.program', {self.Path, true})end
	end
end

function UpdateSearch(self)
	local searchItems = {
		Folders = {},
		Documents = {},
		Images = {},
		Programs = {},
		['System Files'] = {},
		Other = {}
	}
	local paths = Indexer.Search(self:GetObject('SearchTextBox').Text)
	local foundSelected = false
	local selected = nil
	if self:GetObject('SearchListView').Selected then
		selected = self:GetObject('SearchListView').Selected.Path
	end

	for i, path in ipairs(paths) do
		local extension = self.Bedrock.Helpers.Extension(path):lower()
		if extension ~= 'shortcut' then
			path = self.Bedrock.Helpers.TidyPath(path)
			local fileType = 'Other'
			if extension == 'txt' or extension == 'text' or extension == 'license' or extension == 'md' then
				fileType = 'Documents'
			elseif extension == 'nft' or extension == 'nfp' or extension == 'skch' then
				fileType = 'Images'
			elseif extension == 'program' then
				fileType = 'Programs'
			elseif extension == 'lua' or extension == 'log' or extension == 'settings' or extension == 'version' or extension == 'hash' or extension == 'fingerprint' then
				fileType = 'System Files'
			elseif fs.isDir(path) then
				fileType = 'Folders'
			end
			if path == selected then
				Log.i('found')
				foundSelected = true
			end
			table.insert(searchItems[fileType], {Path = path, Text = self.Bedrock.Helpers.RemoveExtension(fs.getName(path)), Selected = (path == selected), OnClick = ItemClick})
		end
	end

	for k, v in safePairs(searchItems) do
		if #v == 0 then
			searchItems[k] = nil
		end
	end

	self:GetObject('SearchListView').Items = searchItems
	self:GetObject('SearchListView'):UpdateItems()
	if not foundSelected then
		local first = self:GetObject('SearchListView'):GetNth(1)
		Log.i(first)
		if first then
			self:GetObject('SearchListView'):SelectItem(first)
		end
	end
	
	--ListScrollBar.Scroll = 0

	--Draw()
end
