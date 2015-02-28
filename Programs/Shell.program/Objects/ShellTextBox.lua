Inherit = 'TextBox'

BackgroundColour = colours.transparent
TextColour = colours.blue
SuggestionTextColour = colours.lightBlue

DrawText = function(self, x, y, text)
	Drawing.DrawCharacters(x, y, self:SuggestedText(text), self.SuggestionTextColour, colours.transparent)
	Drawing.DrawCharacters(x, y, text, self.TextColour, colours.transparent)
end

DrawPlaceholder = function(self, x, y)
	Drawing.DrawCharacters(x, y, self.Placeholder, self.PlaceholderTextColour, self.BackgroundColour)
end

DrawSelectedText = function(self, x, y, text, startPos, endPos)
	for i = 1, #text do
		local char = text:sub(i, i)
		local textColour = self.TextColour
		local backgroundColour = self.BackgroundColour

		if i > startPos and i - 1 <= endPos then
			textColour = self.SelectedTextColour
			backgroundColour = self.SelectedBackgroundColour
		end
		Drawing.DrawCharacters(x + i - 1, y, char, textColour, backgroundColour)
	end
end

CustomOnKeyChar = function(self, event, keychar)
	if event == 'key' and keychar == keys.tab then
		self.Text = self:SuggestedText(self.Text) .. ' '
		self.CursorPos = #self.Text
		return true
	end
end

SuggestedText = function(self, text)
	return ShellSuggestions.SuggestedText(text)
end