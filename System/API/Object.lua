X = 1
Y = 1
Width = 1
Height = 1
Parent = nil
OnClick = nil
Visible = true
Name = nil 

DrawCache = {}

NeedsDraw = function(self)
	if not self.Visible then
		return false
	end
	
	if not self.DrawCache.Buffer or self.DrawCache.AlwaysDraw or self.DrawCache.NeedsDraw then 
		if not self.DrawCache.Buffer then
			if self.OnUpdate then
				for k, v in pairs(self.DrawCache.Evokers) do
					self:OnUpdate(k)
				end
				self:UpdateEvokers()
			end
		end
		return true
	end

	local needsUpdate = false
	for k, v in pairs(self.DrawCache.Evokers) do
		if self[k] ~= v then
			needsUpdate = true
			if self.Parent then
				self.Parent.DrawCache.NeedsDraw = true
			end
			if self.OnUpdate then
				if self:OnUpdate(k) then
					--return
				end
			end
		end
	end

	if needsUpdate then
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

UpdateEvokers = function(self)
	local evokers = {}
	if not self.DrawCache.Evokers then print('*')  print('*') print(self.DrawCache) print(self.Name) end
	for k, v in pairs(self.DrawCache.Evokers) do
		evokers[k] = self[k]
	end
	self.DrawCache.Evokers = evokers
end

GetPosition = function(self)
	return self.Bedrock:GetAbsolutePosition(self)
end

Draw = function(self)
	if not self.Visible then
		return
	end

	if self:NeedsDraw() then
		self.DrawCache.NeedsDraw = false
		local pos = self:GetPosition()
		Drawing.StartCopyBuffer()
		if self.OnDraw then
			self:OnDraw(pos.X, pos.Y)
		end
		self.DrawCache.Buffer = Drawing.EndCopyBuffer()
	else
		Drawing.DrawCachedBuffer(self.DrawCache.Buffer)
	end

	if self.Children then
		for i, child in ipairs(self.Children) do
			child:Draw()
		end
	end

	self:UpdateEvokers()
end

ForceDraw = function(self)
	self.DrawCache.NeedsDraw = true
	if self.Parent then
		self.Parent:ForceDraw()
	end
end

--TODO: look in to using metatables to handle when values are changed
Initialise = function(self)
	local new = {}    -- the new instance
	setmetatable( new, {__index = self} )
	local evokers = {}
	--TODO: a better way of doing this
	for k, v in pairs(self) do
		if type(v) ~= 'function' then
			evokers[k] = false
		end
	end

	for k, v in pairs(new.__index) do
		if type(v) ~= 'function' then
			evokers[k] = false
		end
	end
	new.DrawCache = {
		--any aspects that, if changed, require redrawing
		Evokers = evokers,
		NeedsDraw = true,
		AlwaysDraw = false,
		Buffer = nil
	}
	new:UpdateEvokers()
	return new
end

Click = function(self, event, side, x, y)
	if self.Visible and self.OnClick then
		self:OnClick(event, side, x, y)
		return true
	else
		return false
	end
end

ToggleMenu = function(self, name)
	return self.Bedrock:ToggleMenu(name, self)
end