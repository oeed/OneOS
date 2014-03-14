--OSFileSystem--

	HomePath = "/Home/"
	SystemPath = "/System/"

	isDirectory = function(path) --return true if the path given is a folder (directory)
		--if a directory has an extension (e.g. '.app') it is not considered a directory
		return fs.isDir(path) and not OSFileSystem.hasExtention(path)
	end
		
	exists = function(path)
		return fs.exists(path)
	end
		
	list = function(path) --list, but filter out hidden items
		local t = {}
		for _,v in ipairs(fs.list(path)) do
			if not OSFileSystem.isHidden(path..v) then
				table.insert(t, v)
			end
		end
		return t
	end
		
	isReadOnly = function(path)
		return fs.isReadOnly(path)
	end
		
	isHidden = function(path)
		return string.sub(OSFileSystem.getName(path),1,string.len(1)) == "."
	end
		
	hasExtention = function(path)
		return string.find(OSFileSystem.getName(path), "%.")
	end
		
	getName = function(path)
		return fs.getName(path)
	end
		
	getSize = function(path)
		return fs.getSize(path)
	end
		
	copy = function(path)
		return fs.copy(path)
	end
		
	move = function(path)
		return fs.move(path)
	end
		
	delete = function(path)
		return fs.delete(path)
	end
		
	merge = function(path)
		return fs.combine(path)
	end
		
	extension = function(path) --get the file extension of a path (e.g. '/System/Applications/Finder.app' to '.app')
		return string.match(path, "([^%.]+)$")
	end
		
	shortName = function(path) --gets the file name with out the extension (e.g. above becomes 'Finder')
		--if you know a better way to do this, please suggest a way
		local str = OSFileSystem.getName(path)
		if string.find(str, "%.") then
			str = string.match(str, ".-%.")
			str = string.sub(str, 0,  #str - 1)
		end
		return str
	end
		
	openFile = function(path)
		local ext = OSFileSystem.extension(path)
		if ext == "app" then
			local app = OSApplication:load(path)
			OSApplication.run(app)
		else
			--get the application that uses the extension
			if OSExtensionAssociations.list[ext] then
				local appPath = OSExtensionAssociations.list[ext]
				local app = OSApplication:load(appPath)
				local _app = OSApplication.run(app)
				--open the file
				_app.environment.openFile(path)
			end			
		end
	end