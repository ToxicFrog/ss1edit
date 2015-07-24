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

-- New versions of pairs, ipairs, and type that respect the corresponding
-- metamethods.
do
	local function metamethod_wrap(f, name)
		return function(v)
			local mm = rawget(getmetatable(v) or {}, name)
			if mm then
				return mm(v)
			end
			return f(v)
		end
	end
	rawtype = type
	type = metamethod_wrap(type, "__type")
	if _VERSION:match("Lua 5.1") then
		pairs = metamethod_wrap(pairs, "__pairs")
		ipairs = metamethod_wrap(ipairs, "__ipairs")
	end
end

-- update file metatable with __type
getmetatable(io.stdout).__type = function() return "file" end

-- Allow string formatting in assert and error
do
	local _assert,_error = assert,error
	function assert(exp, err, ...)
		return _assert(exp, err and err:format(...))
	end
	function error(err, ...)
		return _error(err and err:format(...))
	end
end
