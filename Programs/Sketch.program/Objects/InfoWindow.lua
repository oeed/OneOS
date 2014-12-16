Inherit = 'SnapWindow'
ContentViewName = 'infowindow'

Title = 'Info'

OnContentLoad = function(self)
	self:UpdateInfo()
end

UpdateInfo = function(self)
	local artboard = self.Bedrock:GetObject('Artboard')
	local selection = (artboard == nil or artboard.Selection == nil or artboard.Selection[1] == nil or artboard.Selection[2] == nil)
	self:GetObject("CanvasWidthLabel").Text = (artboard == nil and '-' or tostring(#artboard:GetCurrentLayer().Layer.Pixels))
	self:GetObject("CanvasHeightLabel").Text = (artboard == nil and '-' or tostring(#artboard:GetCurrentLayer().Layer.Pixels[1]))
	self:GetObject("SelectionWidthLabel").Text = (selection and '-' or tostring(math.abs(artboard.Selection[1].X-artboard.Selection[2].X)))
	self:GetObject("SelectionHeightLabel").Text = (selection and '-' or tostring(math.abs(artboard.Selection[1].Y-artboard.Selection[2].Y)))
	self:GetObject("SelectionX1Label").Text = (selection and '-' or tostring(artboard.Selection[1].X))
	self:GetObject("SelectionY1Label").Text = (selection and '-' or tostring(artboard.Selection[1].Y))
	self:GetObject("SelectionX2Label").Text = (selection and '-' or tostring(artboard.Selection[2].X))
	self:GetObject("SelectionY2Label").Text = (selection and '-' or tostring(artboard.Selection[2].Y))
end