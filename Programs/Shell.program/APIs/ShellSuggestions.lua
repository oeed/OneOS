
-- Using the same tokenise function as Shell to prevent issues
local function tokenise( ... )
    local sLine = table.concat( { ... }, " " )
	local tWords = {}
    local bQuoted = false
    for match in string.gmatch( sLine .. "\"", "(.-)\"" ) do
        if bQuoted then
            table.insert( tWords, match )
        else
            for m in string.gmatch( match, "[^ \t]+" ) do
                table.insert( tWords, m )
            end
        end
        bQuoted = not bQuoted
    end
    return tWords
end

local matchToken = function(text, tokenType)
	local possible = {}

    local function insertTable(tbl)
    	if tbl and type(tbl) == 'table' then
	    	for i, v in ipairs(tbl) do
	    		local add = true
	    		for i2, v2 in ipairs(possible) do
					if v2 == v then
						add = false
						break
					end
				end
				if add then
					table.insert(possible, v)
				end
	    	end
	    elseif tbl then
	    	table.insert(possible, tbl)
	    end
    end
	
	if tokenType == 'program' then
	    insertTable(shell.resolveProgram(text))
	    for k, v in pairs(shell.aliases()) do
	    	insertTable(k)
	    end
	    insertTable(shell.programs())
	end

    for i, item in ipairs(possible) do
    	if string.lower(string.sub(item, 1, string.len(text))) == string.lower(text) then
    		return item
    	end
    end

	return ''
end

SuggestedText = function(text)
	local tokens = tokenise(text)
	if #tokens == 0 then
		return text
	else
		local lastToken = tokens[#tokens]
		return matchToken(text, 'program')
	end
end