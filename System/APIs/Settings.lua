Defaults = {
	AutomaticUpdates = true,
	UsePreReleases = true, -- TODO: set this false when the beta ends
	StartupProgram = false,
	UseAnimations = true,
	DesktopColour = colours.cyan
}

Values = nil
OnUpdateHandlers = nil

function Initialise(self)
	local _new = {}    -- the new instance
	setmetatable( _new, {__index = self} )

	_new.Values = {}
	_new.OnUpdateHandlers = {}
	
	local new = {} -- the proxy
	setmetatable(new, {
		__index = function(t, k)

			Log.i('Index '..k)
			if k == 'OnUpdate' then
				return _new.OnUpdate
			elseif k == 'OnUpdateHandlers' then
				return _new.OnUpdateHandlers
			elseif _new.Values[k] == nil then
				return _new.Defaults[k]
			else
				return _new.Values[k]
			end
		end,

		__newindex = function (t,k,v)
			_new.Values[k] = v

			for i, handler in ipairs(_new.OnUpdateHandlers) do
				if handler then
					handler(k)
				end
			end
			
			local h = fs.open('/System/.OneOS.settings', 'w')
			if h then
				h.write(textutils.serialize(_new.Values))
				h.close()
			end
		end
	})

	local h = fs.open('/System/.OneOS.settings', 'r')
	if h then
		local values = textutils.unserialize(h.readAll())

		for k, v in pairs(values) do
			_new.Values[k] = v
		end
		h.close()
	end

	return new
end

function OnUpdate(self, handler)
	table.insert(self.OnUpdateHandlers, handler)
end