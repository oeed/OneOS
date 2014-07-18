Inherit = 'View'

BackgroundColour = colours.transparent
Computers = false

local function AddComputer(self, computer, angle, radius)
	--sohcahtoa
	local vertexX, vertexY = Drawing.Screen.Width/2, Drawing.Screen.Height - 2
	width = (radius * math.sin(-angle/90)) * 1.5 -- to fix the pixel ratio
	height = radius * math.cos(-angle/90)

	local centerX = 1 + (Drawing.Screen.Width/2) - width
	local centerY = vertexY - height

	local imageView = self:AddObject({
		["Type"] = 'ImageView',
		["Width"] = 5,
		["Height"] = 4,
		["X"] = centerX - 3,
		["Y"] = centerY - 2,
		["Path"] = '/Images/computer'
	})

	local name = Helpers.TruncateString(computer.Name,13)
	local label = self:AddObject({
		["Type"] = 'Label',
		["X"] = math.floor(centerX - (#name / 2)),
		["Y"] = centerY + 3,
		["Text"] = name
	})

	label.OnClick = function()
		SendToComputer(computer)
	end
	imageView.OnClick = label.OnClick
end

OnUpdate = function(self, value)
	if value == 'Computers' and self.Computers then
		self:RemoveAllObjects()

		while #self.Computers > 4 do
			table.remove(self.Computers, #self.Computers)
		end

		local max = #self.Computers
		local separationAngle = 75
		for i, computer in ipairs(self.Computers) do
			local angle = 0
			if max % 2 == 0 then
				if max/2 == i then
					angle = separationAngle/2
				elseif max/2 == i - 1 then
					angle = -separationAngle/2
				else
					angle = separationAngle * (i - max/2) - separationAngle/2
				end
			else
				if math.ceil(max/2) == i then
					angle = 0
				else
					angle = separationAngle * (i - math.ceil(max/2))
				end
			end
			AddComputer(self, computer, angle, 12)
		end
	end
end