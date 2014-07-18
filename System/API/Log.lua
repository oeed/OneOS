Initialise = function()
	local h = fs.open('/System/OneOS.log', 'w')
	h.write('-- OneOS Log --\n')
	h.close()
end

log = function(msg, state)
	state = state or ''
	if state ~= '' then
		state = ' '..state
	end
	local h = fs.open('/System/OneOS.log', 'a')
	h.write('['..os.clock()..state..'] '..tostring(msg)..'\n')
	h.close()	
end

e = function(msg)
	log(msg, 'Error')
end

i = function(msg)
	log(msg, 'Info')
end

w = function(msg)
	log(msg, 'Warning')
end