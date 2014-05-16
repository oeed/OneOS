--how often the computer is indexed
IndexRate = 60

--fs api calls will cause an index 3 seconds after they are run
FSIndexRate = 3

Index = {}

function AddToIndex(path, index)
	if string.sub(fs.getName(path),1,1) == '.' or string.sub(path,1,string.len("rom"))=="rom" or string.sub(path,1,string.len("/rom"))=="/rom" then
		if fs.getName(path) == '.DS_Store' then
			fs.delete(path)
		end
		return index
	elseif fs.isDir(path) then
		index[fs.getName(path)] = {}
		for i, fileName in ipairs(fs.list(path)) do
			index[fs.getName(path)] = AddToIndex(path .. '/' .. fileName, index[fs.getName(path)])
		end
	else
		index[fs.getName(path)] = true
	end
	return index
end

function RefreshIndex()
	local index = AddToIndex('', {})
	if index['root'] then
		Index = index['root']
	end
	Current.IconCache = {}
	_G.indexTimer = os.startTimer(Indexer.IndexRate)
	if Current.CanDraw then
		Current.DidIndex = true
		Overlay.UpdateButtons()
		MainDraw()
		Current.DidIndexTimer = os.startTimer(1)
	end
end

function Search(filter, items, index, indexName)
	if filter == '' then
		return {}
	end
	items = items or {}
	index = index or Index
	indexName = indexName or ''
	term.setTextColour(colours.black)
	--print('searching '..indexName)
	--sleep(1)
	for name, _file in pairs(index) do
		if not (name == 'rom' and indexName == '') and not (name == 'System' and indexName == '') and not (name == 'startup' and indexName == '') then
			local _path = indexName..'/'..name
			if name == 'root' then
				_path = '/'
			end
			if type(_file) == 'table' and Helpers.Extension(name) ~= 'program' then
				items = Search(filter, items, index[name], _path)
			end
			if string.find(name:lower(), filter:lower()) ~= nil then
				table.insert(items, _path)
			end
		end
	end
	return items
end

--finds a file with the given name in a folder with the given name
--used to find icon files
function FindFileInFolder(file, folder, index, indexName)
	index = index or Index
	for name, _file in pairs(index) do
		if type(_file) == 'table' then
			local _name = FindFileInFolder(file, folder, index[name], name)
			if _name and name ~= 'root' then
				return name .. '/' .. _name
			elseif _name then
				return _name
			end
		elseif name == file and indexName == folder then
			return name
		end
	end
end