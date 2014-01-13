	Content = nil
	Type = nil
	IsCut = false

	function Empty()
		Clipboard.Content = nil
		Clipboard.Type = nil
		Clipboard.IsCut = false
	end

	function isEmpty()
		return Clipboard.Content == nil
	end

	function Copy(content, _type)
		Clipboard.Content = content
		Clipboard.Type = _type or 'generic'
		Clipboard.IsCut = false
	end

	function Cut(content, _type)
		Clipboard.Content = content
		Clipboard.Type = _type or 'generic'
		Clipboard.IsCut = true
	end

	function Paste()
		local c, t = Clipboard.Content, Clipboard.Type
		if Clipboard.IsCut then
			Clipboard.Empty()
		end
		return c, t
	end