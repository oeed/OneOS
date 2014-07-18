TextColour = colours.black
BackgroundColour = colours.transparent
Text = ""
AutoWidth = false
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
	for i, v in ipairs(wrapText(self.Text, self.Width)) do
        local _x = 0
        if self.Align == 'Right' then
            _x = self.Width - #v
        elseif self.Align == 'Center' then
            _x = math.floor((self.Width - #v) / 2)
        end
		Drawing.DrawCharacters(x + _x, y + i - 1, v, self.TextColour, self.BackgroundColour)
	end
end