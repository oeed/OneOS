	X = 1
	Y = 1
	Width = 0
	Height = 0
	Parent = nil
	OnClick = nil
	Visible = true
	Name = nil 

	DrawCache = {}
	
	NeedsDraw = function(self)
		if not self.DrawCache.Buffer or self.DrawCache.AlwaysDraw or self.DrawCache.NeedsDraw then 
			if not self.DrawCache.Buffer then
				if self.OnUpdate then
					for k, v in pairs(self.DrawCache.Evokers) do
						self:OnUpdate(k)
					end
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

		--[[
		This may or may not be needed

		if self.Children then
			for i, v in ipairs(self.Children) do
				if v:NeedsDraw() then
					return true
				end
			end
		end
		
		]]--

		if needsUpdate then
			return true
		end
	end

	UpdateEvokers = function(self)
		local evokers = {}
		for k, v in pairs(self.DrawCache.Evokers) do
			evokers[k] = self[k]
		end
		self.DrawCache.Evokers = evokers
	end

	Draw = function(self)
		if not self.Visible then
			return
		end

		if self:NeedsDraw() then
			local pos = self.Bedrock:GetAbsolutePosition(self)
			Drawing.StartCopyBuffer()
			if self.OnDraw then
				self:OnDraw(pos.X, pos.Y)
			end
			self.DrawCache.Buffer = Drawing.EndCopyBuffer()
			self.DrawCache.NeedsDraw = false
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

	Initialise = function(self)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		local evokers = {}
		for k, v in pairs(self) do
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