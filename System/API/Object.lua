	X = 1
	Y = 1
	Width = 0
	Height = 0
	Parent = nil
	OnClick = nil
	Visible = true
	Name = nil 

	DrawCache = {}

	local function drawCache(evokers)
		return {
			--any aspects that, if changed, require redrawing
			Evokers = evokers,
			NeedsDraw = true,
			AlwaysDraw = false,
			Buffer = {}
		}
	end
	
	NeedsDraw = function(self)
		if not self.DrawCache.Buffer or self.DrawCache.AlwaysDraw or self.DrawCache.NeedsDraw then 
			return true
		end

		for k, v in pairs(self.DrawCache.Evokers) do
			if self[k] ~= v then
				return true
			end
		end
	end

	UpdateEvokers = function(self)
		local evokers = {}
		for k, v in pairs(self.DrawCache.Evokers) do
			evokers[k] = self[k]
			if self.OnUpdate then
				if self:OnUpdate(k) then
					return
				end
			end
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
		self:UpdateEvokers()
	end

	Initialise = function(self)
		local new = {}    -- the new instance
		setmetatable( new, {__index = self} )
		local evokers = {}
		for k, v in pairs(new) do
			if type(v) ~= 'function' then
				evokers[k] = false
			end
		end
		new.DrawCache = drawCache(evokers)
		new:UpdateEvokers()
		return new
	end

	Click = function(self, side, x, y)
		if self.Visible and self.OnClick then
			self:OnClick(side, x, y)
			return true
		else
			return false
		end
	end