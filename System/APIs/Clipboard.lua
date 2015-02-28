Content = nil
Type = nil
IsCut = false

Bedrock = nil

LastChar = 0

function Initialise(self, bedrock)
	local new = {}    -- the new instance
	setmetatable( new, {__index = self} )

	new.Bedrock = bedrock

	new.Bedrock:RegisterEvent('char', function()
		new.LastChar = os.clock()
	end)


	return new
end

function Empty(self)
	self.Content = nil
	self.Type = nil
	self.IsCut = false
end

function isEmpty(self)
	return self.Content == nil
end

function Copy(self, content, _type)
	self.Content = content
	self.Type = _type or 'generic'
	self.IsCut = false
end

function Cut(self, content, _type)
	self.Content = content
	self.Type = _type or 'generic'
	self.IsCut = true
end

function Paste(self, callback)
	-- This is to allow for the user's real OS clipboard to do it's thing first
	self.Bedrock:StartTimer(function()
		-- if self.LastChar + 0.4 > 
		local c, t = self.Content, self.Type
		if self.IsCut then
			self.Empty()
		end
		return c, t
	end, 0.4)
end