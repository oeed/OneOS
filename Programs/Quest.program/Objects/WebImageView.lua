URL = false
Image = false

OnDraw = function(self, x, y)
	if not self.Image then
		Drawing.DrawBlankArea(x, y, self.Width, self.Height, colours.lightGrey)
	elseif self.Format == 'nft' then
		Drawing.DrawImage(x, y, self.Image, self.Width, self.Height)
	elseif self.Format == 'nfp' or self.Format == 'paint' then
		for _x, col in ipairs(self.Image) do
			for _y, colour in ipairs(col) do
	            Drawing.WriteToBuffer(x+_x-1, y+_y-1, ' ', colours.white, colour)
			end
		end
	elseif self.Format == 'skch' or self.Format == 'sketch' then
		Drawing.DrawImage(x, y, self.Image, self.Width, self.Height)
	end
end

OnUpdate = function(self, value)
	if value == 'URL' and self.URL then
		fetchHTTPAsync(resolveFullUrl(self.URL), function(ok, event, response)
			if ok then
				local width, height = self.Width, self.Height

				local lines = {}
				for line in response.readLine do
					table.insert(lines, line)
				end
				response.close()
				local content = table.concat(lines, '\n')

				if not self.Format then
					self.Format = self:DetermineFormat(content)
				end

				if self.Format == 'nft' then
					self.Image, self.Width, self.Height = self:ReadNFT(lines)
				elseif self.Format == 'nfp' or self.Format == 'paint' then
					self.Image, self.Width, self.Height = self:ReadNFP(lines)
				elseif self.Format == 'skch' or self.Format == 'sketch' then
					self.Image, self.Width, self.Height = self:ReadSKCH(content)
				end
				if (width ~= self.Width or height ~= self.Height) then
					self.Bedrock:GetObject('WebView'):RepositionLayout()
				end
			end
		end)
	end
end

DetermineFormat = function(self, content)
	if type(textutils.unserialize(content)) == 'table' then
		-- It's a serlized table, asume sketch
		return 'skch'
	elseif string.find(content, string.char(30)) or string.find(content, string.char(31)) then
		-- Contains the characters that set colours, asume nft
		return 'nft'
	else
		-- Otherwise asume nfp
		return 'nfp'
	end
end

ReadSKCH = function(self, content)
	local _layers = textutils.unserialize(content)
	local layers = {}

	local width, height = 1, 1

	for i, layer in ipairs(_layers) do
		if layer.Visible then
			local nft, w, h = self:ReadNFT(layer.Pixels)
			if w > width then
				width = w
			end
			if h > height then
				height = h
			end
			table.insert(layers, nft)
		end
	end

	--flatten the layers
	local image = {
		text = {},
		textcol = {}
	}

	for i, layer in ipairs(layers) do
		for y, row in ipairs(layer) do
			if not image[y] then
				image[y] = {}
			end
			for x, pixel in ipairs(row) do
				if not image[y][x] or pixel ~= colours.transparent then
					image[y][x] = pixel
				end
			end
		end
		for y, row in ipairs(layer.text) do
			if not image.text[y] then
				image.text[y] = {}
			end
			for x, pixel in ipairs(row) do
				if not image.text[y][x] or pixel ~= ' ' then
					image.text[y][x] = pixel
				end
			end
		end
		for y, row in ipairs(layer.textcol) do
			if not image.textcol[y] then
				image.textcol[y] = {}
			end
			for x, pixel in ipairs(row) do
				if not image.textcol[y][x] or layer.text[y][x] ~= ' ' then
					image.textcol[y][x] = pixel
				end
			end
		end
	end

	return image, width, height
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

ReadNFP = function(self, lines)
	local image = {}
	local y = 1
	for y, line in ipairs(lines) do
		for x = 1, #line do
			if not image[x] then
				image[x] = {}
			end
			image[x][y] = getColourOf(line:sub(x,x))
		end
		line = file.readLine()
	end
	file.close()
 	return image, #image, #image[1]
end

ReadNFT = function(self, lines)
	local image = {
		text = {},
		textcol = {}
	}
	for num, sLine in ipairs(lines) do
        table.insert(image, num, {})
        table.insert(image.text, num, {})
        table.insert(image.textcol, num, {})
        local writeIndex = 1
        local bgNext, fgNext = false, false
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
    end
 	return image, #image[1], #image
end
