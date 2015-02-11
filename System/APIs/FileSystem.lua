local realFs = fs

function Initialise()
	fs = {}
	for k, v in pairs(realFs) do
		fs[k] = v
	end
end