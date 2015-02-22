ID = nil
Author = nil
Category = nil
Name = nil
Description = nil
Icon = nil
IconRaw = nil

Bedrock = nil

local function parseNFT(lines)
	local image = {
		text = {},
		textcol = {}
	}
	for y, line in ipairs(lines) do
        table.insert(image, y, {})
        table.insert(image.text, y, {})
        table.insert(image.textcol, y, {})

		local bgNext, fgNext = false, false
		local currBG, currFG = nil,nil
		local writePosition = 1
		for x = 1, #line do

			local nextChar = string.sub(line, x, x)
            if nextChar:byte() == 30 then
                bgNext = true
            elseif nextChar:byte() == 31 then
                fgNext = true
            elseif bgNext then
                currBG = Drawing.GetColour(nextChar)
                if currBG == nil then
                	currBG = colours.transparent
                end
                bgNext = false
            elseif fgNext then
                currFG = Drawing.GetColour(nextChar)
                fgNext = false
            else
                if nextChar ~= " " and currFG == nil then
                        currFG = colours.white
                end
            	image[y][writePosition] = currBG
                image.textcol[y][writePosition] = currFG
                image.text[y][writePosition] = nextChar
                writePosition = writePosition + 1
            end
		end
	end
	return image
end

local function split(a,e)
	local t,e=e or":",{}
	local t=string.format("([^%s]+)",t)
	a:gsub(t,function(t)e[#e+1]=t end)
	return e
end

Initialise = function(self, data, bedrock)
	local new = {}    -- the new instance
	setmetatable(new, {__index = self} )

	new.ID = data.id
	new.Author = tostring(data.user.username)
	new.Category = tostring(data.category)
	new.Name = tostring(data.name)
	new.Description = tostring(data.description)
	new.Icon = parseNFT(split(data.icon, '\n'))
	new.IconRaw = data.icon

	new.Bedrock = bedrock

	return new
end

Install = function(self)
	self.Bedrock:OpenPage('InstallPageView', {
		App = self
	})
end

InstallData = function(self, data)
	if type(data) ~= 'string' or #data == 0 then
		return false, 'Empty package (Very bad!! Let oeed know!)'
	end

	local pack = JSON.decode(data)

	if not pack then
		return false, 'Corrupted package'
	end

	local _fs = fs
	if OneOS then
		_fs = OneOS.FS
	end
	local function makeFile(_path,_content)
		local file=_fs.open(_path,"w")
		if file then
			file.write(_content)
			file.close()
		else
			error(_path)
		end
	end
	local function makeFolder(_path,_content)
		_fs.makeDir(_path)
		for k,v in pairs(_content) do
			if type(v)=="table" then
				makeFolder(_path.."/"..k,v)
			else
				makeFile(_path.."/"..k,v)
			end
		end
	end

	local installPath = '/'
	local removeSpaces = true
	local alwaysFolder = false
	local fullPath = false

	if OneOS then
		if self.Category == 'Game' or self.Category == 'Games' then
			installPath = '/Programs/Games/' .. self.Name .. '.program/'
		else
			installPath = '/Programs/' .. self.Name .. '.program/'
		end
		removeSpaces = false
		alwaysFolder = true
		fullPath = true
	end

	local appName = self.Name
	local keyCount = 0
	for k, v in pairs(pack) do
		keyCount = keyCount + 1
	end
	if removeSpaces then
		appName = appName:gsub(" ", "")
	end
	local location = installPath .. '/'

	if not fullPath then
		location = location .. appName
	end
	if keyCount == 1 and not alwaysFolder then
		makeFile(location, pack['startup'])
	else
		makeFolder(location, pack)
		location = location
	end

	if OneOS then
		local h = _fs.open(location .. '/icon', 'w')
		if h then
			h.write(self.IconRaw)
			h.close()
		end
	end

	return self.Bedrock.Helpers.TidyPath(location)
end