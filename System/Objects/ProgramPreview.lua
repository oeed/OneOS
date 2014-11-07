Inherit = 'View'
Width = 13
Height = 8
PreviewWidth = 12
PreviewHeight = 5
Program = nil
Preview = nil
Icon = nil

OnLoad = function(self)
	if self.Program and self.Program.Running then
		self.Preview = Current.Program:RenderPreview(self.PreviewWidth, self.PreviewHeight)
		local path = Helpers.ParentFolder(self.Program.Path)..'/icon'
		self.Icon = Drawing.LoadImage(path)
	end
end

OnDraw = function(self, x, y)
	if self.Program and self.Program.Running then
		Drawing.DrawBlankArea(x + 1, y + 2, self.PreviewWidth, self.PreviewHeight, colours.grey)
		Drawing.DrawBlankArea(x, y + 1, self.PreviewWidth, self.PreviewHeight, colours.white)

		for _x, col in pairs(self.Preview) do
			for _y, colour in ipairs(col) do
				local char = '-'
				if colour[1] == ' ' then
					char = ' '
				end
				Drawing.WriteToBuffer(x+_x-1, y+_y, char, colour[2], colour[3])--' ', colours.black, colour)
			end
		end

		Drawing.DrawCharactersCenter(x + 1, y, self.PreviewWidth - 1, 1, Helpers.TruncateString(self.Program.Title, self.Width - 2), colours.white, colours.transparent)
		-- local img = Drawing.LoadImage(self.Program.Path..'/icon')--Helpers.IconForFile('/System/Program/Files.program')
		if self.Icon then
			Drawing.DrawImage(x + self.PreviewWidth - 4, y + self.PreviewHeight - 2, self.Icon, 4, 3)
		end
		Drawing.DrawCharacters(x, y, 'x', colours.red, colours.transparent)

	end
end

OnClick = function(self, event, side, x, y)
	
end