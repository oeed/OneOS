X = 1
Y = 1
Width = 1
Height = 1
Parent = nil
OnClick = nil
Visible = true
IgnoreClick = false
Name = nil 
ClipDrawing = true
UpdateDrawBlacklist = {}
Fixed = false

DrawCache = {}

NeedsDraw = function(self)
	if not self.Visible then
		return false
	end
	
	if not self.DrawCache.Buffer or self.DrawCache.AlwaysDraw or self.DrawCache.NeedsDraw then
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

GetPosition = function(self)
	return self.Bedrock:GetAbsolutePosition(self)
end

GetOffsetPosition = function(self)
	if not self.Parent then
		return {X = 1, Y = 1}
	end

	local offset = {X = 0, Y = 0}
	if not self.Fixed and self.Parent.ChildOffset then
		offset = self.Parent.ChildOffset
	end

	return {X = self.X + offset.X, Y = self.Y + offset.Y}
end

Draw = function(self)
	if not self.Visible then
		return
	end

	self.DrawCache.NeedsDraw = false
	local pos = self:GetPosition()
	Drawing.StartCopyBuffer()

	if self.ClipDrawing then
		Drawing.AddConstraint(pos.X, pos.Y, self.Width, self.Height)
	end

	if self.OnDraw then
		self:OnDraw(pos.X, pos.Y)
	end

	self.DrawCache.Buffer = Drawing.EndCopyBuffer()
	
	if self.Children then
		for i, child in ipairs(self.Children) do
			local pos = child:GetOffsetPosition()
			if pos.Y + self.Height > 1 and pos.Y <= self.Height and pos.X + self.Width > 1 and pos.X <= self.Width then
				child:Draw()
			end
		end
	end

	if self.ClipDrawing then
		Drawing.RemoveConstraint()
	end	
end

ForceDraw = function(self, ignoreChildren, ignoreParent, ignoreBedrock)
	if not ignoreBedrock and self.Bedrock then
		self.Bedrock:ForceDraw()
	end
	self.DrawCache.NeedsDraw = true
	if not ignoreParent and self.Parent then
		self.Parent:ForceDraw(true, nil, true)
	end
	if not ignoreChildren and self.Children then
		for i, child in ipairs(self.Children) do
			child:ForceDraw(nil, true, true)
		end
	end
end

OnRemove = function(self)
	if self == self.Bedrock:GetActiveObject() then
		self.Bedrock:SetActiveObject()
	end
end

Initialise = function(self, values)
	local _new = values    -- the new instance
	_new.DrawCache = {
		NeedsDraw = true,
		AlwaysDraw = false,
		Buffer = nil
	}
	setmetatable(_new, {__index = self} )

	local new = {} -- the proxy
	setmetatable(new, {
		__index = _new,

		__newindex = function (t,k,v)
			if v ~= _new[k] then
				_new[k] = v
				if t.OnUpdate then
					t:OnUpdate(k)
				end

				if t.UpdateDrawBlacklist[k] == nil then
					t:ForceDraw()
				end
			end
		end
	})
	if new.OnInitialise then
		new:OnInitialise()
	end

	return new
end

Click = function(self, event, side, x, y)
	if self.Visible and not self.IgnoreClick then
		if event == 'mouse_click' and self.OnClick and self:OnClick(event, side, x, y) ~= false then
			return true
		elseif event == 'mouse_drag' and self.OnDrag and self:OnDrag(event, side, x, y) ~= false then
			return true
		elseif event == 'mouse_scroll' and self.OnScroll and self:OnScroll(event, side, x, y) ~= false then
			return true
		else
			return false
		end
	else
		return false
	end

end

ToggleMenu = function(self, name, x, y)
	return self.Bedrock:ToggleMenu(name, self, x, y)
end

function OnUpdate(self, value)
	if value == 'Z' then
		self.Bedrock:ReorderObjects()
	end
end