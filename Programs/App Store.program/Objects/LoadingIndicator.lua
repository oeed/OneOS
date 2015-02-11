Width = 7
Height = 5

Step = 1

UpdateDrawBlacklist = {
	['Step'] = true,
}

OnDraw = function(self, x, y)
	local reverseStep = 9
	local resetStep = 18
	if self.Step > resetStep then
		self.Step = 0
	end

	self.Step = self.Step + 1

	for i = 0, 3 do
		local _y = math.min(math.max(0, self.Step - 2 * i), 3)
		if self.Step > reverseStep then
			_y = 3 - math.min(math.max(0, self.Step - reverseStep - 2 * i), 3)
		end

		local colour = (_y == 3 and colours.blue or (_y == 0 and colours.white or colours.lightBlue))
		Drawing.WriteToBuffer(x + i * 2, y + _y - 1, ' ', colours.black, colour)
	end

	Drawing.DrawCharacters(x, y + 4, 'Loading', colours.blue, colours.transparent)

	self.Bedrock:StartTimer(function()
		self:ForceDraw()
	end, 0.05)
end