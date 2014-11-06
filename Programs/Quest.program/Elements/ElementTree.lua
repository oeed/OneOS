Tree = nil
FailHandler = nil

Initialise = function(self, html)
	local new = {}    -- the new instance
	setmetatable( new, {__index = self} )
	local err = nil
	if html:sub(1,15):lower() ~= '<!doctype ccml>' then
		err = Errors.InvalidDoctype
	end

	html = html:gsub("<!%-%-*.-%-%->","")

	local rawTree
	if not err then
		rawTree = parser.parsestr(html)[1]
	end

	if not err then
		_, notok = pcall(function() new:LoadTree(rawTree) end)
		if notok then
			error(notok)
			err = Errors.ParseFailed
		end
	end

	if err then
		return nil, err
	end
	return new
end

LoadTree = function(self, rawTree)
	local tree = {}
	local node = true
	node = function (tbl, tr, parent)
		for i, v in ipairs(tbl) do
			if type(v) == 'table' and v._tag then
				local class = self:GetElementClass(v._tag, v._attr)
				if not class or not class.Initialise then
					error('Unknown class: '..v._attr.type)
				end
				local element = class:Initialise(v)
				element.Parent = parent
				table.insert(tr, element)
				if element.Children then
					node(v, element.Children, element)
				end
			end
		end
	end

	node(rawTree, tree)
	self.Tree = tree
end

GetElement = function(self, tag)
	local node = true
	node = function(tbl)
		for i,v in ipairs(tbl) do
			if type(v) == 'table' and v.Tag then
				if v.Tag == tag then
					return v
				end
				if v.Children then
					local r = node(v.Children)
					if r then
						return r
					end
				end
			end
		end
	end
	return node(self.Tree)
end

GetElementClass = function(self, tag, attr)
	if tag == 'h' then
		return Heading
	elseif tag == 'div' then
		return Divider
	elseif tag == 'p' then
		return Paragraph
	elseif tag == 'center' then
		return Center
	elseif tag == 'img' then
		return Image
	elseif tag == 'a' then
		return Link
	elseif tag == 'float' then
		return Float
	elseif tag == 'br' then
		return Element
	elseif tag == 'input' then
		if attr.type == 'text' then
			return TextInput
		elseif attr.type == 'password' then
			return SecureTextInput
		elseif attr.type == 'submit' or attr.type == 'button' then
			return ButtonInput
		elseif attr.type == 'file' then
			return FileInput
		elseif attr.type == 'hidden' then
			return HiddenInput
		else
			return Element
		end
	elseif tag == 'select' then
		return Select
	elseif tag == 'option' then
		return SelectOption
	elseif tag == 'form' then
		return Form
	elseif tag == 'script' then
		return Script
	else
		return Element
	end
end