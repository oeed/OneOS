TextColour = colours.black
BackgroundColour = colours.transparent
Text = ""
AutoWidth = false

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

OnDraw = function(self, x, y)
	for i, v in ipairs(wrapText(self.Text, self.Width)) do
        local _x = 0
        if self.Align == 'Right' then
            _x = self.Width - #self.Text
        elseif self.Align == 'Center' then
            _x = math.floor((self.Width - #self.Text) / 2) - 1
        end
		Drawing.DrawCharacters(x + _x, y + i - 1, v, self.TextColour, self.BackgroundColour)
	end
end