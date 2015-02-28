--Bedrock Build: 572
--This code is squished down in to one, rather hard to read file.
--As such it is not much good for anything other than being loaded as an API.
--If you want to look at the code to learn from it, copy parts or just take a look,
--you should go to the GitHub repo. http://github.com/oeed/Bedrock/

--
--		Bedrock is the core program framework used by all OneOS and OneCode programs.
--							Inspired by Apple's Cocoa framework.
--									   (c) oeed 2014
--
--		  For documentation see the Bedrock wiki, github.com/oeed/Bedrock/wiki/
--

local apis = {
["Communicate"] = [[
Channel = 42000
Callbacks = {}
CallbackTimeouts = {}
MessageTimeout = 0.5
MessageTypeHandlers = {}

local getNames = peripheral.getNames or function()
    local tResults = {}
    for n,sSide in ipairs( rs.getSides() ) do
            if peripheral.isPresent( sSide ) then
                    table.insert( tResults, sSide )
                    local isWireless = false
                    if pcall(function()isWireless = peripheral.call(sSide, 'isWireless') end) then
                            isWireless = true
                    end     
                    if peripheral.getType( sSide ) == "modem" and not isWireless then
                            local tRemote = peripheral.call( sSide, "getNamesRemote" )
                            for n,sName in ipairs( tRemote ) do
                                    table.insert( tResults, sName )
                            end
                    end
            end
    end
    return tResults
end

GetModems = function(self, callback)
    local ok = false
    for i, name in ipairs(getNames()) do
            ok = true
            if callback then
                    local p = peripheral.wrap(name)
                    callback(p, name)
            end
    end
    return ok
end

Initialise = function(self, bedrock)
    local new = {}
    setmetatable(new, {__index = self})
    new.Bedrock = bedrock
    new.Bedrock:RegisterEvent('modem_message', function(_, event, name, channel, replyChannel, message, distance)
            new:OnMessage(event, name, channel, replyChannel, message, distance)
    end)
    if new:GetModems(function(modem, name)
                    modem.open(new.Channel)
            end)
    then
            return new
    end
    return false
end

RegisterMessageType = function(self, msgType, callback)
    self.MessageTypeHandlers[msgType] = callback
end

OnMessage = function(self, event, name, channel, replyChannel, message, distance)
    if channel == self.Channel and type(message) == 'table' and message.msgType and message.thread and message.id ~= os.getComputerID() then
            if self.Callbacks[message.thread] then
                    local response, callback = self.Callbacks[message.thread](message.content, message, distance)
                    if response ~= nil then
                            self:Reply(response, message, callback)
                    end
            elseif self.MessageTypeHandlers[message.msgType] then
                    local response = self.MessageTypeHandlers[message.msgType](message, message.msgType, message.content, distance)
                    if response ~= nil then
                            self:Reply(response, message)
                    end
            else
            end
            return true
    else
            return false
    end
end

Reply = function(self, content, message, callback)
    self:SendMessage(message.msgType, content, callback, message.thread)
end

SendMessage = function(self, msgType, content, callback, thread, multiple)
    thread = thread or tostring(math.random())
    if self:GetModems(function(modem, name)
                    modem.transmit(self.Channel, self.Channel, {msgType = msgType, content = content, thread = thread, id = os.getComputerID()})
            end)
    then
            if callback then
                    self.Callbacks[thread] = function(...)
                            if not multiple then
                                    self.Callbacks[thread] = nil
                                    self.CallbackTimeouts[thread] = nil
                            end
                            return callback(...), callback
                    end
                    self.CallbackTimeouts[thread] = self.Bedrock:StartTimer(function(_, timer)
                            if timer == self.CallbackTimeouts[thread] then
                                    callback(false)
                            end
                    end, self.MessageTimeout)
            end
            return true
    end
    return false
end
]],
["Drawing"] = [[
local round = function(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

local _w, _h = term.getSize()
local copyBuffer = nil

Screen = {
	Width = _w,
	Height = _h
}

Constraints = {
	
}

CurrentConstraint = {1,1,_w,_h}
IgnoreConstraint = false

function AddConstraint(x, y, width, height)
	local x2 = x + width - 1
	local y2 = y + height - 1
	table.insert(Drawing.Constraints, {x, y, x2, y2})
	Drawing.GetConstraint()
end

function RemoveConstraint()
	--table.remove(Drawing.Constraints, #Drawing.Constraints)
	Drawing.Constraints[#Drawing.Constraints] = nil
	Drawing.GetConstraint()
end

function GetConstraint()
	local x = 1
	local y = 1
	local x2 = Drawing.Screen.Width
	local y2 = Drawing.Screen.Height
	for i, c in ipairs(Drawing.Constraints) do
		if x < c[1] then
			x = c[1]
		end
		if y < c[2] then
			y = c[2]
		end
		if x2 > c[3] then
			x2 = c[3]
		end
		if y2 > c[4] then
			y2 = c[4]
		end
	end
	Drawing.CurrentConstraint = {x, y, x2, y2}
end

function WithinContraint(x, y)
	return Drawing.IgnoreConstraint or
		  (x >= Drawing.CurrentConstraint[1] and
		   y >= Drawing.CurrentConstraint[2] and
		   x <= Drawing.CurrentConstraint[3] and
		   y <= Drawing.CurrentConstraint[4])
end

colours.transparent = 0
colors.transparent = 0

Filters = {
	None = {
		[colours.white] = colours.white,
		[colours.orange] = colours.orange,
		[colours.magenta] = colours.magenta,
		[colours.lightBlue] = colours.lightBlue,
		[colours.yellow] = colours.yellow,
		[colours.lime] = colours.lime,
		[colours.pink] = colours.pink,
		[colours.grey] = colours.grey,
		[colours.lightGrey] = colours.lightGrey,
		[colours.cyan] = colours.cyan,
		[colours.purple] = colours.purple,
		[colours.blue] = colours.blue,
		[colours.brown] = colours.brown,
		[colours.green] = colours.green,
		[colours.red] = colours.red,
		[colours.black] = colours.black,
		[colours.transparent] = colours.transparent,
	},

	Greyscale = {
		[colours.white] = colours.white,
		[colours.orange] = colours.lightGrey,
		[colours.magenta] = colours.lightGrey,
		[colours.lightBlue] = colours.lightGrey,
		[colours.yellow] = colours.lightGrey,
		[colours.lime] = colours.lightGrey,
		[colours.pink] = colours.lightGrey,
		[colours.grey] = colours.grey,
		[colours.lightGrey] = colours.lightGrey,
		[colours.cyan] = colours.grey,
		[colours.purple] = colours.grey,
		[colours.blue] = colours.grey,
		[colours.brown] = colours.grey,
		[colours.green] = colours.grey,
		[colours.red] = colours.grey,
		[colours.black] = colours.black,
		[colours.transparent] = colours.transparent,
	},

	BlackWhite = {
		[colours.white] = colours.white,
		[colours.orange] = colours.white,
		[colours.magenta] = colours.white,
		[colours.lightBlue] = colours.white,
		[colours.yellow] = colours.white,
		[colours.lime] = colours.white,
		[colours.pink] = colours.white,
		[colours.grey] = colours.black,
		[colours.lightGrey] = colours.white,
		[colours.cyan] = colours.black,
		[colours.purple] = colours.black,
		[colours.blue] = colours.black,
		[colours.brown] = colours.black,
		[colours.green] = colours.black,
		[colours.red] = colours.black,
		[colours.black] = colours.black,
		[colours.transparent] = colours.transparent,
	},

	Darker = {
		[colours.white] = colours.lightGrey,
		[colours.orange] = colours.red,
		[colours.magenta] = colours.purple,
		[colours.lightBlue] = colours.cyan,
		[colours.yellow] = colours.orange,
		[colours.lime] = colours.green,
		[colours.pink] = colours.magenta,
		[colours.grey] = colours.black,
		[colours.lightGrey] = colours.grey,
		[colours.cyan] = colours.blue,
		[colours.purple] = colours.grey,
		[colours.blue] = colours.grey,
		[colours.brown] = colours.grey,
		[colours.green] = colours.grey,
		[colours.red] = colours.brown,
		[colours.black] = colours.black,
		[colours.transparent] = colours.transparent,
	},

	Lighter = {
		[colours.white] = colours.lightGrey,
		[colours.orange] = colours.yellow,
		[colours.magenta] = colours.pink,
		[colours.lightBlue] = colours.cyan,
		[colours.yellow] = colours.orange,
		[colours.lime] = colours.green,
		[colours.pink] = colours.magenta,
		[colours.grey] = colours.lightGrey,
		[colours.lightGrey] = colours.grey,
		[colours.cyan] = colours.lightBlue,
		[colours.purple] = colours.magenta,
		[colours.blue] = colours.lightBlue,
		[colours.brown] = colours.red,
		[colours.green] = colours.lime,
		[colours.red] = colours.orange,
		[colours.black] = colours.grey,
		[colours.transparent] = colours.transparent,
	},

	Highlight = {
		[colours.white] = colours.lightGrey,
		[colours.orange] = colours.yellow,
		[colours.magenta] = colours.pink,
		[colours.lightBlue] = colours.cyan,
		[colours.yellow] = colours.orange,
		[colours.lime] = colours.green,
		[colours.pink] = colours.magenta,
		[colours.grey] = colours.lightGrey,
		[colours.lightGrey] = colours.grey,
		[colours.cyan] = colours.lightBlue,
		[colours.purple] = colours.magenta,
		[colours.blue] = colours.lightBlue,
		[colours.brown] = colours.red,
		[colours.green] = colours.lime,
		[colours.red] = colours.orange,
		[colours.black] = colours.grey,
		[colours.transparent] = colours.transparent,
	},

	Invert = {
		[colours.white] = colours.black,
		[colours.orange] = colours.blue,
		[colours.magenta] = colours.green,
		[colours.lightBlue] = colours.brown,
		[colours.yellow] = colours.blue,
		[colours.lime] = colours.purple,
		[colours.pink] = colours.green,
		[colours.grey] = colours.lightGrey,
		[colours.lightGrey] = colours.grey,
		[colours.cyan] = colours.red,
		[colours.purple] = colours.green,
		[colours.blue] = colours.yellow,
		[colours.brown] = colours.lightBlue,
		[colours.green] = colours.purple,
		[colours.red] = colours.cyan,
		[colours.black] = colours.white,
		[colours.transparent] = colours.transparent,
	},
}

function FilterColour(colour, filter)
	if filter[colour] then
		return filter[colour]
	else
		return colour
	end
end

DrawCharacters = function (x, y, characters, textColour, bgColour)
	Drawing.WriteStringToBuffer(x, y, tostring(characters), textColour, bgColour)
end

DrawBlankArea = function (x, y, w, h, colour)
	if colour ~= colours.transparent then
		Drawing.DrawArea (x, y, w, h, " ", 1, colour)
	end
end

DrawArea = function (x, y, w, h, character, textColour, bgColour)
	--width must be greater than 1, otherwise we get problems
	if w < 0 then
		w = w * -1
	elseif w == 0 then
		w = 1
	end

	for ix = 1, w do
		local currX = x + ix - 1
		for iy = 1, h do
			local currY = y + iy - 1
			Drawing.WriteToBuffer(currX, currY, character, textColour, bgColour)
		end
	end
end

DrawImage = function(_x,_y,tImage, w, h)
	if tImage then
		for y = 1, h do
			if not tImage[y] then
				break
			end
			for x = 1, w do
				if not tImage[y][x] then
					break
				end
				local bgColour = tImage[y][x]
	            local textColour = tImage.textcol[y][x] or colours.white
	            local char = tImage.text[y][x]
	            Drawing.WriteToBuffer(x+_x-1, y+_y-1, char, textColour, bgColour)
			end
		end
	elseif w and h then
		Drawing.DrawBlankArea(_x, _y, w, h, colours.lightGrey)
	end
end

--using .nft
LoadImage = function(path, global)
	local image = {
		text = {},
		textcol = {}
	}
	if fs.exists(path) then
		local _io = io
		if OneOS and global then
			_io = OneOS.IO
		end
        local file = _io.open(path, "r")
        if not file then
        	error('Error Occured. _io:'..tostring(_io)..' OneOS: '..tostring(OneOS)..' OneOS.IO'..tostring(OneOS.IO)..' io: '..tostring(io))
        end
        local sLine = file:read()
        local num = 1
        while sLine do  
            table.insert(image, num, {})
            table.insert(image.text, num, {})
            table.insert(image.textcol, num, {})
                                        
            --As we're no longer 1-1, we keep track of what index to write to
            local writeIndex = 1
            --Tells us if we've hit a 30 or 31 (BG and FG respectively)- next char specifies the curr colour
            local bgNext, fgNext = false, false
            --The current background and foreground colours
            local currBG, currFG = nil,nil
            for i=1,#sLine do
                    local nextChar = string.sub(sLine, i, i)
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
		                    if currFG == nil or currFG == colours.transparent then
		                    	currFG = colours.white
		                    end
                            fgNext = false
                    else
                            if nextChar ~= " " and currFG == nil then
                                    currFG = colours.white
                            end
                            image[num][writeIndex] = currBG
                            image.textcol[num][writeIndex] = currFG
                            image.text[num][writeIndex] = nextChar
                            writeIndex = writeIndex + 1
                    end
            end
            num = num+1
            sLine = file:read()
        end
        file:close()
    else
    	return nil
	end
 	return image
end

DrawCharactersCenter = function(x, y, w, h, characters, textColour,bgColour)
	w = w or Drawing.Screen.Width
	h = h or Drawing.Screen.Height
	x = x or 0
	y = y or 0
	x = math.floor((w - #characters) / 2) + x
	y = math.floor(h / 2) + y

	Drawing.DrawCharacters(x, y, characters, textColour, bgColour)
end

GetColour = function(hex)
	if hex == ' ' then
		return colours.transparent
	end
    local value = tonumber(hex, 16)
    if not value then return nil end
    value = math.pow(2,value)
    return value
end

Clear = function (_colour)
	_colour = _colour or colours.black
	Drawing.DrawBlankArea(1, 1, Drawing.Screen.Width, Drawing.Screen.Height, _colour)
end

Buffer = {}
BackBuffer = {}

TryRestore = false


--TODO: make this quicker
-- maybe sort the pixels in order of colour so it doesn't have to set the colour each time
DrawBuffer = function()
	if TryRestore and Restore then
		Restore()
	end

	-- If the program is within OneOS pass our buffer straight to the OS to draw rather than fidling around with the term API

	if OneOS and OneOS.Buffer then
		Drawing.Buffer = OneOS.Buffer
	else
		for y,row in pairs(Drawing.Buffer) do
			for x,pixel in pairs(row) do
				local shouldDraw = true
				local hasBackBuffer = true
				if Drawing.BackBuffer[y] == nil or Drawing.BackBuffer[y][x] == nil or #Drawing.BackBuffer[y][x] ~= 3 then
					hasBackBuffer = false
				end
				if hasBackBuffer and Drawing.BackBuffer[y][x][1] == Drawing.Buffer[y][x][1] and Drawing.BackBuffer[y][x][2] == Drawing.Buffer[y][x][2] and Drawing.BackBuffer[y][x][3] == Drawing.Buffer[y][x][3] then
					shouldDraw = false
				end
				if shouldDraw then
					term.setBackgroundColour(pixel[3])
					term.setTextColour(pixel[2])
					term.setCursorPos(x, y)
					term.write(pixel[1])
				end
			end
		end
	end
	Drawing.BackBuffer = Drawing.Buffer
	Drawing.Buffer = {}
end

ClearBuffer = function()
	Drawing.Buffer = {}
end

WriteStringToBuffer = function (x, y, characters, textColour,bgColour)
	for i = 1, #characters do
		local character = characters:sub(i,i)
		Drawing.WriteToBuffer(x + i - 1, y, character, textColour, bgColour)
	end
end

WriteToBuffer = function(x, y, character, textColour,bgColour, cached)
	if not cached and not Drawing.WithinContraint(x, y) then
		return
	end
	x = round(x)
	y = round(y)

	if textColour == colours.transparent then
		character = ' '
	end

	if bgColour == colours.transparent then
		Drawing.Buffer[y] = Drawing.Buffer[y] or {}
		Drawing.Buffer[y][x] = Drawing.Buffer[y][x] or {"", colours.white, colours.black}
		Drawing.Buffer[y][x][1] = character
		Drawing.Buffer[y][x][2] = textColour
	else
		Drawing.Buffer[y] = Drawing.Buffer[y] or {}
		Drawing.Buffer[y][x] = {character, textColour, bgColour}
	end

	if copyBuffer then
		copyBuffer[y] = copyBuffer[y] or {}
		copyBuffer[y][x] = {character, textColour, bgColour}		
	end
end

DrawCachedBuffer = function(buffer)
	for y, row in pairs(buffer) do
		for x, pixel in pairs(row) do
			WriteToBuffer(x, y, pixel[1], pixel[2], pixel[3], true)
		end
	end
end

StartCopyBuffer = function()
	copyBuffer = {}
end

EndCopyBuffer = function()
	local tmpCopy = copyBuffer
	copyBuffer = nil
	return tmpCopy
end
]],
["Helpers"] = [[
LongestString = function(input, key, isKey)
	local length = 0
	if isKey then
		for k, v in pairs(input) do
			local titleLength = string.len(k)
			if titleLength > length then
				length = titleLength
			end
		end
	else
		for i = 1, #input do
			local value = input[i]
			if key then
				if value[key] then
					value = value[key]
				else
					value = ''
				end
			end
			local titleLength = string.len(value)
			if titleLength > length then
				length = titleLength
			end
		end
	end
	return length
end

Split = function(a,e)
	local t,e=e or":",{}
	local t=string.format("([^%s]+)",t)
	a:gsub(t,function(t)e[#e+1]=t end)
	return e
end

Extension = function(path, addDot)
	if not path then
		return nil
	elseif not string.find(fs.getName(path), '%.') then
		return ''
	else
		local _path = path
		if path:sub(#path) == '/' then
			_path = path:sub(1,#path-1)
		end

		local extension = _path:gmatch('%.[0-9a-z]+$')()
		if extension then
			extension = extension:sub(2)
		elseif fs.getName(_path):sub(1,1) == '.' then
			extension = fs.getName(_path):sub(2)
		else
			return ''
		end
		
		if addDot then
			extension = '.'..extension
		end
		return extension:lower()
	end
end

RemoveExtension = function(path)
--local name = string.match(fs.getName(path), '(%a+)%.?.-')
	if not path:find('%.') then
		return path
	end
	local extension = Helpers.Extension(path)
	if extension == path then
		return fs.getName(path)
	end
	return string.gsub(path, extension, ''):sub(1, -2)
end

RemoveFileName = function(path)
	if string.sub(path, -1) == '/' then
		path = string.sub(path, 1, -2)
	end
	local v = string.match(path, "(.-)([^\\/]-%.?([^%.\\/]*))$")
	if type(v) == 'string' then
		return v
	end
	return v[1]
end

ParentFolder = function(path)
	local folderName = fs.getName(path)
	return path:sub(1, #path-#folderName-1)
end

TruncateString = function(sString, maxLength)
	if #sString > maxLength then
		sString = sString:sub(1,maxLength-3)
		if sString:sub(-1) == ' ' then
			sString = sString:sub(1,maxLength-4)
		end
		sString = sString  .. '...'
	end
	return sString
end

TruncateStringStart = function(sString, maxLength)
	local len = #sString
	if #sString > maxLength then
		sString = sString:sub(len - maxLength, len - 3)
		if sString:sub(-1) == ' ' then
			sString = sString:sub(len - maxLength, len - 4)
		end
		sString = '...' .. sString
	end
	return sString
end

WrapText = function(text, maxWidth)
	local lines = {''}
    for word, space in text:gmatch('(%S+)(%s*)') do
            local temp = lines[#lines] .. word .. space:gsub('\n','')
            if #temp > maxWidth then
                    table.insert(lines, '')
            end
            if space:find('\n') then
                    lines[#lines] = lines[#lines] .. word
                    
                    space = space:gsub('\n', function()
                            table.insert(lines, '')
                            return ''
                    end)
            else
                    lines[#lines] = lines[#lines] .. word .. space
            end
    end
    if #lines[1] == 0 then
        table.remove(lines,1)
    end
	return lines
end

TidyPath = function(path)
	path = '/'..path
	if fs.exists(path) and fs.isDir(path) or (OneOS and OneOS.FS.exists(path) and OneOS.FS.isDir(path)) then
		path = path .. '/'
	end

	path, n = path:gsub("//", "/")
	while n > 0 do
		path, n = path:gsub("//", "/")
	end
	return path
end

Capitalise = function(str)
	return str:sub(1, 1):upper() .. str:sub(2, -1)
end

Round = function(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end
]],
["Object"] = [[
X = 1
Y = 1
Width = 1
Height = 1
Parent = nil
OnClick = nil
Visible = true
IgnoreClick = false
Name = nil 
ClipDrawing = true
UpdateDrawBlacklist = {}
Fixed = false
Ready = false

DrawCache = {}

NeedsDraw = function(self)
	if not self.Visible then
		return false
	end
	
	if not self.DrawCache.Buffer or self.DrawCache.AlwaysDraw or self.DrawCache.NeedsDraw then
		return true
	end

	if self.OnNeedsUpdate then
		if self.OnNeedsUpdate() then
			return true
		end
	end

	if self.Children then
		for i, v in ipairs(self.Children) do
			if v:NeedsDraw() then
				return true
			end
		end
	end
end

GetPosition = function(self)
	return self.Bedrock:GetAbsolutePosition(self)
end

GetOffsetPosition = function(self)
	if not self.Parent then
		return {X = 1, Y = 1}
	end

	local offset = {X = 0, Y = 0}
	if not self.Fixed and self.Parent.ChildOffset then
		offset = self.Parent.ChildOffset
	end

	return {X = self.X + offset.X, Y = self.Y + offset.Y}
end

Draw = function(self)
	if not self.Visible then
		return
	end

	self.DrawCache.NeedsDraw = false
	local pos = self:GetPosition()
	Drawing.StartCopyBuffer()

	if self.ClipDrawing then
		Drawing.AddConstraint(pos.X, pos.Y, self.Width, self.Height)
	end

	if self.OnDraw then
		self:OnDraw(pos.X, pos.Y)
	end

	self.DrawCache.Buffer = Drawing.EndCopyBuffer()
	
	if self.Children then
		for i, child in ipairs(self.Children) do
			local pos = child:GetOffsetPosition()
			if pos.Y + self.Height > 1 and pos.Y <= self.Height and pos.X + self.Width > 1 and pos.X <= self.Width then
				child:Draw()
			end
		end
	end


	if self.OnPostChildrenDraw then
		self:OnPostChildrenDraw(pos.X, pos.Y)
	end

	if self.ClipDrawing then
		Drawing.RemoveConstraint()
	end	
end

ForceDraw = function(self, ignoreChildren, ignoreParent, ignoreBedrock)
	if not ignoreBedrock and self.Bedrock then
		self.Bedrock:ForceDraw()
	end
	self.DrawCache.NeedsDraw = true
	if not ignoreParent and self.Parent then
		self.Parent:ForceDraw(true, nil, true)
	end
	if not ignoreChildren and self.Children then
		for i, child in ipairs(self.Children) do
			child:ForceDraw(nil, true, true)
		end
	end
end

OnRemove = function(self)
	if self == self.Bedrock:GetActiveObject() then
		self.Bedrock:SetActiveObject()
	end
end

local function ParseColour(value)
	if type(value) == 'string' then
		if colours[value] and type(colours[value]) == 'number' then
			return colours[value]
		elseif colors[value] and type(colors[value]) == 'number' then
			return colors[value]
		end
	elseif type(value) == 'number' and (value == colours.transparent or (value >= colours.white and value <= colours.black)) then
		return value
	end
	error('Invalid colour: "'..tostring(value)..'"')
end

Initialise = function(self, values)
	local _new = values    -- the new instance
	_new.DrawCache = {
		NeedsDraw = true,
		AlwaysDraw = false,
		Buffer = nil
	}
	setmetatable(_new, {__index = self} )

	local new = {} -- the proxy
	setmetatable(new, {
		__index = function(t, k)
			if k:find('Color') then
				k = k:gsub('Color', 'Colour')
			end

			if k:find('Colour') and type(_new[k]) ~= 'table' and type(_new[k]) ~= 'function' then
				if _new[k] then
					return ParseColour(_new[k])
				end
			elseif _new[k] ~= nil then
				return _new[k]
			end
		end,

		__newindex = function (t,k,v)
			if k:find('Color') then
				k = k:gsub('Color', 'Colour')
			end

			if k == 'Width' or k == 'X' or k == 'Height' or k == 'Y' then
				v = new.Bedrock:ParseStringSize(new.Parent, k, v)
			end

			if v ~= _new[k] then
				_new[k] = v
				if t.OnUpdate then
					t:OnUpdate(k)
				end

				if t.UpdateDrawBlacklist[k] == nil then
					t:ForceDraw()
				end
			end
		end
	})
	if new.OnInitialise then
		new:OnInitialise()
	end

	return new
end

AnimateValue = function(self, valueName, from, to, duration, done, tbl)
	tbl = tbl or self
	if type(tbl[valueName]) ~= 'number' then
		error('Animated value ('..valueName..') must be number.')
	elseif not self.Bedrock.AnimationEnabled then
		tbl[valueName] = to
		if done then
			done()
		end
		return
	end
	from = from or tbl[valueName]
	duration = duration or 0.2
	local delta = to - from

	local startTime = os.clock()
	local previousFrame = startTime
	local frame
	frame = function()
		local time = os.clock()
		local totalTime = time - startTime
		local isLast = totalTime >= duration

		if isLast then
			tbl[valueName] = to
			self:ForceDraw()
			if done then
				done()
			end
		else
			tbl[valueName] = self.Bedrock.Helpers.Round(from + delta * (totalTime / duration))
			self:ForceDraw()
			self.Bedrock:StartTimer(function()
				frame()
			end, 0.05)
		end
	end
	frame()
end

Click = function(self, event, side, x, y)
	if self.Visible and not self.IgnoreClick then
		if event == 'mouse_click' and self.OnClick and self:OnClick(event, side, x, y) ~= false then
			return true
		elseif event == 'mouse_drag' and self.OnDrag and self:OnDrag(event, side, x, y) ~= false then
			return true
		elseif event == 'mouse_scroll' and self.OnScroll and self:OnScroll(event, side, x, y) ~= false then
			return true
		else
			return false
		end
	else
		return false
	end

end

ToggleMenu = function(self, name, x, y)
	return self.Bedrock:ToggleMenu(name, self, x, y)
end

function OnUpdate(self, value)
	if value == 'Z' then
		self.Bedrock:ReorderObjects()
	end
end
]],
["Peripheral"] = [[
GetPeripheral = function(_type)
	for i, p in ipairs(GetPeripherals()) do
		if p.Type == _type then
			return p
		end
	end
end

Call = function(type, ...)
	local tArgs = {...}
	local p = GetPeripheral(type)
	peripheral.call(p.Side, unpack(tArgs))
end

local getNames = peripheral.getNames or function()
	local tResults = {}
	for n,sSide in ipairs( rs.getSides() ) do
		if peripheral.isPresent( sSide ) then
			table.insert( tResults, sSide )
			local isWireless = false
			if pcall(function()isWireless = peripheral.call(sSide, 'isWireless') end) then
				isWireless = true
			end     
			if peripheral.getType( sSide ) == "modem" and not isWireless then
				local tRemote = peripheral.call( sSide, "getNamesRemote" )
				for n,sName in ipairs( tRemote ) do
					table.insert( tResults, sName )
				end
			end
		end
	end
	return tResults
end

GetPeripherals = function(filterType)
	local peripherals = {}
	for i, side in ipairs(getNames()) do
		local name = peripheral.getType(side):gsub("^%l", string.upper)
		local code = string.upper(side:sub(1,1))
		if side:find('_') then
			code = side:sub(side:find('_')+1)
		end

		local dupe = false
		for i, v in ipairs(peripherals) do
			if v[1] == name .. ' ' .. code then
				dupe = true
			end
		end

		if not dupe then
			local _type = peripheral.getType(side)
			local formattedType = _type:sub(1, 1):upper() .. _type:sub(2, -1)
			local isWireless = false
			if _type == 'modem' then
				if not pcall(function()isWireless = peripheral.call(side, 'isWireless') end) then
					isWireless = true
				end     
				if isWireless then
					_type = 'wireless_modem'
					formattedType = 'Wireless Modem'
					name = 'W '..name
				end
			end
			if not filterType or _type == filterType then
				table.insert(peripherals, {Name = name:sub(1,8) .. ' '..code, Fullname = name .. ' ('..side:sub(1, 1):upper() .. side:sub(2, -1)..')', Side = side, Type = _type, Wireless = isWireless, FormattedType = formattedType})
			end
		end
	end
	return peripherals
end

GetSide = function(side)
	for i, p in ipairs(GetPeripherals()) do
		if p.Side == side then
			return p
		end
	end
end

PresentNamed = function(name)
	return peripheral.isPresent(name)
end

CallType = function(type, ...)
	local tArgs = {...}
	local p = GetPeripheral(type)
	return peripheral.call(p.Side, unpack(tArgs))
end

CallNamed = function(name, ...)
	local tArgs = {...}
	return peripheral.call(name, unpack(tArgs))
end

GetInfo = function(p)
	local info = {}
	local buttons = {}
	if p.Type == 'computer' then
		local id = peripheral.call(p.Side:lower(),'getID')
		if id then
			info = {
				ID = tostring(id)
			}
		else
			info = {}
		end
	elseif p.Type == 'drive' then
		local discType = 'No Disc'
		local discID = nil
		local mountPath = nil
		local discLabel = nil
		local songName = nil
		if peripheral.call(p.Side:lower(), 'isDiskPresent') then
			if peripheral.call(p.Side:lower(), 'hasData') then
				discType = 'Data'
				discID = peripheral.call(p.Side:lower(), 'getDiskID')
				if discID then
					discID = tostring(discID)
				else
					discID = 'None'
				end
				mountPath = '/'..peripheral.call(p.Side:lower(), 'getMountPath')..'/'
				discLabel = peripheral.call(p.Side:lower(), 'getDiskLabel')
			else
				discType = 'Audio'
				songName = peripheral.call(p.Side:lower(), 'getAudioTitle')
			end
		end
		if mountPath then
			table.insert(buttons, {Text = 'View Files', OnClick = function(self, event, side, x, y)GoToPath(mountPath)end})
		elseif discType == 'Audio' then
			table.insert(buttons, {Text = 'Play', OnClick = function(self, event, side, x, y)
				if self.Text == 'Play' then
					disk.playAudio(p.Side:lower())
					self.Text = 'Stop'
				else
					disk.stopAudio(p.Side:lower())
					self.Text = 'Play'
				end
			end})
		else
			diskOpenButton = nil
		end
		if discType ~= 'No Disc' then
			table.insert(buttons, {Text = 'Eject', OnClick = function(self, event, side, x, y)disk.eject(p.Side:lower()) sleep(0) RefreshFiles() end})
		end

		info = {
			['Disc Type'] = discType,
			['Disc Label'] = discLabel,
			['Song Title'] = songName,
			['Disc ID'] = discID,
			['Mount Path'] = mountPath
		}
	elseif p.Type == 'printer' then
		local pageSize = 'No Loaded Page'
		local _, err = pcall(function() return tostring(peripheral.call(p.Side:lower(), 'getPgaeSize')) end)
		if not err then
			pageSize = tostring(peripheral.call(p.Side:lower(), 'getPageSize'))
		end
		info = {
			['Paper Level'] = tostring(peripheral.call(p.Side:lower(), 'getPaperLevel')),
			['Paper Size'] = pageSize,
			['Ink Level'] = tostring(peripheral.call(p.Side:lower(), 'getInkLevel'))
		}
	elseif p.Type == 'modem' then
		info = {
			['Connected Peripherals'] = tostring(#peripheral.call(p.Side:lower(), 'getNamesRemote'))
		}
	elseif p.Type == 'monitor' then
		local w, h = peripheral.call(p.Side:lower(), 'getSize')
		local screenType = 'Black and White'
		if peripheral.call(p.Side:lower(), 'isColour') then
			screenType = 'Colour'
		end
		local buttonTitle = 'Use as Screen'
		if OneOS.Settings:GetValues()['Monitor'] == p.Side:lower() then
			buttonTitle = 'Use Computer Screen'
		end
		table.insert(buttons, {Text = buttonTitle, OnClick = function(self, event, side, x, y)
				self.Bedrock:DisplayAlertWindow('Reboot Required', "To change screen you'll need to reboot your computer.", {'Reboot', 'Cancel'}, function(value)
					if value == 'Reboot' then
						if buttonTitle == 'Use Computer Screen' then
							OneOS.Settings:SetValue('Monitor', nil)
						else
							OneOS.Settings:SetValue('Monitor', p.Side:lower())
						end
						OneOS.Reboot()
					end
				end)
			end
		})
		info = {
			['Type'] = screenType,
			['Width'] = tostring(w),
			['Height'] = tostring(h),
		}
	end
	info.Buttons = buttons
	return info
end
]],
}
local objects = {
["Button"] = [[
BackgroundColour = colours.lightGrey
ActiveBackgroundColour = colours.blue
ActiveTextColour = colours.white
TextColour = colours.black
DisabledTextColour = colours.lightGrey
Text = ""
Toggle = nil
Momentary = true
AutoWidth = true
Align = 'Center'
Enabled = true

OnUpdate = function(self, value)
	if value == 'Text' and self.AutoWidth then
		self.Width = #self.Text + 2
	end
end

OnDraw = function(self, x, y)
	local bg = self.BackgroundColour

	if self.Toggle then
		bg = self.ActiveBackgroundColour
	end

	local txt = self.TextColour
	if self.Toggle then
		txt = self.ActiveTextColour
	end
	if not self.Enabled then
		txt = self.DisabledTextColour
	end
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, bg)

	local _x = 1
    if self.Align == 'Right' then
        _x = self.Width - #self.Text - 1
    elseif self.Align == 'Center' then
        _x = math.floor((self.Width - #self.Text) / 2)
    end

	Drawing.DrawCharacters(x + _x, y-1+math.ceil(self.Height/2), self.Text, txt, bg)
end

OnLoad = function(self)
	if self.Toggle ~= nil then
		self.Momentary = false
	end
end

Click = function(self, event, side, x, y)
	if self.Visible and not self.IgnoreClick and self.Enabled and event ~= 'mouse_scroll' then
		if self.OnClick then
			if self.Momentary then
				self.Toggle = true
				self.Bedrock:StartTimer(function()self.Toggle = false end,0.25)
			elseif self.Toggle ~= nil then
				self.Toggle = not self.Toggle
			end

			self:OnClick(event, side, x, y, self.Toggle)
		else
			self.Toggle = not self.Toggle
		end
		return true
	else
		return false
	end
end
]],
["CollectionView"] = [[
Inherit = 'ScrollView'
UpdateDrawBlacklist = {['NeedsItemUpdate']=true}

TextColour = colours.black
BackgroundColour = colours.white
Items = false
NeedsItemUpdate = false
SpacingX = 2
SpacingY = 1

OnDraw = function(self, x, y)
	if self.NeedsItemUpdate then
		self:UpdateItems()
		self.NeedsItemUpdate = false
	end
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
end

local function MaxIcons(self, obj)
	if not obj.Height or not obj.Width then
		error('You must provide each object\'s height when adding to a CollectionView.')
	end
	local slotHeight = obj.Height + self.SpacingY
	local slotWidth = obj.Width + self.SpacingX
	local maxX = math.floor((self.Width - 2) / slotWidth)
	return maxX, slotWidth, slotHeight
end

local function IconLocation(self, obj, i)
	local maxX, slotWidth, slotHeight = MaxIcons(self, obj)
	local y = 2
	local x = 1 + math.ceil((self.Width - slotWidth * maxX) / 2)
	local rowPos = ((i - 1) % maxX)
	local colPos = math.ceil(i / maxX) - 1
	x = x + (slotWidth * rowPos)
	y = y + colPos * slotHeight
	return x, y
end

local function AddItem(self, v, i)
	local toggle = false
	if not self.CanSelect then
		toggle = nil
	end
	local x, y = IconLocation(self, v, i)
	local item = {
		["X"]=x,
		["Y"]=y,
		["Name"]="CollectionViewItem",
		["Type"]="View",
		["TextColour"]=self.TextColour,
		["BackgroundColour"]=0,
		OnClick = function(itm)
			if self.CanSelect then
				for i2, _v in ipairs(self.Children) do
					_v.Toggle = false
				end
				self.Selected = itm
			end
		end
    }
	for k, _v in pairs(v) do
		item[k] = _v
   	end
	self:AddObject(item)
end

UpdateItems = function(self)
	self:RemoveAllObjects()
	local groupMode = false
	for k, v in pairs(self.Items) do
		if type(k) == 'string' then
			groupMode = true
			break
		end
	end

	for i, v in ipairs(self.Items) do
		AddItem(self, v, i)
	end
	self:UpdateScroll()
end

OnUpdate = function(self, value)
	if value == 'Items' then
		self.NeedsItemUpdate = true
	end
end
]],
["ImageView"] = [[
Image = false

OnDraw = function(self, x, y)
	Drawing.DrawImage(x, y, self.Image, self.Width, self.Height)
end

OnLoad = function(self)
	if self.Path and fs.exists(self.Path) then
		self.Image = Drawing.LoadImage(self.Path)
	end
end

OnUpdate = function(self, value)
	if value == 'Path' then
		if self.Path and fs.exists(self.Path) then
			self.Image = Drawing.LoadImage(self.Path)
		end
	end
end
]],
["Label"] = [[
TextColour = colours.black
BackgroundColour = colours.transparent
Text = ""
AutoWidth = false
Wrap = true
Align = 'Left'

local wrapText = function(text, maxWidth)
    local lines = {''}
    for word, space in text:gmatch('(%S+)(%s*)') do
        local temp = lines[#lines] .. word .. space:gsub('\n','')
        if #temp > maxWidth then
            table.insert(lines, '')
        end
        if space:find('\n') then
            lines[#lines] = lines[#lines] .. word
            
            space = space:gsub('\n', function()
                    table.insert(lines, '')
                    return ''
            end)
        else
            lines[#lines] = lines[#lines] .. word .. space
        end
    end
    if #lines[1] == 0 then
        table.remove(lines,1)
    end
    return lines
end

OnUpdate = function(self, value)
    if value == 'Text' then
        if self.AutoWidth then
            self.Width = #self.Text
        else
            self.Height = #wrapText(self.Text, self.Width)
        end
    end
end

OnDraw = function(self, x, y)
    local lines
    if self.Wrap then
        lines = wrapText(self.Text, self.Width)
    else
        lines = {self.Bedrock.Helpers.TruncateString(self.Text, self.Width)}
    end

	for i, v in ipairs(lines) do
        local _x = 0
        if self.Align == 'Right' then
            _x = self.Width - #v
        elseif self.Align == 'Center' then
            _x = math.floor((self.Width - #v) / 2)
        end
		Drawing.DrawCharacters(x + _x, y + i - 1, v, self.TextColour, self.BackgroundColour)
	end
end
]],
["ListView"] = [[
Inherit = 'ScrollView'
UpdateDrawBlacklist = {['NeedsItemUpdate']=true}

TextColour = colours.black
BackgroundColour = colours.white
HeadingColour = colours.lightGrey
SelectionBackgroundColour = colours.blue
SelectionTextColour = colours.white
Items = false
CanSelect = false
Selected = nil
NeedsItemUpdate = false
ItemMargin = 1
HeadingMargin = 0
TopMargin = 0

OnDraw = function(self, x, y)
	if self.NeedsItemUpdate then
		self:UpdateItems()
	end
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
end

local function AddItem(self, v, x, y, group)
	local toggle = false
	if not self.CanSelect then
		toggle = nil
	elseif v.Selected then
		toggle = true
	end
	local item = {
		["Width"]=self.Width,
		["X"]=x,
		["Y"]=y,
		["Name"]="ListViewItem",
		["Type"]="Button",
		["TextColour"]=self.TextColour,
		["BackgroundColour"]=0,
		["ActiveTextColour"]=self.SelectionTextColour,
		["ActiveBackgroundColour"]=self.SelectionBackgroundColour,
		["Align"]='Left',
		["Toggle"]=toggle,
		["Group"]=group,
		OnClick = function(itm)
			if self.CanSelect then
				self:SelectItem(itm)
			elseif self.OnSelect then
				self:OnSelect(itm.Text)
			end
		end
    }
    if type(v) == 'table' then
    	for k, _v in pairs(v) do
    		item[k] = _v
    	end
    else
		item.Text = v
    end
	
	local itm = self:AddObject(item)
	if v.Selected then
		self:SelectItem(itm)
	end
end

UpdateItems = function(self)
	if not self.Items or type(self.Items) ~= 'table' then
		self.Items = {}
	end
	self.Selected = nil
	self:RemoveAllObjects()
	local groupMode = false
	for k, v in pairs(self.Items) do
		if type(k) == 'string' then
			groupMode = true
			break
		end
	end

	if not groupMode then
		for i, v in ipairs(self.Items) do
			AddItem(self, v, self.ItemMargin, i)
		end
	else
		local y = self.TopMargin
		for k, v in pairs(self.Items) do
			y = y + 1
			AddItem(self, {Text = k, TextColour = self.HeadingColour, IgnoreClick = true}, self.HeadingMargin, y)
			for i, _v in ipairs(v) do
				y = y + 1
				AddItem(self, _v, 1, y, k)
			end
			y = y + 1
		end
	end
	self:UpdateScroll()
	self.NeedsItemUpdate = false
end

OnKeyChar = function(self, event, keychar)
	if keychar == keys.up or keychar == keys.down then
		local n = self:GetIndex(self.Selected)
		if keychar == keys.up then
			n = n - 1
		else
			n = n + 1
		end
		local new = self:GetNth(n)
		if new then
			self:SelectItem(new)
		end
	elseif keychar == keys.enter and self.Selected then
		self.Selected:Click('mouse_click', 1, 1, 1)
	end
end

--returns the index/'n' of the given item
GetIndex = function(self, obj)
	local n = 1
	for i, v in ipairs(self.Children) do
		if not v.IgnoreClick then
			if obj == v then
				return n
			end
			n = n + 1
		end
	end
end

--gets the 'nth' list item (does not include headings)
GetNth = function(self, n)
	local _n = 1
	for i, v in ipairs(self.Children) do
		if not v.IgnoreClick then
			if n == _n then
				return v
			end
			_n = _n + 1
		end
	end
end

SelectItem = function(self, item)
	for i, v in ipairs(self.Children) do
		v.Toggle = false
	end
	self.Selected = item
	item.Toggle = true
	if self.OnSelect then
		self:OnSelect(item.Text)
	end
end

OnUpdate = function(self, value)
	if value == 'Items' then
		self.NeedsItemUpdate = true
	end
end
]],
["Menu"] = [[
Inherit = 'View'

TextColour = colours.black
BackgroundColour = colours.white
HideTop = false
Prepared = false

OnDraw = function(self, x, y)
	Drawing.IgnoreConstraint = true
	Drawing.DrawBlankArea(x + 1, y + (self.HideTop and 0 or 1), self.Width, self.Height + (self.HideTop and 1 or 0), colours.grey)
	Drawing.IgnoreConstraint = false
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
end

OnLoad = function(self)
	local owner = self.Owner
	if type(owner) == 'string' then
		owner = self.Bedrock:GetObject(self.Owner)
	end

	if owner then
		if self.X == 0 and self.Y == 0 then
			local pos = owner:GetPosition()
			self.X = pos.X
			self.Y = pos.Y + owner.Height
		end
		self.Owner = owner
	else
		self.Owner = nil
	end
end

OnUpdate = function(self, value)
	if value == 'Children' then
		self.Height = #self.Children + 1 + (self.HideTop and 0 or 1)
		if not self.BaseY then
			self.BaseY = self.Y
		end
		if #self.Children > 0 and self.Children[1].Type == 'Button' then
			self.Width = self.Bedrock.Helpers.LongestString(self.Children, 'Text') + 2
			for i, v in ipairs(self.Children) do
				if v.TextColour then
					v.TextColour = self.TextColour
				end
				if v.BackgroundColour then
					v.BackgroundColour = colours.transparent
				end
				if v.Colour then
					v.Colour = colours.lightGrey
				end
				v.Align = 'Left'
				v.X = 1
				v.Y = i + (self.HideTop and 0 or 1)
				v.Width = self.Width
				v.Height = 1
			end
		elseif #self.Children > 0 and self.Children[1].Type == 'MenuItem' then
			local width = 1
			for i, v in ipairs(self.Children) do
				if v.Width > width then
					width = v.Width
				end
			end
			self.Width = width
			for i, v in ipairs(self.Children) do
				if v.TextColour then
					v.TextColour = self.TextColour
				end
				if v.Colour then
					v.Colour = colours.lightGrey
				end
				v.X = 1
				v.Y = i + (self.HideTop and 0 or 1)
				v.Width = width
				v.Height = 1
			end
		end

		self.Y = self.BaseY
		local pos = self:GetPosition()
		if pos.Y + self.Height + 1 > Drawing.Screen.Height then
			self.Y = self.BaseY - ((self.Height +  pos.Y) - Drawing.Screen.Height)
		end
		
		if pos.X + self.Width > Drawing.Screen.Width then
			self.X = Drawing.Screen.Width - self.Width
		end
	end
end

Close = function(self, isBedrockCall)
	self.Bedrock.Menu = nil
	if not self.Prepared then
		self.Parent:RemoveObject(self)
	else
		self.Visible = false
	end

	if self.Owner and self.Owner.Toggle then
		self.Owner.Toggle = false
	end
	self.Parent:ForceDraw()
	self = nil
end

OnChildClick = function(self, child, event, side, x, y)
	self:Close()
end
]],
["MenuItem"] = [[
BackgroundColour = colours.white
TextColour = colours.black
DisabledTextColour = colours.lightGrey
ShortcutTextColour = colours.grey
Text = ""
Enabled = true
Shortcut = nil
ShortcutPadding = 2
ShortcutName = nil

OnUpdate = function(self, value)
	if value == 'Text' then
		if self.Shortcut then
			self.Width = #self.Text + 2 + self.ShortcutPadding + #self.Shortcut
		else
			self.Width = #self.Text + 2
		end
	elseif value == 'OnClick' then
		self:RegisterShortcut()
	end
end

OnDraw = function(self, x, y)
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)

	local txt = self.TextColour
	if not self.Enabled then
		txt = self.DisabledTextColour
	end
	Drawing.DrawCharacters(x + 1, y, self.Text, txt, colours.transparent)

	if self.Shortcut then
		local shrt = self.ShortcutTextColour
		if not self.Enabled then
			shrt = self.DisabledTextColour
		end
		Drawing.DrawCharacters(x + self.Width - #self.Shortcut - 1, y, self.Shortcut, shrt, colours.transparent)
	end
end

ParseShortcut = function(self)
	local special = {
		['^'] = keys.leftShift,
		['<'] = keys.delete,
		['>'] = keys.delete,
		['#'] = keys.leftCtrl,
		['~'] = keys.leftAlt,
	}

	local keys = {}
	for i = 1, #self.Shortcut do
	    local c = self.Shortcut:sub(i,i)
    	table.insert(keys, special[c] or c:lower())
	end
	return keys
end

RegisterShortcut = function(self)
	if self.Shortcut then
		self.Shortcut = self.Shortcut:upper()
		self.ShortcutName = self.Bedrock:RegisterKeyboardShortcut(self:ParseShortcut(), function()
			if self.OnClick and self.Enabled then
				if self.Parent.Owner then
					self.Parent:Close()
					self.Parent.Owner.Toggle = true
					self.Bedrock:StartTimer(function()
						self.Parent.Owner.Toggle = false
					end, 0.3)
				end
				return self:OnClick('keyboard_shortcut', 1, 1, 1)
			else
				return false
			end
		end)
	end
end

OnRemove = function(self)
	if self.ShortcutName then
		self.Bedrock:UnregisterKeyboardShortcut(self.ShortcutName)
	end
end

OnLoad = function(self)
	if self.OnClick ~= nil then
		self:RegisterShortcut()
	end
	-- self:OnUpdate('Text')
end
]],
["NumberBox"] = [[
Inherit = 'View'

Value = 1
Minimum = 1
Maximum = 99
BackgroundColour = colours.lightGrey
TextBoxTimer = nil
Width = 7

OnLoad = function(self)
	self:AddObject({
		X = self.Width - 1,
		Y = 1,
		Width = 1,
		AutoWidth = false,
		Text = '-',
		Type = 'Button',
		Name = 'AddButton',
		BackgroundColour = colours.transparent,
		OnClick = function()
			self:ShiftValue(-1)
		end
	})

	self:AddObject({
		X = self.Width,
		Y = 1,
		Width = 1,
		AutoWidth = false,
		Text = '+',
		Type = 'Button',
		Name = 'SubButton',
		BackgroundColour = colours.transparent,
		OnClick = function()
			self:ShiftValue(1)
		end
	})

	self:AddObject({
		X = 1,
		Y = 1,
		Width = self.Width - 2,
		Text = tostring(self.Value),
		Align = 'Center',
		Type = 'TextBox',
		BackgroundColour = colours.transparent,
		OnChange = function(_self, event, keychar)
			if keychar == keys.enter then
				self:SetValue(tonumber(_self.Text))
				self.TextBoxTimer = nil
			end
			if self.TextBoxTimer then
				self.Bedrock:StopTimer(self.TextBoxTimer)
			end

			self.TextBoxTimer = self.Bedrock:StartTimer(function(_, timer)
				if timer and timer == self.TextBoxTimer then
					self:SetValue(tonumber(_self.Text))
					self.TextBoxTimer = nil
				end
			end, 2)
		end
	})
end

OnScroll = function(self, event, dir, x, y)
	self:ShiftValue(-dir)
end

ShiftValue = function(self, delta)
	local val = tonumber(self:GetObject('TextBox').Text) or self.Minimum
	self:SetValue(val + delta)
end

SetValue = function(self, newValue)
	newValue = newValue or 0
	if self.Maximum and newValue > self.Maximum then
		newValue = self.Maximum
	elseif self.Minimum and newValue < self.Minimum then
		newValue = self.Minimum
	end
	self.Value = newValue
	if self.OnChange then
		self:OnChange()
	end
end

OnUpdate = function(self, value)
	if value == 'Value' then
		local textbox = self:GetObject('TextBox')
		if textbox then
			textbox.Text = tostring(self.Value)
		end
	end
end
]],
["ProgressBar"] = [[
BackgroundColour = colours.lightGrey
BarColour = colours.blue
TextColour = colours.white
ShowText = false
Value = 0
Maximum = 1
Indeterminate = false
AnimationStep = 0

OnDraw = function(self, x, y)
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)

	-- if self.Indeterminate then
	-- 	for i = 1, self.Width do
	-- 		local s = x + i - 1 + self.AnimationStep
	-- 		if s % 4 == 1 or s % 4 == 2 then
	-- 			Drawing.DrawBlankArea(s, y, 1, self.Height, self.BarColour)
	-- 		end
	-- 	end
	-- 	self.AnimationStep = self.AnimationStep + 1
	-- 	if self.AnimationStep >= 4 then
	-- 		self.AnimationStep = 0
	-- 	end
	-- 	self.Bedrock:StartTimer(function()
	-- 		self:Draw()
	-- 	end, 0.25)
	-- else
		local values = self.Value
		local barColours = self.BarColour
		if type(values) == 'number' then
			values = {values}
		end
		if type(barColours) == 'number' then
			barColours = {barColours}
		end

		local total = 0
		local _x = x
		for i, v in ipairs(values) do
			local width = (v == 0 and 0 or self.Bedrock.Helpers.Round((v / self.Maximum) * self.Width))
			total = total + v
			if width ~= 0 then
				Drawing.DrawBlankArea(_x, y, width, self.Height, barColours[((i-1)%#barColours)+1])
			end
			_x = _x + width
		end

		if self.ShowText then
			local text = self.Bedrock.Helpers.Round((total / self.Maximum) * 100) .. '%'
			Drawing.DrawCharactersCenter(x, y, self.Width, self.Height, text, self.TextColour, colours.transparent)
		end
	-- end
end
]],
["ScrollBar"] = [[
BackgroundColour = colours.lightGrey
BarColour = colours.lightBlue
Scroll = 0
MaxScroll = 0
ClickPoint = nil
Fixed = true

OnUpdate = function(self, value)
	if value == 'Text' and self.AutoWidth then
		self.Width = #self.Text + 2
	end
end

OnDraw = function(self, x, y)
	local barHeight = self.Height * (self.Height / (self.Height + self.MaxScroll))
    if barHeight < 3 then
      barHeight = 3
    end
    local percentage = (self.Scroll/self.MaxScroll)

    Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
    Drawing.DrawBlankArea(x, y + math.ceil(self.Height*percentage - barHeight*percentage), self.Width, barHeight, self.BarColour)
end

OnScroll = function(self, event, direction, x, y)
	if event == 'mouse_scroll' then
		direction = self.Bedrock.Helpers.Round(direction * 3)
	end
	if self.Scroll < 0 or self.Scroll > self.MaxScroll then
		return false
	end
	local old = self.Scroll
	self.Scroll = self.Bedrock.Helpers.Round(self.Scroll + direction)
	if self.Scroll < 0 then
		self.Scroll = 0
	elseif self.Scroll > self.MaxScroll then
		self.Scroll = self.MaxScroll
	end

	if self.Scroll ~= old and self.OnChange then
		self:OnChange()
	end
end

-- TODO: this really needs an overhaul
OnClick = function(self, event, side, x, y)
	if event == 'mouse_click' then
		self.ClickPoint = y
	else
		if self.ClickPoint then
			local gapHeight = self.Height - (self.Height * (self.Height / (self.Height + self.MaxScroll)))
			local barHeight = self.Height * (self.Height / (self.Height + self.MaxScroll))
			--local delta = (self.Height + self.MaxScroll) * ((y - self.ClickPoint) / barHeight)
			local delta = ((y - self.ClickPoint)/gapHeight)*self.MaxScroll
			--l(((y - self.ClickPoint)/gapHeight))
			--l(delta)
			self.Scroll = self.Bedrock.Helpers.Round(delta)
			--l(self.Scroll)
			--l('----')
			if self.Scroll < 0 then
				self.Scroll = 0
			elseif self.Scroll > self.MaxScroll then
				self.Scroll = self.MaxScroll
			end
			if self.OnChange then
				self:OnChange()
			end
		end
	end

	local relScroll = self.MaxScroll * ((y-1)/self.Height)
	if y == self.Height then
		relScroll = self.MaxScroll
	end
	self.Scroll = self.Bedrock.Helpers.Round(relScroll)


end

OnDrag = OnClick
]],
["ScrollView"] = [[
Inherit = 'View'
ChildOffset = false
ContentWidth = 0
ContentHeight = 0
ScrollBarBackgroundColour = colours.lightGrey
ScrollBarColour = colours.lightBlue

CalculateContentSize = function(self)
	local function calculateObject(obj)
		local pos = obj:GetPosition()
		local x2 = pos.X + obj.Width - 1
		local y2 = pos.Y + obj.Height - 1
		if obj.Children then
			for i, child in ipairs(obj.Children) do
				local _x2, _y2 = calculateObject(child)
				if _x2 > x2 then
					x2 = _x2
				end
				if _y2 > y2 then
					y2 = _y2
				end
			end
		end
		return x2, y2
	end

	local pos = self:GetPosition()
	local x2, y2 = calculateObject(self)
	self.ContentWidth = x2 - pos.X + 1
	self.ContentHeight = y2 - pos.Y + 1
end

UpdateScroll = function(self)
	self.ChildOffset.Y = 0
	self:CalculateContentSize()
	if self.ContentHeight > self.Height then
		if not self:GetObject('ScrollViewScrollBar') then
			local _scrollBar = self:AddObject({
				["Name"] = 'ScrollViewScrollBar',
				["Type"] = 'ScrollBar',
				["X"] = self.Width,
				["Y"] = 1,
				["Width"] = 1,
				["Height"] = self.Height,
				["BackgroundColour"] = self.ScrollBarBackgroundColour,
				["BarColour"] = self.ScrollBarColour,
				["Z"]=999
			})

			_scrollBar.OnChange = function(scrollBar)
				self.ChildOffset.Y = -scrollBar.Scroll
				for i, child in ipairs(self.Children) do
					child:ForceDraw()
				end
			end
		end

		if self:GetObject('ScrollViewScrollBar') then
			self:GetObject('ScrollViewScrollBar').MaxScroll = self.ContentHeight - self.Height
		end
	else
		self:RemoveObject('ScrollViewScrollBar')
	end
end

OnScroll = function(self, event, direction, x, y)
	if self:GetObject('ScrollViewScrollBar') then
		self:GetObject('ScrollViewScrollBar'):OnScroll(event, direction, x, y)
	end
end

OnLoad = function(self)
	if not self.ChildOffset or not self.ChildOffset.X or not self.ChildOffset.Y then
		self.ChildOffset = {X = 0, Y = 0}
	end
	self:UpdateScroll()
end
]],
["SecureTextBox"] = [[
Inherit = 'TextBox'
MaskCharacter = '*'

OnDraw = function(self, x, y)
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
	if self.CursorPos > #self.Text then
		self.CursorPos = #self.Text
	elseif self.CursorPos < 0 then
		self.CursorPos = 0
	end
	local text = ''

	for i = 1, #self.Text do
		text = text .. self.MaskCharacter
	end

	if self.Bedrock:GetActiveObject() == self then
		if #text > (self.Width - 2) then
			text = text:sub(#text-(self.Width - 3))
			self.Bedrock.CursorPos = {x + 1 + self.Width-2, y}
		else
			self.Bedrock.CursorPos = {x + 1 + self.CursorPos, y}
		end
		self.Bedrock.CursorColour = self.TextColour
	end

	if #tostring(text) == 0 then
		Drawing.DrawCharacters(x + 1, y, self.Placeholder, self.PlaceholderTextColour, self.BackgroundColour)
	else
		if not self.Selected then
			Drawing.DrawCharacters(x + 1, y, text, self.TextColour, self.BackgroundColour)
		else
			for i = 1, #text do
				local char = text:sub(i, i)
				local textColour = self.TextColour
				local backgroundColour = self.BackgroundColour
				if i > self.DragStart and i - 1 <= self.CursorPos then
					textColour = self.SelectedTextColour
					backgroundColour = self.SelectedBackgroundColour
				end
				Drawing.DrawCharacters(x + i, y, char, textColour, backgroundColour)
			end
		end
	end
end
]],
["Separator"] = [[
Colour = colours.grey
Character = nil

OnDraw = function(self, x, y)
	local char = self.Character
	if not char then
		char = "|"
		if self.Width > self.Height then
			char = '-'
		end
	end
	Drawing.DrawArea(x, y, self.Width, self.Height, char, self.Colour, colours.transparent)
end
]],
["TextBox"] = [[
BackgroundColour = colours.lightGrey
SelectedBackgroundColour = colours.blue
SelectedTextColour = colours.white
TextColour = colours.black
PlaceholderTextColour = colours.grey
Placeholder = ''
AutoWidth = false
Text = ""
CursorPos = nil
Numerical = false
DragStart = nil
Selected = false
SelectOnClick = false
ActualDragStart = nil

OnDraw = function(self, x, y)
	Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
	if self.CursorPos > #self.Text then
		self.CursorPos = #self.Text
	elseif self.CursorPos < 0 then
		self.CursorPos = 0
	end
	local text = self.Text
	local offset = self:TextOffset()
	if #text > (self.Width - 2) then
		text = text:sub(offset+1, offset + self.Width - 2)
		-- self.Bedrock.CursorPos = {x + 1 + self.Width-2, y}
	-- else
	end
	if self.Bedrock:GetActiveObject() == self then
		self.Bedrock.CursorPos = {x + 1 + self.CursorPos - offset, y}
		self.Bedrock.CursorColour = self.TextColour
	else
		self.Selected = false
	end

	if #tostring(text) == 0 then
		self:DrawPlaceholder(x + 1, y)
	else
		if not self.Selected then
			self:DrawText(x + 1, y, text)
		else
			local startPos = self.DragStart - offset
			local endPos = self.CursorPos - offset
			if startPos > endPos then
				startPos = self.CursorPos - offset
				endPos = self.DragStart - offset
			end
			self:DrawSelectedText(x, y, text, startPos, endPos)
		end
	end
end

DrawText = function(self, x, y, text)
	Drawing.DrawCharacters(x, y, text, self.TextColour, self.BackgroundColour)
end

DrawPlaceholder = function(self, x, y)
	Drawing.DrawCharacters(x, y, self.Placeholder, self.PlaceholderTextColour, self.BackgroundColour)
end

DrawSelectedText = function(self, x, y, text, startPos, endPos)
	for i = 1, #text do
		local char = text:sub(i, i)
		local textColour = self.TextColour
		local backgroundColour = self.BackgroundColour

		if i > startPos and i - 1 <= endPos then
			textColour = self.SelectedTextColour
			backgroundColour = self.SelectedBackgroundColour
		end
		Drawing.DrawCharacters(x + i, y, char, textColour, backgroundColour)
	end
end

TextOffset = function(self)
	if #self.Text < (self.Width - 2) then
		return 0
	elseif self.Bedrock:GetActiveObject() ~= self then
		return 0
	else
		local textWidth = (self.Width - 2)
		local offset = self.CursorPos - textWidth
		if offset < 0 then
			offset = 0
		end
		return offset
	end
end

OnLoad = function(self)
	if not self.CursorPos then
		self.CursorPos = #self.Text
	end
end

OnClick = function(self, event, side, x, y)
	if self.Bedrock:GetActiveObject() ~= self and self.SelectOnClick then
		self.CursorPos = #self.Text - 1
		self.DragStart = 0
		self.ActualDragStart = x - 2 + self:TextOffset()
		self.Selected = true
	else
		self.CursorPos = x - 2 + self:TextOffset()
		self.DragStart = self.CursorPos
		self.Selected = false
	end
	self.Bedrock:SetActiveObject(self)
end

OnDrag = function(self, event, side, x, y)
	self.CursorPos = x - 2 + self:TextOffset()
	if self.ActualDragStart then
		self.DragStart = self.ActualDragStart
		self.ActualDragStart = nil
	end
	if self.DragStart then
		self.Selected = true
	end
end

OnPaste = function(self, event, text)
	self:DeleteSelected()
	if self.Numerical then
		text = tostring(tonumber(text))
		if text == 'nil' then
			return
		end
	end
	self.Text = string.sub(self.Text, 1, self.CursorPos ) .. text .. string.sub( self.Text, self.CursorPos + #text )
	if self.Numerical then
		self.Text = tostring(tonumber(self.Text))
		if self.Text == 'nil' then
			self.Text = '1'
		end
	end
	
	self.CursorPos = self.CursorPos + #text
	if self.OnChange then
		self:OnChange(event, text)
	end
end

DeleteSelected = function(self)
	if self.Selected then
		local startPos = self.DragStart
		local endPos = self.CursorPos
		if startPos > endPos then
			startPos = self.CursorPos
			endPos = self.DragStart
		end
		self.Text = self.Text:sub(1, startPos) .. self.Text:sub(endPos + 2)
		self.CursorPos = startPos
		self.DragStart = nil
		self.Selected = false
		return true
	end
end

OnKeyChar = function(self, event, keychar)

	if self.CustomOnKeyChar and self:CustomOnKeyChar(event, keychar) then
		self:OnChange(event, keychar)
		return
	elseif event == 'char' then
		self:DeleteSelected()
		if self.Numerical then
			keychar = tostring(tonumber(keychar))
		end
		if keychar == 'nil' then
			return
		end
		self.Text = string.sub(self.Text, 1, self.CursorPos ) .. keychar .. string.sub( self.Text, self.CursorPos + 1 )
		if self.Numerical then
			self.Text = tostring(tonumber(self.Text))
			if self.Text == 'nil' then
				self.Text = '1'
			end
		end
		
		self.CursorPos = self.CursorPos + 1
		if self.OnChange then
			self:OnChange(event, keychar)
		end
		return false
	elseif event == 'key' then
		if keychar == keys.enter then
			if self.OnChange then
				self:OnChange(event, keychar)
			end
		elseif keychar == keys.left then
			-- Left
			if self.CursorPos > 0 then
				if self.Selected then
					self.CursorPos = self.DragStart
					self.DragStart = nil
					self.Selected = false
				else
					self.CursorPos = self.CursorPos - 1
				end
				if self.OnChange then
					self:OnChange(event, keychar)
				end
			end
			
		elseif keychar == keys.right then
			-- Right				
			if self.CursorPos < string.len(self.Text) then
				if self.Selected then
					self.CursorPos = self.CursorPos
					self.DragStart = nil
					self.Selected = false
				else
					self.CursorPos = self.CursorPos + 1
				end
				if self.OnChange then
					self:OnChange(event, keychar)
				end
			end
		
		elseif keychar == keys.backspace then
			-- Backspace
			if not self:DeleteSelected() and self.CursorPos > 0 then
				self.Text = string.sub( self.Text, 1, self.CursorPos - 1 ) .. string.sub( self.Text, self.CursorPos + 1 )
				self.CursorPos = self.CursorPos - 1					
				if self.Numerical then
					self.Text = tostring(tonumber(self.Text))
					if self.Text == 'nil' then
						self.Text = '1'
					end
				end
				if self.OnChange then
					self:OnChange(event, keychar)
				end
			end
		elseif keychar == keys.home then
			-- Home
			self.CursorPos = 0
			if self.OnChange then
				self:OnChange(event, keychar)
			end
		elseif keychar == keys.delete then
			if not self:DeleteSelected() and self.CursorPos < string.len(self.Text) then
				self.Text = string.sub( self.Text, 1, self.CursorPos ) .. string.sub( self.Text, self.CursorPos + 2 )		
				if self.Numerical then
					self.Text = tostring(tonumber(self.Text))
					if self.Text == 'nil' then
						self.Text = '1'
					end
				end
				if self.OnChange then
					self:OnChange(keychar)
				end
			end
		elseif keychar == keys["end"] then
			-- End
			self.CursorPos = string.len(self.Text)
		else
			if self.OnChange then
				self:OnChange(event, keychar)
			end
			return false
		end
	end
end
]],
["View"] = [[
BackgroundColour = colours.transparent
Children = {}

OnDraw = function(self, x, y)
	if self.BackgroundColour then
		Drawing.DrawBlankArea(x, y, self.Width, self.Height, self.BackgroundColour)
	end
end

OnInitialise = function(self)
	self.Children = {}
end

InitialiseFile = function(self, bedrock, file, name)
	local _new = {}
	_new.X = 1
	_new.Y = 1
	_new.Width = Drawing.Screen.Width
	_new.Height = Drawing.Screen.Height
	_new.BackgroundColour = file.BackgroundColour
	_new.Name = name
	_new.Children = {}
	_new.Bedrock = bedrock
	local new = self:Initialise(_new)
	for i, obj in ipairs(file.Children) do
		local view = bedrock:ObjectFromFile(obj, new)
		if not view.Z then
			view.Z = i
		end
		view.Parent = new
		table.insert(new.Children, view)
	end
	return new
end

function CheckClick(self, object, x, y)
	local offset = {X = 0, Y = 0}
	if not object.Fixed and self.ChildOffset then
		offset = self.ChildOffset
	end
	if object.X + offset.X <= x and object.Y + offset.Y <= y and  object.X + offset.X + object.Width > x and object.Y + offset.Y + object.Height > y then
		return true
	end
end

function DoClick(self, object, event, side, x, y)
	if object then
		if self:CheckClick(object, x, y) then
			local offset = {X = 0, Y = 0}
			if not object.Fixed and self.ChildOffset then
				offset = self.ChildOffset
			end
			return object:Click(event, side, x - object.X - offset.X + 1, y - object.Y + 1 - offset.Y)
		end
	end	
end

Click = function(self, event, side, x, y, z)
	if self.Visible and not self.IgnoreClick then
		for i = #self.Children, 1, -1 do --children are ordered from smallest Z to highest, so this is done in reverse
			local child = self.Children[i]
			if self:DoClick(child, event, side, x, y) then
				if self.OnChildClick then
					self:OnChildClick(child, event, side, x, y)
				end
				return true
			end
		end
		if event == 'mouse_click' and self.OnClick and self:OnClick(event, side, x, y) ~= false then
			return true
		elseif event == 'mouse_drag' and self.OnDrag and self:OnDrag(event, side, x, y) ~= false then
			return true
		elseif event == 'mouse_scroll' and self.OnScroll and self:OnScroll(event, side, x, y) ~= false then
			return true
		else
			return false
		end
	else
		return false
	end
end

OnRemove = function(self)
	if self == self.Bedrock:GetActiveObject() then
		self.Bedrock:SetActiveObject()
	end
	for i, child in ipairs(self.Children) do
		child:OnRemove()
	end
end

local function findObjectNamed(view, name, minI)
	local minI = minI or 0
	if view and view.Children then
		for i, child in ipairs(view.Children) do
			if child.Name == name or child == name then
				return child, i, view
			elseif child.Children then
				local found, index, foundView = findObjectNamed(child, name)
				if found and minI <= index then
					return found, index, foundView
				end
			end
		end
	end
end

function ReorderObjects(self)
	if self.Children then
		table.sort(self.Children, function(a,b)
			return a.Z < b.Z 
		end)
		for i, v in ipairs(self.Children) do
			if v.ReorderObjects then
				v:ReorderObjects()
			end
		end
	end
end

function AddObject(self, info, extra, first)
	if type(info) == 'string' then
		local h = fs.open(self.Bedrock.ViewPath..info..'.view', 'r')
		if h then
			info = textutils.unserialize(h.readAll())
			h.close()
		else
			error('Error in opening object: '..info)
		end
	end

	if extra then
		for k, v in pairs(extra) do
			if v then
				info[k] = v
			end
		end
	end

	local view = self.Bedrock:ObjectFromFile(info, self)
	if not view.Z then
		if first then
			view.Z = 1
		else
			view.Z = #self.Children + 1
		end
	end
	
	if first then
		table.insert(self.Children, 1, view)
	else
		table.insert(self.Children, view)
	end
	if self.Bedrock.View then
		self.Bedrock:ReorderObjects()
	end
	self:ForceDraw()
	return view
end

function GetObject(self, name)
	return findObjectNamed(self, name)
end

local function findObjects(view, name)
	local objects = {}
	if view and view.Children then
		for i, child in ipairs(view.Children) do
			if child.Name == name or child == name then
				table.insert(objects, child)
			elseif child.Children then
				local objs = findObjects(child, name)
				if objs then
					for i2, v in ipairs(objs) do
						table.insert(objects, v)
					end
				end
			end
		end
	end
	return objects
end

function GetObjects(self, name)
	return findObjects(self, name)
end

function RemoveObject(self, name)
	local obj, index, view = findObjectNamed(self, name, minI)
	if index then
		view.Children[index]:OnRemove()
		table.remove(view.Children, index)
		if view.OnUpdate then
			view:OnUpdate('Children')
		end
		return true
	end
	return false
end

function RemoveObjects(self, name)
	local i = 1
	while self:RemoveObject(name) and i < 100 do
		i = i + 1
	end
	
end

function RemoveAllObjects(self)
	for i, child in ipairs(self.Children) do
		child:OnRemove()
		self.Children[i] = nil
	end
	self:ForceDraw()
end
]],
["Window"] = [[
Inherit = 'View'

ToolBarColour = colours.lightGrey
ToolBarTextColour = colours.black
ShadowColour = colours.grey
Title = ''
Flashing = false
CanClose = true
OnCloseButton = nil
OldActiveObject = nil

LoadView = function(self)
	local view = self:GetObject('View')
	if view.ToolBarColour then
		window.ToolBarColour = view.ToolBarColour
	end
	if view.ToolBarTextColour then
		window.ToolBarTextColour = view.ToolBarTextColour
	end
	view.X = 1
	view.Y = 2

	view:ForceDraw()
	self:OnUpdate('View')
	if self.OnViewLoad then
		self.OnViewLoad(view)
	end
	self.OldActiveObject = self.Bedrock:GetActiveObject()
	self.Bedrock:SetActiveObject(view)
end

SetView = function(self, view)
	self:RemoveObject('View')
	table.insert(self.Children, view)
	view.Parent = self
	self:LoadView()
end

Flash = function(self)
	self.Flashing = true
	self:ForceDraw()
	self.Bedrock:StartTimer(function()self.Flashing = false end, 0.4)
end

OnDraw = function(self, x, y)
	local toolBarColour = (self.Flashing and colours.grey or self.ToolBarColour)
	local toolBarTextColour = (self.Flashing and colours.black or self.ToolBarTextColour)
	if toolBarColour then
		Drawing.DrawBlankArea(x, y, self.Width, 1, toolBarColour)
	end
	if toolBarTextColour then
		local title = self.Bedrock.Helpers.TruncateString(self.Title, self.Width - 2)
		Drawing.DrawCharactersCenter(self.X, self.Y, self.Width, 1, title, toolBarTextColour, toolBarColour)
	end
	Drawing.IgnoreConstraint = true
	Drawing.DrawBlankArea(x + 1, y + 1, self.Width, self.Height, self.ShadowColour)
	Drawing.IgnoreConstraint = false
end

Close = function(self)
	self.Bedrock:SetActiveObject(self.OldActiveObject)
	self.Bedrock.Window = nil
	self.Bedrock:RemoveObject(self)
	if self.OnClose then
		self:OnClose()
	end
	self = nil
end

OnUpdate = function(self, value)
	if value == 'View' and self:GetObject('View') then
		self.Width = self:GetObject('View').Width
		self.Height = self:GetObject('View').Height + 1
		self.X = math.ceil((Drawing.Screen.Width - self.Width) / 2)
		self.Y = math.ceil((Drawing.Screen.Height - self.Height) / 2)
	elseif value == 'CanClose' then
		self:RemoveObject('CloseButton')
		if self.CanClose then
			local button = self:AddObject({X = 1, Y = 1, Width = 1, Height = 1, Type = 'Button', BackgroundColour = colours.red, TextColour = colours.white, Text = 'x', Name = 'CloseButton'})
			button.OnClick = function(btn)
				if self.OnCloseButton then
					self:OnCloseButton()
				end
				self:Close()
			end
		end
	end
end
]],
}
BasePath = ''
ProgramPath = nil

function LoadAPIs(self)
	local function loadAPI(name, content)
		local env = setmetatable({}, { __index = getfenv() })
		local func, err = loadstring(content, name..' (Bedrock API)')
		if not func then
			return false, printError(err)
		end
		setfenv(func, env)
		func()
		local api = {}
		for k,v in pairs(env) do
			api[k] = v
		end
		_G[name] = api
		return true
	end

	local env = getfenv()
	local function loadObject(name, content)
		loadAPI(name, content)
		if env[name].Inherit then
			if not getfenv()[env[name].Inherit] then	
				if objects[env[name].Inherit] then
					loadObject(env[name].Inherit, objects[env[name].Inherit])
				elseif fs.exists(self.ProgramPath..'/Objects/'..env[name].Inherit..'.lua') then
					local h = fs.open(self.ProgramPath..'/Objects/'..env[name].Inherit..'.lua', 'r')
					loadObject(env[name].Inherit, h.readAll())
					h.close()
					loadObject(name, content)
					return
				end
			end
			env[name].__index = getfenv()[env[name].Inherit]
		else
			env[name].__index = Object
		end
		setmetatable(env[name], env[name])
	end

	for k, v in pairs(apis) do
		loadAPI(k, v)
		if k == 'Helpers' then
			self.Helpers = Helpers
		end
	end

	for k, v in pairs(objects) do
		loadObject(k, v)
	end
	
	local privateObjPath = self.ProgramPath..'/Objects/'
	if fs.exists(privateObjPath) and fs.isDir(privateObjPath) then
		for i, v in ipairs(fs.list(privateObjPath)) do
			if v ~= '.DS_Store' then
				local name = string.match(v, '(%w+)%.?.-')
				local h = fs.open(privateObjPath..v, 'r')
				loadObject(name, h.readAll())
				h.close()
			end
		end
	end
	
	local privateAPIPath = self.ProgramPath..'/APIs/'
	if fs.exists(privateAPIPath) and fs.isDir(privateAPIPath) then
		for i, v in ipairs(fs.list(privateAPIPath)) do
			if v ~= '.DS_Store' then
				local name = string.match(v, '(%w+)%.?.-')
				local h = fs.open(privateAPIPath..v, 'r')
				loadAPI(name, h.readAll())
				h.close()
			end
		end
	end
end

AllowTerminate = true

View = nil
Menu = nil

ActiveObject = nil

DrawTimer = nil
DrawTimerExpiry = 0

IsDrawing = false

Running = true

DefaultView = 'main'

AnimationEnabled = true

EventHandlers = {
	
}

ObjectClickHandlers = {
	
}

ObjectUpdateHandlers = {
	
}

Timers = {
	
}

ModifierKeys = {}
KeyboardShortcuts = {}

keys.leftCommand = 219
keys.rightCommand = 220

function Initialise(self, programPath)
	self.ProgramPath = programPath or self.ProgramPath
	if not programPath then
		if self.ProgramPath then
			local prgPath = self.ProgramPath
			local prgName = fs.getName(prgPath)
			if prgPath:find('/') then 
				self.ProgramPath = prgPath:sub(1, #prgPath-#prgName-1)
				self.ProgramPath = prgPath:sub(1, #prgPath-#prgName-1) 
			else 
		 		self.ProgramPath = '' 
		 	end
		else
			self.ProgramPath = ''
		end
	end
	self:LoadAPIs()
	self.ViewPath = self.ProgramPath .. '/Views/'
	--first, check that the barebones APIs are available
	local requiredApis = {
		'Drawing',
		'View'
	}
	local env = getfenv()
	for i,v in ipairs(requiredApis) do
		if not env[v] then
			error('The API: '..v..' is not loaded. Please make sure you load it to use Bedrock.')
		end
	end

	local copy = { }
	for k, v in pairs(self) do
		if k ~= 'Initialise' then
			copy[k] = v
		end
	end
	return setmetatable(copy, getmetatable(self))
end

function HandleClick(self, event, side, x, y)
	if self.Menu then
		if not self.View:DoClick(self.Menu, event, side, x, y) then
			self.Menu:Close()
		end
	elseif self.Window then
		if not self.View:CheckClick(self.Window, x, y) then
			self.Window:Flash()
		else
			self.View:DoClick(self.Window, event, side, x, y)
		end
	elseif self.View then
		if self.View:Click(event, side, x, y) ~= false then
		end		
	end
end

function UnregisterKeyboardShortcut(self, name)
	if name then
		self.KeyboardShortcuts[name] = nil
	end
end

function RegisterKeyboardShortcut(self, keys, func, name)
	name = name or tostring(math.random(1, 10000))
	if type(keys[1]) == 'table' then
		for i, v in ipairs(keys) do
			self.KeyboardShortcuts[name] = {Keys = v, Function = func}
		end
	else
		self.KeyboardShortcuts[name] = {Keys = keys, Function = func}
	end
	return name
end

function TryKeyboardShortcuts(self, keychar)
	if keychar == keys.backspace then
		keychar = keys.delete
	end

	local len = 1 -- + keychar
	for k, v in pairs(self.ModifierKeys) do
		len = len + 1
	end

	if type(keychar) == 'string' then
		keychar = keychar:lower()
	end

	for _, shortcut in pairs(self.KeyboardShortcuts) do
		local match = true
		for i2, key in ipairs(shortcut.Keys) do
			if type(keychar) == 'string' then
				keychar = keychar:lower()
			end

			if self.ModifierKeys[key] == nil and key ~= keychar  then
				match = false
			end
		end

		if match and #shortcut.Keys == len then
			return shortcut.Function() ~= false
		end
	end
end

function HandleKeyChar(self, event, keychar)
	if keychar == keys.leftCtrl or keychar == keys.leftShift or keychar == keys.leftAlt or keychar == keys.leftCommand or keychar == keys.rightCommand or keychar == keys.rightCtrl or keychar == keys.rightShift or keychar == keys.rightAlt then
		if keychar == keys.leftCommand or keychar == keys.rightCommand or keychar == keys.rightCtrl then
			keychar = keys.leftCtrl
		elseif keychar == keys.rightAlt then
			keychar = keys.leftAlt
		elseif keychar == keys.rightShift then
			keychar = keys.leftShift
		end
		self.ModifierKeys[keychar] = self:StartTimer(function(_, timer)
			if timer == self.ModifierKeys[keychar] then
				self.ModifierKeys[keychar] = nil
			end
		end, 1)
	elseif self:TryKeyboardShortcuts(keychar) then
		return
	end

	if self:GetActiveObject() then
		local activeObject = self:GetActiveObject()
		if activeObject.OnKeyChar then
			if activeObject:OnKeyChar(event, keychar) ~= false then
				--self:Draw()
			end
		end
	end
end

PreparedMenus = {}

function PrepareMenu(self, name)
	local menu = self:AddObject(name, {Type = 'Menu', X = 1, Y = 1, Prepared = true})
	menu.Visible = false
	self.PreparedMenus[name] = menu
	return menu
end

function ToggleMenu(self, name, owner, x, y)
	if self.Menu then
		self.Menu:Close()
		return false
	else
		self:SetMenu(name, owner, x, y)
		return true
	end
end

function SetMenu(self, menu, owner, x, y)
	x = x or 1
	y = y or 1
	if self.Menu then
		self.Menu:Close()
	end	
	if menu then
		local pos = owner:GetPosition()
		if self.PreparedMenus[menu] then
			self.Menu = self.PreparedMenus[menu]
			self.Menu.Visible = true
			self.Menu.Owner = owner
			self.Menu.X = pos.X + x - 1
			self.Menu.Y = pos.Y + y
			self.Menu.Z = self.View.Children[#self.View.Children].Z + 1
			self:ReorderObjects()
		else
			self.Menu = self:AddObject(menu, {Type = 'Menu', Owner = owner, X = pos.X + x - 1, Y = pos.Y + y, Z = self.View.Children[#self.View.Children].Z + 1})
		end
	end
end

function ObjectClick(self, name, func)
	self.ObjectClickHandlers[name] = func
end

function ClickObject(self, object, event, side, x, y)
	if self.ObjectClickHandlers[object.Name] then
		return self.ObjectClickHandlers[object.Name](object, event, side, x, y)
	end
	return false
end

function ObjectUpdate(self, name, func)
	self.ObjectUpdateHandlers[name] = func
end

function UpdateObject(self, object, ...)
	if self.ObjectUpdateHandlers[object.Name] then
		self.ObjectUpdateHandlers[object.Name](object, ...)
		--self:Draw()
	end
end

function GetAbsolutePosition(self, obj)
	if not obj.Parent then
		return {X = obj.X, Y = obj.Y}
	else
		local pos = self:GetAbsolutePosition(obj.Parent)
		local x = pos.X + obj.X - 1
		local y = pos.Y + obj.Y - 1
		if not obj.Fixed and obj.Parent.ChildOffset then
			x = x + obj.Parent.ChildOffset.X
			y = y + obj.Parent.ChildOffset.Y
		end
		return {X = x, Y = y}
	end
end

function LoadView(self, name, draw)
	if self.View and self.OnViewClose then
		self.OnViewClose(self.View.Name)
	end
	if self.View then
		self.View:OnRemove()
	end
	local success = false

	if Drawing.Screen.Width <= 26 and fs.exists(self.ViewPath..name..'-pocket.view') then
		name = name..'-pocket'
	elseif Drawing.Screen.Width <= 39 and fs.exists(self.ViewPath..name..'-turtle.view') then
		name = name..'-turtle'
	end

	if not fs.exists(self.ViewPath..name..'.view') then
		error('The view: '..name..'.view does not exist.')
	end

	local h = fs.open(self.ViewPath..name..'.view', 'r')
	if h then
		local view = textutils.unserialize(h.readAll())
		h.close()
		if view then
			self.View = View:InitialiseFile(self, view, name)
			self:ReorderObjects()

			if OneOS and view.ToolBarColour then
				OneOS.ToolBarColour = view.ToolBarColour
			end
			if OneOS and view.ToolBarTextColour then
				OneOS.ToolBarTextColour = view.ToolBarTextColour
			end
			if not self:GetActiveObject() then
				self:SetActiveObject()
			end
			success = true
		end
	end

	if success and self.OnViewLoad then
		self.OnViewLoad(name)
	end

	if draw ~= false then
		self:Draw()
	end

	if not success then
		error('Failed to load view: '..name..'. It probably isn\'t formatted correctly. Did you forget a } or ,?')
	end

	return success
end

function InheritFile(self, file, name)
	local h = fs.open(self.ViewPath..name..'.view', 'r')
	if h then
		local super = textutils.unserialize(h.readAll())
		if super then
			if type(super) ~= 'table' then
				error('View: "'..name..'.view" is not formatted correctly.')
			end

			for k, v in pairs(super) do
				if not file[k] then
					file[k] = v
				end
			end
			return file
		end
	end
	return file
end

function ParseStringSize(self, parent, k, v)
	local parentSize = parent.Width
	if k == 'Height' or k == 'Y' then
		parentSize = parent.Height
	end
	local parts = {v}
	if type(v) == 'string' and string.find(v, ',') then
		parts = {}
		for word in string.gmatch(v, '([^,]+)') do
		    table.insert(parts, word)
		end
	end

	v = 0
	for i2, part in ipairs(parts) do
		if type(part) == 'string' and part:sub(#part) == '%' then
			v = v + math.ceil(parentSize * (tonumber(part:sub(1, #part-1)) / 100))
		else
			v = v + tonumber(part)
		end
	end
	return v
end

function ObjectFromFile(self, file, view)
	local env = getfenv()
	if env[file.Type] then
		if not env[file.Type].Initialise then
			error('Malformed Object: '..file.Type)
		end
		local object = {}

		if file.InheritView then
			file = self:InheritFile(file, file.InheritView)
		end
		
		object.AutoWidth = true
		for k, v in pairs(file) do
			if k == 'Width' or k == 'X' or k == 'Height' or k == 'Y' then
				v = self:ParseStringSize(view, k, v)
			end

			if k == 'Width' then
				object.AutoWidth = false
			end
			if k ~= 'Children' then
				object[k] = v
			else
				object[k] = {}
			end
		end

		object.Parent = view
		object.Bedrock = self
		if not object.Name then
			object.Name = file.Type
		end

		object = env[file.Type]:Initialise(object)

		if file.Children then
			for i, obj in ipairs(file.Children) do
				local _view = self:ObjectFromFile(obj, object)
				if not _view.Z then
					_view.Z = i
				end
				_view.Parent = object
				table.insert(object.Children, _view)
			end
		end

		if not object.OnClick then
			object.OnClick = function(...) return self:ClickObject(...) end
		end
		--object.OnUpdate = function(...) self:UpdateObject(...) end

		if object.OnUpdate then
			for k, v in pairs(env[file.Type]) do
				object:OnUpdate(k)
			end

			for k, v in pairs(object.__index) do
				object:OnUpdate(k)
			end
		end

		if object.Active then
			object.Bedrock:SetActiveObject(object)
		end
		if object.OnLoad then
			object:OnLoad()
		end
		object.Ready = true
		return object
	elseif not file.Type then
		error('No object type specified. (e.g. Type = "Button")')
	else
		error('No Object: '..file.Type..'. The API probably isn\'t loaded')
	end
end

function ReorderObjects(self)
	if self.View and self.View.Children then
		self.View:ReorderObjects()
	end
end

function AddObject(self, info, extra, first)
	return self.View:AddObject(info, extra, first)
end

function GetObject(self, name)
	return self.View:GetObject(name)
end

function GetObjects(self, name)
	return self.View:GetObjects(name)
end

function RemoveObject(self, name)
	return self.View:RemoveObject(name)
end

function RemoveObjects(self, name)
	return self.View:RemoveObjects(name)
end

DrawEvent = nil

function HandleDraw(self, event, id)
	if id == self.DrawEvent then
		self.DrawEvent = nil
		self:Draw()
	end
end

function ForceDraw(self)
	if not self.DrawEvent then--or self.DrawTimerExpiry <= os.clock() then
		self.DrawEvent = math.random()
		os.queueEvent('bedrock_draw', self.DrawEvent)
		-- self:StartTimer(function()
		-- 	self.DrawTimer = nil
		-- 	self:Draw()
		-- end, 0.05)
		-- self.DrawTimerExpiry = os.clock() + 0.1
	end
end

function DisplayWindow(self, _view, title, canClose)
	if canClose == nil then
		canClose = true
	end
	if type(_view) == 'string' then
		local h = fs.open(self.ViewPath.._view..'.view', 'r')
		if h then
			_view = textutils.unserialize(h.readAll())
			h.close()
		end
	end

	self.Window = self:AddObject({Type = 'Window', Z = 999, Title = title, CanClose = canClose})
	_view.Type = 'View'
	_view.Name = 'View'
	_view.Z = 1
	_view.BackgroundColour = _view.BackgroundColour or colours.white
	self.Window:SetView(self:ObjectFromFile(_view, self.Window))
end

function DisplayAlertWindow(self, title, text, buttons, callback)
	local func = function(btn)
		self.Window:Close()
		if callback then
			callback(btn.Text)
		end
	end
	local children = {}
	local usedX = -1
	if buttons then
		for i, text in ipairs(buttons) do
			usedX = usedX + 3 + #text
			table.insert(children, {
				["Y"]="100%,-1",
				["X"]="100%,-"..usedX,
				["Name"]=text.."Button",
				["Type"]="Button",
				["Text"]=text,
				OnClick = func
			})
		end
	end

	local width = usedX + 2
	if width < 28 then
		width = 28
	end

	local canClose = true
	if buttons and #buttons~=0 then
		canClose = false
	end

	local height = 0
	if text then
		height = #Helpers.WrapText(text, width - 2)
		table.insert(children, {
			["Y"]=2,
			["X"]=2,
			["Width"]="100%,-2",
			["Height"]=height,
			["Name"]="Label",
			["Type"]="Label",
			["Text"]=text
		})
	end
	local view = {
		Children = children,
		Width=width,
		Height=3+height+(canClose and 0 or 1),
		OnKeyChar = function(_view, keychar)
			func({Text=buttons[1]})
		end
	}
	self:DisplayWindow(view, title, canClose)
end

function DisplayTextBoxWindow(self, title, text, callback, textboxText, cursorAtEnd)
	textboxText = textboxText or ''
	local children = {
		{
			["Y"]="100%,-1",
			["X"]="100%,-4",
			["Name"]="OkButton",
			["Type"]="Button",
			["Text"]="Ok",
			OnClick = function()
				local text = self.Window:GetObject('TextBox').Text
				self.Window:Close()
				callback(true, text)
			end
		},
		{
			["Y"]="100%,-1",
			["X"]="100%,-13",
			["Name"]="CancelButton",
			["Type"]="Button",
			["Text"]="Cancel",
			OnClick = function()
				self.Window:Close()
				callback(false)
			end
		}
	}

	local height = -1
	if text and #text ~= 0 then
		height = #Helpers.WrapText(text, 26)
		table.insert(children, {
			["Y"]=2,
			["X"]=2,
			["Width"]="100%,-2",
			["Height"]=height,
			["Name"]="Label",
			["Type"]="Label",
			["Text"]=text
		})
	end
	table.insert(children,
		{
			["Y"]=3+height,
			["X"]=2,
			["Width"]="100%,-2",
			["Name"]="TextBox",
			["Type"]="TextBox",
			["Text"]=textboxText,
			["CursorPos"]=(cursorAtEnd and #textboxText or 0)
		})
	local view = {
		Children = children,
		Width=28,
		Height=5+height+(canClose and 0 or 1),
	}
	self:DisplayWindow(view, title)
	self.Window:GetObject('TextBox').OnChange = function(txtbox, event, keychar)
		if keychar == keys.enter then
			self.Window:Close()
			callback(true, txtbox.Text)
		end
	end
	self:SetActiveObject(self.Window:GetObject('TextBox'))
	self.Window.OnCloseButton = function()callback(false)end
end

local function isFolder(path)
	local _fs = fs
	if OneOS then
		_fs = OneOS.FS
	end
	
	if not _fs.isDir(path) then
		return false
	end

	local extension
	if OneOS and OneOS.System then
		extension = OneOS.System.RealExtension(path)
	elseif self.System then
		extension = self.System.RealExtension(path)
	else
		extension = self.Helpers.Extension(path)
	end

	return extension == ''
end

function DisplayOpenFileWindow(self, title, callback)
	title = title or 'Open File'
	local func = function(btn)
		self.Window:Close()
		if callback then
			callback(btn.Text)
		end
	end

	local sidebarItems = {}

	--this is a really, really super bad way of doing it
	local separator = '                               !'
	
	local _fs = fs
	if OneOS then
		_fs = OneOS.FS
	end

	local function addFolder(path, level)
		for i, v in ipairs(_fs.list(path)) do
			local fPath = path .. '/' .. v
			if fPath ~= '/rom' and fPath ~= '/Favourites' and fPath ~= '/.git' and _fs.isDir(fPath) then
				if isFolder(fPath) then
					table.insert(sidebarItems, level .. v..separator..fPath)
					addFolder(fPath, level .. '  ')
				end
			end
		end
	end
	
	if OneOS then
		_fs = OneOS.FS
	end

	addFolder('','')

	local currentFolder = ''
	local selectedPath = nil

	local goToFolder = nil

	local children = {
		{
			["Y"]="100%,-2",
			["X"]=1,
			["Height"]=3,
			["Width"]="100%",
			["BackgroundColour"]=colours.lightGrey,
			["Name"]="SidebarListView",
			["Type"]="View"
		},
		{
			["Y"]="100%,-1",
			["X"]="100%,-4",
			["Name"]="OkButton",
			["Type"]="Button",
			["Text"]="Ok",
			["BackgroundColour"]=colours.white,
			["Enabled"]=false,
			OnClick = function()
				if selectedPath then
					self.Window:Close()
					callback(true, Helpers.TidyPath(selectedPath))
				end
			end
		},
		{
			["Y"]="100%,-1",
			["X"]="100%,-13",
			["Name"]="CancelButton",
			["Type"]="Button",
			["Text"]="Cancel",
			["BackgroundColour"]=colours.white,
			OnClick = function()
				self.Window:Close()
				callback(false)
			end
		},
		{
			["Y"]=1,
			["X"]=1,
			["Height"]="100%,-3",
			["Width"]="40%,-1",
			["Name"]="SidebarListView",
			["Type"]="ListView",
			["CanSelect"]=true,
			["Items"]={
				["Computer"] = sidebarItems
			},
			OnSelect = function(listView, text)
				local _,s = text:find(separator)
				if s then
					local path = text:sub(s + 1)
					goToFolder(path)
				end
			end,
			OnClick = function(listView, event, side, x, y)
				if y == 1 then
					goToFolder('/')
				end
			end
		},
		{
			["Y"]=1,
			["X"]="40%",
			["Height"]="100%,-3",
			["Width"]=1,
			["Type"]="Separator"
		},
		{
			["Y"]=1,
			["X"]="40%,2",
			["Width"]="65%,-3",
			["Height"]=1,
			["Type"]="Label",
			["Name"]="PathLabel",
			["TextColour"]=colours.lightGrey,
			["Text"]='/'
		},
		{
			["Y"]=2,
			["X"]="40%,1",
			["Height"]="100%,-4",
			["Width"]="65%,-1",
			["Name"]="FilesListView",
			["Type"]="ListView",
			["CanSelect"]=true,
			["Items"]={},
			OnSelect = function(listView, text)
				selectedPath = Helpers.TidyPath(currentFolder .. '/' .. text)
				self.Window:GetObject('OkButton').Enabled = true
			end,
			OnClick = function(listView, event, side, x, y)
				if y == 1 then
					goToFolder('/')
				end
			end
		},
	}
	local view = {
		Children = children,
		Width=40,
		Height= Drawing.Screen.Height - 4,
		OnCloseButton=function()
			callback(false)
		end
	}
	self:DisplayWindow(view, title)

	goToFolder = function(path)
		path = Helpers.TidyPath(path)
		self.Window:GetObject('PathLabel').Text = path
		currentFolder = path

		local filesListItems = {}
		for i, v in ipairs(_fs.list(path)) do
			if not isFolder(v .. '/' .. path) then
				table.insert(filesListItems, v)
			end
		end
		self.Window:GetObject('OkButton').Enabled = false
		selectedPath = nil
		self.Window:GetObject('FilesListView').Items = filesListItems

	end

	if startPath then
		goToFolder(startPath)
	elseif OneOS then
		goToFolder('/Desktop/Documents/')
	else
		goToFolder('')
	end

	self.Window.OnCloseButton = function()callback(false)end
end

function DisplaySaveFileWindow(self, title, callback, extension, startPath)
	local _fs = fs
	if extension and extension:sub(1,1) ~= '.' then
		extension = '.' .. extension
	end
	extension = extension or ''

	title = title or 'Save File'
	local func = function(btn)
		self.Window:Close()
		if callback then
			callback(btn.Text)
		end
	end

	local sidebarItems = {}

	--this is a really, really super bad way of doing it
	local separator = '                                                       !'

	local function addFolder(path, level)
		for i, v in ipairs(_fs.list(path)) do
			local fPath = path .. '/' .. v
			if fPath ~= '/rom' and fPath ~= '/Favourites' and fPath ~= '/.git' and _fs.isDir(fPath) then
				if isFolder(fPath) then
					table.insert(sidebarItems, level .. v..separator..fPath)
					addFolder(fPath, level .. '  ')
				end
			end
		end
	end
	
	if OneOS then
		_fs = OneOS.FS
	end
	addFolder('','')

	local currentFolder = ''
	local selectedPath = nil

	local goToFolder = nil

	local function updatePath()
		local text = self:GetObject('FileNameTextBox').Text
		if #text == 0 then
			self.Window:GetObject('OkButton').Enabled = false
			selectedPath = Helpers.TidyPath(currentFolder)
		else
			self.Window:GetObject('OkButton').Enabled = true
			selectedPath = Helpers.TidyPath(currentFolder .. '/' .. text .. extension)
		end
		self:GetObject('PathLabel').Text = selectedPath
	end

	local children = {
		{
			["Y"]="100%,-2",
			["X"]=1,
			["Height"]=3,
			["Width"]="100%",
			["BackgroundColour"]=colours.lightGrey,
			["Type"]="View"
		},
		{
			["Y"]="100%,-1",
			["X"]="100%,-4",
			["Name"]="OkButton",
			["Type"]="Button",
			["Text"]="Ok",
			["BackgroundColour"]=colours.white,
			["Enabled"]=false,
			OnClick = function()
				if selectedPath then
					local text = self:GetObject('FileNameTextBox').Text
					self.Window:Close()
					callback(true, selectedPath, text)
				end
			end
		},
		{
			["Y"]="100%,-1",
			["X"]="100%,-13",
			["Name"]="CancelButton",
			["Type"]="Button",
			["Text"]="Cancel",
			["BackgroundColour"]=colours.white,
			OnClick = function()
				self.Window:Close()
				callback(false)
			end
		},
		{
			["Y"]="100%,-2",
			["X"]=3,
			["Width"]="100%,-4",
			["Name"]="PathLabel",
			["Type"]="Label",
			["Text"]="/",
			["TextColour"]=colours.grey
		},
		{
			["Y"]="100%,-1",
			["X"]=3,
			["Width"]="100%,-17",
			["Name"]="FileNameTextBox",
			["Type"]="TextBox",
			["Placeholder"]="File Name",
			["Active"]=true,
			["BackgroundColour"]=colours.white,
			OnChange = function(_self, event, keychar)
				if keychar == keys.enter then
					self:GetObject('OkButton'):OnClick()
				else
					updatePath()
				end
			end
		},
		{
			["Y"]=1,
			["X"]=2,
			["Height"]="100%,-3",
			["Width"]="100%,-1",
			["Name"]="SidebarListView",
			["Type"]="ListView",
			["CanSelect"]=true,
			["Items"]={
				["Computer"] = sidebarItems
			},
			OnSelect = function(listView, text)
				local _,s = text:find(separator)
				if s then
					local path = text:sub(s + 1)
					goToFolder(path)
				end
			end,
			OnClick = function(listView, event, side, x, y)
				if y == 1 then
					goToFolder('/')
				end
			end
		},
	}
	local view = {
		Children = children,
		Width=35,
		Height= Drawing.Screen.Height - 4,
		OnCloseButton=function()
			callback(false)
		end
	}
	self:DisplayWindow(view, title)

	self:SetActiveObject(self.Window:GetObject('FileNameTextBox'))

	goToFolder = function(path)
		path = Helpers.TidyPath(path)
		currentFolder = path
		selectedPath = nil
		updatePath()
	end

	if startPath then
		goToFolder(startPath)
	elseif OneOS then
		goToFolder('/Desktop/Documents/')
	else
		goToFolder('')
	end

	self.Window.OnCloseButton = function()callback(false)end
end

function RegisterEvent(self, event, func)
	if not self.EventHandlers[event] then
		self.EventHandlers[event] = {}
	end
	table.insert(self.EventHandlers[event], func)
end

function StartRepeatingTimer(self, func, interval)
	local int = interval
	if type(int) == 'function' then
		int = int()
	end
	if not int or int <= 0 then
		return
	end
	local timer = os.startTimer(int)

	self.Timers[timer] = {func, true, interval}
	return timer
end

function StartTimer(self, func, delay)
	local timer = os.startTimer(delay)
	self.Timers[timer] = {func, false}
	return timer
end

function StopTimer(self, timer)
	if self.Timers[timer] then
		self.Timers[timer] = nil
	end
end

function HandleTimer(self, event, timer)
	if self.Timers[timer] then
		local oldTimer = self.Timers[timer]
		self.Timers[timer] = nil
		local new = nil
		if oldTimer[2] then
			new = self:StartRepeatingTimer(oldTimer[1], oldTimer[3])
		end
		if oldTimer and oldTimer[1] then
			oldTimer[1](new, timer)
		end
	elseif self.OnTimer then
		self.OnTimer(self, event, timer)
	end
end

function HandlePaste(self, event, text)
	local activeObject = self:GetActiveObject()
	if activeObject and activeObject.OnPaste then
		activeObject:OnPaste(event, text)
	end
end

function SetActiveObject(self, object)
	if object then
		if object ~= self.ActiveObject then
			self.ActiveObject = object
			object:ForceDraw()
		end
	elseif self.ActiveObject ~= nil then
		self.ActiveObject = nil
		self.CursorPos = nil
		self.View:ForceDraw()
	end
end

function GetActiveObject(self)
	return self.ActiveObject
end

OnTimer = nil
OnClick = nil
OnKeyChar = nil
OnDrag = nil
OnScroll = nil
OnViewLoad = nil
OnViewClose = nil
OnDraw = nil
OnQuit = nil

local eventFuncs = {
	OnClick = {'mouse_click', 'monitor_touch'},
	OnKeyChar = {'key', 'char'},
	OnDrag = {'mouse_drag'},
	OnScroll = {'mouse_scroll'},
	HandleClick = {'mouse_click', 'mouse_drag', 'mouse_scroll', 'monitor_touch'},
	HandleKeyChar = {'key', 'char'},
	HandlePaste = {'paste'},
	HandleTimer = {'timer'},
	HandleDraw = {'bedrock_draw'}
}

local drawCalls = 0
local ignored = 0
function Draw(self)
	self.IsDrawing = true
	if self.OnDraw then
		self:OnDraw()
	end

	if self.View and self.View:NeedsDraw() then
		self.View:Draw()
		Drawing.DrawBuffer()
		if isDebug then
			drawCalls = drawCalls + 1
		end
	elseif not self.View then
		print('No loaded view. You need to do program:LoadView first.')
	end	

	if self:GetActiveObject() and self.CursorPos and type(self.CursorPos[1]) == 'number' and type(self.CursorPos[2]) == 'number' and self.CursorPos[1] >= 1 and self.CursorPos[1] <= Drawing.Screen.Width and self.CursorPos[2] >= 1 and self.CursorPos[2] <= Drawing.Screen.Height then
		term.setCursorPos(self.CursorPos[1], self.CursorPos[2])
		term.setTextColour(self.CursorColour)
		term.setCursorBlink(true)
	else
		term.setCursorBlink(false)
	end

	self.IsDrawing = false
end

function EventHandler(self)
	local event = { os.pullEventRaw() }
	
	if self.EventHandlers[event[1]] then
		for i, e in ipairs(self.EventHandlers[event[1]]) do
			e(self, unpack(event))
		end
	end
end

function Quit(self)
	self.Running = false
	if self.OnQuit then
		self:OnQuit()
	end
	if OneOS then
		OneOS.Close()
	end
end

function Run(self, ready)
	-- Bypass the window API
	-- This doesn't really work...
	-- term.redirect(term.native())
	-- if term.native then
	-- 	if type(term.native) == 'function' then
	-- 		term.redirect(term.native())
	-- 	else
	-- 		term.redirect(term.native)
	-- 	end
	-- end
	
	if not  term.isColour or not term.isColour() then
		print('This program requires an advanced (golden) comptuer to run, sorry.')
		error('', 0)
	end

	for name, events in pairs(eventFuncs) do
		if self[name] then
			for i, event in ipairs(events) do
				self:RegisterEvent(event, self[name])
			end
		end
	end

	if self.AllowTerminate then
		self:RegisterEvent('terminate', function()error('Terminated', 0) end)
	end

	if self.DefaultView and self.DefaultView ~= '' and fs.exists(self.ViewPath..self.DefaultView..'.view') then
		self:LoadView(self.DefaultView)
	end

	if ready then
		ready()
	end
	
	self:Draw()

	while self.Running do
		self:EventHandler()
	end
end