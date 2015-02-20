local hexnums = { [10] = "a", [11] = "b", [12] = "c", [13] = "d", [14] = "e" , [15] = "f" }
local function getHexOf(colour)
    if colour == colours.transparent or not colour or not tonumber(colour) then
        return " "
    end
    local value = math.log(colour)/math.log(2)
    if value > 9 then
            value = hexnums[value]
    end
    return value
end

local function getColourOf(hex)
	if hex == ' ' then
		return colours.transparent
	end
    local value = tonumber(hex, 16)
    if not value then return nil end
    value = math.pow(2,value)
    return value
end

function SaveSKCH(layersIn)
	local layers = {}
	for i, l in ipairs(layersIn) do
		local pixels = SaveNFT(l.Pixels)
		local layer = {
			Name = l.Name,
			Pixels = pixels,
			BackgroundColour = l.BackgroundColour,
			Visible = l.Visible,
			Index = l.Index,
			LayerType = l.LayerType
		}
		table.insert(layers, layer)
	end
	return layers
end

function SaveNFT(pixels)
	local lines = {}
	local width = #pixels
	local height = #pixels[1]
	for y = 1, height do
		local line = ''
		local currentBackgroundColour = nil
		local currentTextColour = nil
		for x = 1, width do
			local pixel = pixels[x][y]
			if pixel.BackgroundColour ~= currentBackgroundColour then
				line = line..string.char(30)..getHexOf(pixel.BackgroundColour)
				currentBackgroundColour = pixel.BackgroundColour
			end
			if pixel.TextColour ~= currentTextColour then
				line = line..string.char(31)..getHexOf(pixel.TextColour)
				currentTextColour = pixel.TextColour
			end
			line = line .. pixel.Character
		end
		table.insert(lines, line)
	end
	return lines
end

function SaveNFP(pixels)
	local lines = {}
	local width = #pixels
	local height = #pixels[1]
	for y = 1, height do
		local line = ''
		for x = 1, width do
			line = line .. getHexOf(pixels[x][y].BackgroundColour)
		end
		table.insert(lines, line)
	end
	return lines
end

function ReadNFP(path)
	local pixels = {}
	local _fs = fs
	if OneOS then
		_fs = OneOS.FS
	end
	local file = _fs.open(path, 'r')
	local line = file.readLine()
	local y = 1
	while line do
		for x = 1, #line do
			if not pixels[x] then
				pixels[x] = {}
			end
			pixels[x][y] = {BackgroundColour = getColourOf(line:sub(x,x)), TextColour = colours.black, Character = ' '}
		end
		y = y + 1
		line = file.readLine()
	end
	file.close()
	return {{Pixels = pixels}}
end

function ReadNFT(path)
	local _fs = fs
	if OneOS then
		_fs = OneOS.FS
	end
	local file = _fs.open(path, 'r')
	local line = file.readLine()
	local lines = {}
	while line do
		table.insert(lines, line)
		line = file.readLine()
	end
	file.close()
	return {{Pixels = ParseNFT(lines)}}
end

function ParseNFT(lines)
	local pixels = {}
	for y, line in ipairs(lines) do
		local bgNext, fgNext = false, false
		local currBG, currFG = nil,nil
		local writePosition = 1
		for x = 1, #line do
			if not pixels[writePosition] then
				pixels[writePosition] = {}
			end

			local nextChar = string.sub(line, x, x)
            if nextChar:byte() == 30 then
                    bgNext = true
            elseif nextChar:byte() == 31 then
                    fgNext = true
            elseif bgNext then
                    currBG = getColourOf(nextChar)
                    if currBG == nil then
                    	currBG = colours.transparent
                    end
                    bgNext = false
            elseif fgNext then
                    currFG = getColourOf(nextChar)
                    fgNext = false
            else
                    if nextChar ~= " " and currFG == nil then
                            currFG = colours.white
                    end
                    pixels[writePosition][y] = {BackgroundColour = currBG, TextColour = currFG, Character = nextChar}
                    writePosition = writePosition + 1
            end
		end
	end
	return pixels
end

function ReadSKCH(path)
	local _fs = fs
	if OneOS then
		_fs = OneOS.FS
	end
	local file = _fs.open(path, 'r')
	local _layers = textutils.unserialize(file.readAll())
	file.close()
	local layers = {}

	for i, l in ipairs(_layers) do
		local layer = {
			Name = l.Name,
			Pixels = ParseNFT(l.Pixels),
			BackgroundColour = l.BackgroundColour,
			Visible = l.Visible,
			Index = l.Index,
			LayerType = l.LayerType or 'Normal'
		}
		table.insert(layers, layer)
	end
	return layers
end

function GetFormat(path)
	local _fs = fs
	if OneOS then
		_fs = OneOS.FS
	end
	local file = _fs.open(path, 'r')
	local content = file.readAll()
	file.close()
	if type(textutils.unserialize(content)) == 'table' then
		-- It's a serlized table, assume sketch
		return '.skch'
	elseif string.find(content, string.char(30)) or string.find(content, string.char(31)) then
		-- Contains the characters that set colours, assume nft
		return '.nft'
	else
		-- Otherwise assume nfp
		return '.nfp'
	end
end

function LoadDocument(path, program)
	local _fs = fs
	if OneOS then
		_fs = OneOS.FS
	end
	if _fs.exists(path) and not _fs.isDir(path) then
		local format = program.Helpers.Extension(path, true):lower()
		if (not format or format == '') or (format ~= '.nfp' and format ~= '.nft' and format ~= '.foldericonz' and format ~= '.skch') then
			format = GetFormat(path)
			OneOS.Log.i(format)
		end
		local layers = {}
		if format == '.nfp' then
			layers = ReadNFP(path)
		elseif format == '.nft' or format == '.foldericonz' then
			layers = ReadNFT(path)		
		elseif format == '.skch' then
			layers = ReadSKCH(path)
		end

		for i, layer in ipairs(layers) do
			if layer.Visible == nil then
				layer.Visible = true
			end
			if layer.Index == nil then
				layer.Index = 1
			end
			if layer.Name == nil then
				if layer.Index == 1 then
					layer.Name = 'Background'
				else
					layer.Name = 'Layer'
				end
			end

			if layer.LayerType == nil then
				layer.LayerType = 'Normal'
			end

			if layer.BackgroundColour == nil then
				layer.BackgroundColour = colours.transparent
			end
		end

		if not layers or not layers[1] or not layers[1].Pixels then
			program:DisplayAlertWindow('File Read Failed', 'The image file appears to be corrupt, maybe it is of a unsupported format?', {'Ok'})
			return
		end

		local width = #layers[1].Pixels
		local height = #layers[1].Pixels[1]
		local _fs = fs
		if OneOS then
			_fs = OneOS.FS
		end

	    return {
			Width=width,
			Height=height,
			ImageName=_fs.getName(path),
			ImagePath=path,
			ImageFormat=format,
			Layers=layers
	    }
	end
end
