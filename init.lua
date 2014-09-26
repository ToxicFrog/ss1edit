local name = (...)

require (name..'.flags')
require (name..'.io')
require (name..'.math')
require (name..'.misc')
require (name..'.string')
require (name..'.table')

local unpack = unpack
local coroutine = coroutine

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
