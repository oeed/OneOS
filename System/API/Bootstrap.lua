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

local mode = '?'

-- os.run(getfenv(), 'n')
if not fs.exists('/System/.OneOS.settings') then
	mode = 'Setup'
	os.run(getfenv(), '/System/Programs/Setup.program/startup')
else
	local h = fs.open('/System/.bootargs', 'r')
	local main = true
	if h then
		local args = h.readAll()
		h.close()
		if args == 'update' then
			mode = 'Update'
			os.run(getfenv(), '/System/Programs/Update.program/startup')
			main = false
		end
	end

	if main then
		mode = 'Standard'
		os.run(getfenv(), '/System/main.lua')
	end
end

-- TODO: if not Initialise then show error (attempt to call nil below)
local _, err
if Initialise then
	_, err= pcall(Initialise)
else
	err = 'Unable to initialise (nil): ' .. mode
end

if err then
	Log.e(err)
	printError(err)

	term.setBackgroundColour(colours.grey)
	term.clear()

	term.setTextColor(colours.white)
	term.setCursorPos(2, 2)
	print('OneOS Crashed :(')

	term.setTextColor(colours.lightGrey)
	term.setCursorPos(2, 4)
	print('Sorry about that!')

	term.setTextColor(colours.white)
	term.setCursorPos(2, 6)
	print('Please inform oeed with this information:')
	print()
	term.setTextColor(colours.lightGrey)

	local h = fs.open('/System/.version', 'r')
	if h then
		print('Version: ' .. h.readAll())
		h.close()
	else
		print('Version: No .version file')
	end
	print()

	for i, v in ipairs(Log.Errors) do
		print(v)
	end

	local w, h = term.getSize()
	term.setCursorPos(1, h)
end