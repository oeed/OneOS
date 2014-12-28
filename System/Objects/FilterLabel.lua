Inherit = 'Label'
Passes = 1

OnLoad = function(self)
	self:OnUpdate('FilterName')
end

OnUpdate = function(self, value)
	if value == 'FilterName' then
		self.Filter = Drawing.Filters[self.FilterName]
	elseif value == 'Text' then
        if self.AutoWidth then
            self.Width = #self.Text
        else
            self.Height = #self.Bedrock.Helpers.WrapText(self.Text, self.Width)
        end
	end
end

OnDraw = function(self, x, y)
	local filter = self.Filter
	for i, v in ipairs(self.Bedrock.Helpers.WrapText(self.Text, self.Width)) do
        local _x = 0
        if self.Align == 'Right' then
            _x = self.Width - #v
        elseif self.Align == 'Center' then
            _x = math.floor((self.Width - #v) / 2)
        end

        for c = 1, #v do
			if Drawing.Buffer[y + i - 1] and Drawing.Buffer[y + i - 1][x + _x + c - 1] then
				local px = Drawing.Buffer[y + i - 1][x + _x + c - 1]
				-- error(Drawing.FilterColour(px[2], filter)) 
				-- error(y + i - 1)
				-- Drawing.DrawCharacters(x + _x + c - 1, y + i - 1, 'a', colors.black, self.BackgroundColour)
				local colour = px[3]
				for i = 1, self.Passes do
					colour = Drawing.FilterColour(colour, filter)
				end
				if colour == px[3] then
					colour = colours.white
				end
				Drawing.WriteToBuffer(x + _x + c - 1, y + i - 1, v:sub(c, c), colour, self.BackgroundColour)
        	end
        end
	end
end

