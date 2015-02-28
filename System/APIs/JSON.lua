------------------------------------------------------------------ utils
local controls = {["\n"]="\\n", ["\r"]="\\r", ["\t"]="\\t", ["\b"]="\\b", ["\f"]="\\f", ["\""]="\\\"", ["\\"]="\\\\"}
 
local function isArray(t)
        local max = 0
        for k,v in pairs(t) do
                if type(k) ~= "number" then
                        return false
                elseif k > max then
                        max = k
                end
        end
        return max == #t
end
 
local whites = {['\n']=true; ['r']=true; ['\t']=true; [' ']=true; [',']=true; [':']=true}
function removeWhite(str)
        while whites[str:sub(1, 1)] do
                str = str:sub(2)
        end
        return str
end
 
------------------------------------------------------------------ encoding
 
local function encodeCommon(val, pretty, tabLevel, tTracking)
        local str = ""
 
        -- Tabbing util
        local function tab(s)
                str = str .. ("\t"):rep(tabLevel) .. s
        end
 
        local function arrEncoding(val, bracket, closeBracket, iterator, loopFunc)
                str = str .. bracket
                if pretty then
                        str = str .. "\n"
                        tabLevel = tabLevel + 1
                end
                for k,v in iterator(val) do
                        tab("")
                        loopFunc(k,v)
                        str = str .. ","
                        if pretty then str = str .. "\n" end
                end
                if pretty then
                        tabLevel = tabLevel - 1
                end
                if str:sub(-2) == ",\n" then
                        str = str:sub(1, -3) .. "\n"
                elseif str:sub(-1) == "," then
                        str = str:sub(1, -2)
                end
                tab(closeBracket)
        end
 
        -- Table encoding
        if type(val) == "table" then
                assert(not tTracking[val], "Cannot encode a table holding itself recursively")
                tTracking[val] = true
                if isArray(val) then
                        arrEncoding(val, "[", "]", ipairs, function(k,v)
                                str = str .. encodeCommon(v, pretty, tabLevel, tTracking)
                        end)
                else
                        arrEncoding(val, "{", "}", pairs, function(k,v)
                                assert(type(k) == "string", "JSON object keys must be strings", 2)
                                str = str .. encodeCommon(k, pretty, tabLevel, tTracking)
                                str = str .. (pretty and ": " or ":") .. encodeCommon(v, pretty, tabLevel, tTracking)
                        end)
                end
        -- String encoding
        elseif type(val) == "string" then
                str = '"' .. val:gsub("[%c\"\\]", controls) .. '"'
        -- Number encoding
        elseif type(val) == "number" or type(val) == "boolean" then
                str = tostring(val)
        else
                error("JSON only supports arrays, objects, numbers, booleans, and strings", 2)
        end
        return str
end
 
function encode(val)
        return encodeCommon(val, false, 0, {})
end
 
function encodePretty(val)
        return encodeCommon(val, true, 0, {})
end
 
------------------------------------------------------------------ decoding
 
function parseBoolean(str)
        if str:sub(1, 4) == "true" then
                return true, removeWhite(str:sub(5))
        else
                return false, removeWhite(str:sub(6))
        end
end
 
function parseNull(str)
        return nil, removeWhite(str:sub(5))
end
 
local numChars = {['e']=true; ['E']=true; ['+']=true; ['-']=true; ['.']=true}
function parseNumber(str)
        local i = 1
        while numChars[str:sub(i, i)] or tonumber(str:sub(i, i)) do
                i = i + 1
        end
        local val = tonumber(str:sub(1, i - 1))
        str = removeWhite(str:sub(i))
        return val, str
end
 
function parseString(str)
        local i,j = str:find('[^\\]"')
        local s = str:sub(2, j - 1)
 
        for k,v in pairs(controls) do
                s = s:gsub(v, k)
        end
        str = removeWhite(str:sub(j + 1))
        return s, str
end
 
function parseArray(str)
        str = removeWhite(str:sub(2))
       
        local val = {}
        local i = 1
        while str:sub(1, 1) ~= "]" do
                local v = nil
                v, str = parseValue(str)
                val[i] = v
                i = i + 1
                str = removeWhite(str)
        end
        str = removeWhite(str:sub(2))
        return val, str
end
 
function parseObject(str)
        str = removeWhite(str:sub(2))
       
        local val = {}
        while str:sub(1, 1) ~= "}" do
                local k, v = nil, nil
                k, v, str = parseMember(str)
                val[k] = v
                str = removeWhite(str)
        end
        str = removeWhite(str:sub(2))
        return val, str
end
 
function parseMember(str)
        local k = nil
        k, str = parseValue(str)
        local val = nil
        val, str = parseValue(str)
        return k, val, str
end
 
function parseValue(str)
        local fchar = str:sub(1, 1)
        if fchar == "{" then
                return parseObject(str)
        elseif fchar == "[" then
                return parseArray(str)
        elseif tonumber(fchar) ~= nil or numChars[fchar] then
                return parseNumber(str)
        elseif str:sub(1, 4) == "true" or str:sub(1, 5) == "false" then
                return parseBoolean(str)
        elseif fchar == "\"" then
                return parseString(str)
        elseif str:sub(1, 4) == "null" then
                return parseNull(str)
        end
        return nil
end
 
function decode(str)
        str = removeWhite(str)
        t = parseValue(str)
        return t
end
 
function decodeFromFile(path)
        local file = assert(fs.open(path, "r"))
        return decode(file.readAll())
end