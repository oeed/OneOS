cleanEnvironment = {}
for k, v in pairs(_G) do
	cleanEnvironment[k] = v
end

local function anm(col)
	term.setBackgroundColour(col)
	term.clear()
	sleep(0.05)
end

anm(colours.black)
anm(colours.grey)
anm(colours.lightGrey)
anm(colours.white)

local function log(...)
	if Log then
		Log.i(...)
	end
	if isDebug or doLog then
		print(...)
	end
end

local function loadAPI(_sPath)
	local sName = string.gsub(fs.getName( _sPath ), "%.%w+$", "")
	log('Loading: '.._sPath)
	local tEnv = { isStartup = true }
	setmetatable( tEnv, { __index = getfenv()} )
	local fnAPI, err = loadfile( _sPath )
	if fnAPI then
		setfenv( fnAPI, tEnv )
		fnAPI()
	else
		printError( err )
		log('Error: '..err)
		return false
	end
	
	local tAPI = {}
	for k,v in pairs( tEnv ) do
		tAPI[k] =  v
	end
	
	if not tAPI then
		log('Could not find API: '..sName)
		error('Could not find API: '..sName)
	end

	getfenv()[sName] = tAPI
	return true
end

loadAPI('/System/APIs/Log.lua')
Log.Initialise()

loadAPI('/System/APIs/FileSystem.lua')
_fileSystem = FileSystem:Initialise()
fs = _fileSystem.FS
io = _fileSystem.IO
loadfile = _fileSystem.LoadFile
dofile = _fileSystem.DoFile
paintutils.loadImage = _fileSystem.LoadImage

loadAPI('/System/API/Bedrock.lua')

if type(term.native) == 'function' then
	restoreTerm = function()term.redirect(term.native())end
else
	restoreTerm = function()term.restore()end
end

-- os.run(getfenv(), 'n')
os.run(getfenv(), '/System/main.lua')

local _, err = pcall(Initialise)
-- TODO: error handling
term.setCursorPos(1, 4)
-- , function(err)
-- 	restoreTerm()
-- 	term.setCursorPos(1, 1)
-- 	error('bad stuff happended')
-- 	Log.i('errror')
-- 	ok = {false, err}
-- end)

if err then
	Log.e(err)
	printError(err)
	assert(err)
end