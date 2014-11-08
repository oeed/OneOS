Inherit = 'View'
Width = 13
Height = 8
PreviewWidth = 12
PreviewHeight = 5
Program = nil
Preview = nil
Icon = nil
Minimal = false

OnLoad = function(self)
	if self.Program then
		self:UpdatePreview()
		local path = Helpers.ParentFolder(self.Program.Path)..'/icon'
		self.Icon = Drawing.LoadImage(path)
	end
end

UpdatePreview = function(self)
	if self.Program then
		if self.Minimal then
			self.PreviewWidth = self.Width
			self.PreviewHeight = self.Height
		end
		self.Preview = self.Program:RenderPreview(self.PreviewWidth, self.PreviewHeight)
		self:ForceDraw()
	end
end

OnDraw = function(self, x, y)
	if self.Program then
		if not self.Minimal then
			Drawing.DrawBlankArea(x + 1, y + 2, self.PreviewWidth, self.PreviewHeight, colours.grey)
		end

		local startY = 0
		if self.Minimal then
			startY = -1
		end
		for _x, col in pairs(self.Preview) do
			for _y, colour in ipairs(col) do
				local char = '-'
				if colour[1] == ' ' then
					char = ' '
				end
				Drawing.WriteToBuffer(x+_x-1, y+_y+startY, char, colour[2], colour[3])--' ', colours.black, colour)
			end
		end
		
		if not self.Minimal then
			Drawing.DrawCharactersCenter(x + 1, y, self.PreviewWidth - 1, 1, Helpers.TruncateString(self.Program.Title, self.Width - 2), colours.white, colours.transparent)
			if self.Icon then
				Drawing.DrawImage(x + self.PreviewWidth - 4, y + self.PreviewHeight - 2, self.Icon, 4, 3)
			end

			if not self.Program.Hidden then
				Drawing.DrawCharacters(x, y, 'x', colours.red, colours.transparent)
			end
		end
	end
end