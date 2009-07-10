-- new string-related functions, all of them placed in table string
-- and thus callable with str:foo()
-- split, trim, join, rfind, count, interpolate

-- python-style string formatting with %
getmetatable("").__mod = function(lhs, rhs)
    if type(rhs) == "table" then
        return lhs:format(unpack(rhs))
    else
        return lhs:gsub('%%', '%%%%'):gsub('%%%%', '%%', 1):format(rhs)
    end
end

-- string... split(string, pattern. max) - break up string on pattern
-- default value for pattern is to split on whitespace
-- default value for max is infinity
function string.split(s, pat, max)
	pat = pat or "%s+"
	max = max or nil
	local count = 0
	local i = 1
	local result = { 1 }
	
	local function splitter(sof, eof)
		result[#result] = s:sub(result[#result], sof-1)
		result[#result+1] = eof
	end
	
	if pat == "" then return s end

	s:gsub("()"..pat.."()", splitter, max)

	result[#result] = s:sub(result[#result], #s)

	return unpack(result)
end

-- string trim(string) - remove whitespace from start and end
function string.trim(s)
	return s:gsub('^%s*', ''):gsub('%s*$', '')
end

-- string join(seperator, ...) - concatenate strings
function string.join(joiner, ...)
	return table.concat({...}, joiner)
end

-- rfind - as string.find() only backwards
function string.rfind (s, pattern, rinit, plain)
	-- if rinit is set, we basically trim the last rinit characters from the string
	s = s:sub(rinit, -1)
	
	local old_R = {}
	local R = { s:find(pattern, 1, plain) }

	while true do
		if R[1] == nil then return unpack(old_R) end
		old_R,R = R,{ s:find(pattern, R[2]+1) }
	end
end

-- count - count the number of occurences of a regex
function string.count(s, pattern)
	local count = 0
	for match in s:gmatch(pattern) do
		count = count+1
	end
	return count
end

-- string.interpolate - take a string with $(...) interpolation expressions in it,
-- and a table of stuff to resolve them in terms of
function string.interpolate(str, data, seeall)
	local oldmt
	if seeall then
		oldmt = getmetatable(data)
		setmetatable(data, { __index = getfenv(2) })
	end
	
	local function do_interp(key)
		key = key:sub(2,-2)
		local format = key:match([[|([^|'"%]%[]*)$]])
		if format then
			key = key:gsub([[|[^|'"%]%[]*$]], "")
		end
		local sfn = "return "..key
		sfn = sfn:interpolate(data)
		local fn = setfenv(assert(loadstring(sfn)), data)
		if format then
			return regex:format(fn())
		end
		return tostring(fn())
	end

	local count
	repeat
		str,count = str:gsub('%$(%b())', do_interp)
	until count == 0
	
	if seeall then
		setmetatable(data, oldmt)
	end
	
	return str
end
