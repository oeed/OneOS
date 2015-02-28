Inherit = 'PageView'

OnNext = function(self)
	local text = self:GetObject('NameTextBox').Text
	os.setComputerLabel((#text ~= 0 and text or nil))
end