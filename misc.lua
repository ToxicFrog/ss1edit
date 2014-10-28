-- new global functions, either replacing existing ones or providing new
-- ones for convenience
-- replacements: pairs, ipairs, type
-- new: printf, fprintf, eprintf, sprintf, srequire, L

-- new version of type() that supports the __type metamethod
rawtype = type
function type(obj)
	local mt = getmetatable(obj)
	if mt and rawget(mt, "__type") then
		return rawget(mt, "__type")(obj)
	end
	return rawtype(obj)
end
-- update file metatable
getmetatable(io.stdout).__type = function() return "file" end

-- printf(format, ...)
function printf(...)
	return io.stdout:printf(...)
end

-- printf to standard error
function eprintf(...)
	return io.stderr:printf(...)
end

-- bind to io tables, so that file:printf(...) becomes legal
getmetatable(io.stdout).__index.printf = function(self, ...)
  return self:write(string.format(...))
end

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
function f(src)
	return assert(loadstring(
		"return function(" .. src:gsub(" => ", ") return ") .. " end"
	))()
end

-- bind args into function
function partial(f, ...)
	if select('#', ...) == 0 then
		return f
	end
	local arg = (...)
	return partial(function(...) return f(arg, ...) end, select(2, ...))
end

if lfs then
	function lfs.exists(path)
		return lfs.attributes(path, "mode") ~= nil
	end
end
