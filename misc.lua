-- Assorted global functions that don't belong in their own file.

memoize = (function(f) return f(f) end)(function(f)
	local memos = {}
	local function findmemo(memo, args, first, ...)
		local argv = { ... }
		if #argv == 0 then
			if memo[first] == nil then
				args[#args+1] = first
				memo[first] = { f(unpack(args)) }
			end
			return unpack(memo[first])
		else
			args[#args+1] = first
			memo[first] = memo[first] or {}
			return findmemo(memo[first], args, ...)
		end
	end
	return function(...)
		local argc = #({...})
		memos[argc] = memos[argc] or {}
		return findmemo(memos[argc], {}, ...)
	end
end)

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
