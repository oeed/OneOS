Inherit = 'PageView'

OnPageLoad = function(self)
	self:GetObject('DesktopBackgroundColourPicker').ActiveColour = OneOS.System.Settings.DesktopColour

	self:GetObject('DesktopBackgroundColourPicker').OnChange = function(_, value)
		OneOS.System.Settings.DesktopColour = value
	end
	self:GetObject('UseAnimationsSwitch').Toggle = OneOS.System.Settings.UseAnimations

	self:GetObject('UseAnimationsSwitch').OnChange = function(_, value)
		OneOS.System.Settings.UseAnimations = value
	end
end