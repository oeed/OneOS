local _fs = fs

FS = nil
IO = nil

function Initialise(self)
	local new = {}    -- the new instance
	setmetatable( new, {__index = self} )

	new.RawFS = _fs

	new.FS = {}
	for k, v in pairs(fs) do
		new.FS[k] = new:SandboxFunction(k, v)
	end

	new.IO = io
	new.IO.open = new:SandboxFunction('open', io.open)

	new.LoadFile = function( _sFile)
		local file = new.FS.open( _sFile, "r")
		if file then
			local func, err = loadstring( file.readAll(), new.FS.getName( _sFile) )
			file.close()
			return func, err
		end
		return nil, "File not found"
	end

	new.DoFile = function( _sFile )
		local fnFile, e = new.LoadFile( _sFile )
		if fnFile then
			setfenv( fnFile, getfenv(2) )
			return fnFile()
		else
			error( e, 2 )
		end
	end

	new.LoadImage = function( sPath )
		local relPath = new.Bedrock.Helpers.RemoveFileName(path) .. sPath
		local tImage = {}
		if new.FS.exists( relPath ) then
			local file = new.IO.open(relPath, "r" )
			local sLine = file:read()
			while sLine do
				local tLine = {}
				for x=1,sLine:len() do
					tLine[x] = tColourLookup[ string.byte(sLine,x,x) ] or 0
				end
				table.insert( tImage, tLine )
				sLine = file:read()
			end
			file:close()
			return tImage
		end
		return nil
	end

	return new
end

function HandleError(self, k, v)
	if type(v) ~= 'function' then
		return v
	end
	return function(...)
		local response = {pcall(v, ...)}
		local ok = response[1]
		table.remove(response, 1)
		if ok then
			return unpack(response)
		else
			for i, err in ipairs(response) do
		    	Log.e('File System Error: ' .. k .. ': ' .. err)
				error('File System Error: ' .. k .. ': ' .. err)
			end
				
		end
	end
end

function UpdateIndex(self)
	-- self.Bedrock:StartTimer(function()
	-- 	Indexer.RefreshIndex()
	-- end, 3)
end

function SandboxFunction(self, k, v)
	local f
	if k == 'getName' or k == 'getDir' or k == 'find' or k == 'delete' then
		f = function(_path)
			return v(_path)
		end
	elseif k == 'copy' or k == 'move' then
		f = function(_path, _path2)
			self:UpdateIndex()
			return v(self:ResolveAlias(_path), self:ResolveAlias(_path2))
		end
	elseif k == 'combine' then
		f = function(_path, _path2)
			return v(_path, _path2)
		end
	elseif k == 'open' then
		f = function(_path, mode)
			if mode ~= 'r' then 
				self:UpdateIndex()
			end
			return v(self:ResolveAlias(_path), mode)
		end
	else
		f = function(_path)
			self:UpdateIndex()

			if k == 'list' then
				Log.i('list')
				Log.i(_path)
			end

			return v(self:ResolveAlias(_path))
		end
	end

	if f then
		return self:HandleError(k, f)
	end
end

AliasIdentifier = string.char(1) .. 'ALIAS' .. string.char(2)

function ResolveAlias(self, path)
	if not path or path == '/System/OneOS.log' or type(path) ~= 'string' then
		return path
	end

	if path:sub(1,1) ~= '/' then
		path = '/' .. path
	end

	local function split(a,e)
		local t,e=e or":",{}
		local t=string.format("([^%s]+)",t)
		a:gsub(t,function(t)e[#e+1]=t end)
		return e
	end

	local function tryReadAlias(_path)
		local h = _fs.open(_path, 'r')
		if h then
			local str = h.readLine()
			h.close()
			if str and str:sub(1, #self.AliasIdentifier) == self.AliasIdentifier then
				return str:sub(#self.AliasIdentifier + 1)
			end
		end
	end

	

	local tmpPath = path

	local function resolveFolders()
		-- If it exists (meaning that it's not within a 'fake' alias folder) try reading it's alias
		if _fs.exists(tmpPath) then
			return tryReadAlias(tmpPath) or tmpPath
		end

		local parts = split(tmpPath, '/')
		for i = #parts, 1, -1 do
			local _path = '/' .. table.concat(parts, '/')
			if _fs.exists(_path) then
				if _fs.isDir(_path) then
					return tmpPath
				end

				local pointer = tryReadAlias(_path)
				-- Log.i('Replace: ' .. _path .. ' With: ' .. pointer)
				tmpPath = pointer .. tmpPath:sub(#_path + 2)
				return resolveFolders()
			end
			table.remove(parts, i)
		end
		return path
	end

	tmpPath = resolveFolders()

	-- if it's not an alias just return the original path
	return tmpPath
end

function MakeAlias(self, path, pointer)
	if self.Bedrock then
		pointer = self.Bedrock.Helpers.TidyPath(pointer)
	end
	pointer = self:ResolveAlias(pointer)

	if not fs.exists(pointer) then
		return false
	end

	local h = _fs.open(path, 'w')
	if h then
		h.write(self.AliasIdentifier .. pointer)
		h.close()
		return true
	end
	return false
end