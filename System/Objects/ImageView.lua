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