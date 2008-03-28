-- new versions of pairs and ipairs that respect the metamethods for same
local _pairs,_ipairs = pairs,ipairs

function pairs(obj)
	local mt = getmetatable(obj)
	if mt and mt.__pairs then
		return mt.__pairs(obj)
	end
	return _pairs(obj)
end

function ipairs(obj)
	local mt = getmetatable(obj)
	if mt and mt.__ipairs then
		return mt.__ipairs(obj)
	end
	return _ipairs(obj)
end

-- new version of type() that supports the __type metamethod
local _type = type
function type(obj)
	local mt = getmetatable(obj)
	if mt and mt.__type then
		return mt.__type(obj)
	end
	return _type(obj)
end

-- printf(format, ...)
function printf(...)
	return fprintf(io.stdout,...)
end

-- printf to standard error
function eprintf(...)
	return fprintf(io.stderr, ...)
end

-- fprintf(file, format, ...)
function fprintf(fout, ...)
	return fout:write(string.format(...))
end

-- string sprintf(format, ...)
function sprintf(...)
	return string.format(...)
end

-- bind to io tables, so that file:printf(...) becomes legal
getmetatable(io.stdout).__index.printf = fprintf

-- "safe require", returns nil,error if require fails rather than
-- throwing an error
function srequire(...)
	local s,r = pcall(require, ...)
	if s then
		return r
	end
	return nil,r
end

-- fast one-liner lambda creation
function L(args)
	return function(exp)
		return assert(loadstring(
			"return function("..args..") return "..exp.." end"))()
	end
end

