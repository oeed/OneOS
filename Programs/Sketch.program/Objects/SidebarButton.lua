Inherit = 'Button'

X = 1
Width = 3
Height = 1
AutoWidth = false

TextColour = colours.white
ActiveTextColour = colours.lightGrey

WindowDocked = false
Window = false

OnDraw = function(self, x, y)
	local text = self.Text
	if self.WindowDocked then
		text = ' > '
	end

	local textColour = self.TextColour
	if self.Toggle then
		textColour = self.ActiveTextColour
	end
	if not self.Enabled then
		textColour = self.DisabledTextColour
	end

	Drawing.DrawCharacters(x, y, text, textColour, colours.transparent)
end


OnClick = function(self, event, side, x, y)
	if event == 'mouse_click' then
		if self.WindowName and not self.Window then
			self.Window = self.Bedrock:AddObject({
				["Y"]=(self.Bedrock:GetAbsolutePosition(self)).Y,
				["Type"]=self.WindowName,
				["Docked"]=true,
				OnDockChange = function(_self, state)
					self.WindowDocked = state
					if state then
						_self.Y = (self.Bedrock:GetAbsolutePosition(self)).Y
						_self.X = Drawing.Screen.Width - _self.Width - 2
						self.Parent:OnDock()
					end
				end,
				OnClose = function(_self)
					self.Window = nil
					self.WindowDocked = false
				end
			})
			self.Window.X = Drawing.Screen.Width - self.Window.Width - 2
			self.Parent:CloseDocked()
			self.WindowDocked = true
		else
			self.Window:Close()
		end
	end
end