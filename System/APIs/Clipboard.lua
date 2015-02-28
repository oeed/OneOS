Content = nil
Type = nil
IsCut = false

Bedrock = nil

LastPaste = 0

function Initialise(self, bedrock)
	local new = {}    -- the new instance
	setmetatable( new, {__index = self} )

	new.Bedrock = bedrock

	new.Bedrock:RegisterEvent('paste', function(bedrock, event, text)

		Log.i('paste event!')

		Log.i(text)
		new.LastPaste = os.clock()
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
		if self.LastPaste + 0.15 < os.clock() then
			local c, t, is = self.Content, self.Type, self.IsCut
			if self.IsCut then
				self.Empty()
			end
			callback(c, t, is)
		end
	end, 0.2)
end

function PasteToActiveObject(self, bedrock)
	bedrock = bedrock or self.Bedrock
	local obj = bedrock:GetActiveObject()
	if obj then
		self:Paste(function(content, _type)
			if type(content) == 'string' then
				if obj.OnPaste then
					obj:OnPaste('oneos_paste', content)
				end
			end
		end)
	end
end