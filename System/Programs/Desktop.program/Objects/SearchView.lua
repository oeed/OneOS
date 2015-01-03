Inherit = 'ScrollView'
Visible = false

OnSearch = function(self, search)
	if search == '' then
		self.Visible = false
	else
		self:BringToFront()
		self:RemoveAllObjects()
		self.Visible = true

		local paths = OneOS.Indexer.Search(search)

		local searchItems = {
			Folders = {},
			Documents = {},
			Images = {},
			Programs = {},
			['System Files'] = {},
			Other = {}
		}

		-- TODO: selected item
		for i, path in ipairs(paths) do
			local extension = self.Bedrock.Helpers.Extension(path):lower()
			if extension ~= 'shortcut' then
				path = self.Bedrock.Helpers.TidyPath(path)
				local fileType = 'Other'
				if extension == 'txt' or extension == 'text' or extension == 'license' or extension == 'md' then
					fileType = 'Documents'
				elseif extension == 'nft' or extension == 'nfp' or extension == 'skch' or extension == 'paint' then
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

				local parentFolder = fs.getName(path:sub(1, #path-#fs.getName(path)-1))
				table.insert(searchItems[fileType], {Path = path, Text = self.Bedrock.Helpers.RemoveExtension(fs.getName(path)), Selected = (path == selected), Subtext = parentFolder})
			end
		end

		local y = 2
		for name, items in pairs(searchItems) do
			if #items ~= 0 then
				self:AddObject({
					X = 2,
					Y = y,
					Type = 'FilterLabel',
					FilterName = 'Highlight',
					Text = name
				})
				y = y + 1

				self:AddObject({
					X = 1,
					Width = '100%',
					Height = #items * 4 - 1,
					Y = y,
					Type = 'View',
					BackgroundColour = colours.grey
					-- Type = 'FilterView',
					-- FilterName = 'Highlight',
				})

				for i, item in ipairs(items) do
					self:AddObject({
						X = 2,
						Y = y,
						Type = 'ImageView',
						Image = OneOS.GetIcon(item.Path),
						Width = 4,
						Height = 3
					})

					self:AddObject({
						X = 7,
						Y = y,
						Type = 'Label',
						TextColour = colours.white,
						Text = item.Text
					})

					self:AddObject({
						X = 7,
						Y = y + 1,
						Type = 'FilterLabel',
						FilterName = 'Highlight',
						Text = item.Subtext
					})
					y = y + 4
				end
			end
		end

		if y == 2 then
			self:AddObject({
				X = 1,
				Width = '100%',
				Y = 3,
				Type = 'FilterLabel',
				FilterName = 'Highlight',
				Text = 'No Files Found',
				Align = 'Center'
			})
		else
		end
	end
end

BringToFront = function(self)
	for i = #self.Bedrock.View.Children, 1, -1 do
		local child = self.Bedrock.View.Children[i]

		self.Z = child.Z + 1
		break
	end
	self.Bedrock:ReorderObjects()
end