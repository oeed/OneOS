	Name = nil
	PeripheralType = 'printer'

	local TextLine = {
		Text = "",
		Alignment = AlignmentLeft,

		Initialise = function(self, text, alignment)
			local new = {}    -- the new instance
			setmetatable( new, {__index = self} )
			new.Text = text
			new.Alignment = alignment or AlignmentLeft
			return new
		end
	}

	function paperLevel(self)
		return Peripheral.CallNamed(self.Name, 'getPaperLevel')
	end

	function newPage(self)
		return Peripheral.CallNamed(self.Name, 'newPage')
	end

	function endPage(self)
		return Peripheral.CallNamed(self.Name, 'endPage')
	end

	function pageWrite(self, text)
		return Peripheral.CallNamed(self.Name, 'write', text)
	end

	function setPageTitle(self, title)
		return Peripheral.CallNamed(self.Name, 'setPageTitle', title)
	end

	function inkLevel(self)
		return Peripheral.CallNamed(self.Name, 'getInkLevel')
	end

	function getCursorPos(self)
		return Peripheral.CallNamed(self.Name, 'getCursorPos')
	end

	function setCursorPos(self, x, y)
		return Peripheral.CallNamed(self.Name, 'setCursorPos', x, y)
	end

	function pageSize(self)
		return Peripheral.CallNamed(self.Name, 'getPageSize')
	end

	function Present()
		if Peripheral.GetPeripheral(PeripheralType) == nil then
			return false
		else
			return true
		end
	end

	local function StripColours(str)
		return str:gsub('['..string.char(14)..'-'..string.char(29)..']','')
	end

	function PrintLines(self, lines, title, copies)
		local pages = {}
		local pageLines = {}
		for i, line in ipairs(lines) do
			table.insert(pageLines, TextLine:Initialise(StripColours(line)))
			if i % 25 == 0 then
				table.insert(pages, pageLines)
				pageLines = {}
			end
		end
		if #pageLines ~= 0 then
				table.insert(pages, pageLines)
		end
		return self:PrintPages(pages, title, copies)
	end

	function PrintPages(self, pages, title, copies)
		copies = copies or 1
		for c = 1, copies do
			for p, page in ipairs(pages) do
				if self:paperLevel() < #pages * copies then
					return 'Add more paper to the printer'
				end
				if self:inkLevel() < #pages * copies then
					return 'Add more ink to the printer'
				end
				self:newPage()
				for i, line in ipairs(page) do
					self:setCursorPos(1, i)
					self:pageWrite(StripColours(line.Text))
				end
				if title then
					self:setPageTitle(title)
				end
				self:endPage()
			end
		end
	end

	Initialise = function(self, name)
		if Present() then
			local new = {}    -- the new instance
			setmetatable( new, {__index = self} )
			if name and Peripheral.PresentNamed(name) then
				new.Name = name
			else
				new.Name = Peripheral.GetPeripheral(PeripheralType).Side
			end
			return new
		end
	end