local name = (...)

require (name..'.table')
require (name..'.string')
require (name..'.math')
require (name..'.misc')
require (name..'.io')

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

function getopts(args, ...)
	local argv = { ... }
	local yield = coroutine.yield

	local function isFlag(flag)
		return args:match(flag) or false
	end

	local function flagHasArgs(flag)
		local s = args:find(flag)
		local a = args:sub(s+1,s+1)
		if a ~= ':' and a ~= '?' then
			return false
		end
		return a
	end

	local function doShortOpts(arg, next_arg)
		while #arg > 0 do
			flag = arg:sub(1,1)
			arg = arg:sub(2,-1)

			-- not a valid flag? Yield false indicating error
			if not isFlag(flag) then
				yield(false, flag.." is not a valid flag")
			end

			-- no arguments required? Yield flag only, no optarg
			if not flagHasArgs(flag) then
				yield(flag)

			-- flag has arguments. If we have -ffoo, yield f,foo
			elseif #arg > 0 then
				yield(flag, arg)
				return false

			-- otherwise things get interesting. If the flag has a mandatory
			-- argument, next_arg is that argument, and if not present we error
			elseif flagHasArgs(flag) == ':' then
				if next_arg then
					yield(flag, next_arg)
					return true
				end
				yield(false, flag.." requires an argument")

			-- if the flag has an optional argument, the next argument is that
			-- arg if present and not starting with -
			elseif next_arg and not next_arg:match('^-') then
				yield(flag, next_arg)
				return true

			else
				yield(flag)
				return false
			end
		end
		return false
	end

	return coroutine.wrap(function()
		-- we roll our own for loop so that we can adjust i in mid-loop
		local i = 1
		while i <= #argv do
			local arg = argv[i]
			if arg == "--" then
				-- stop argument processing - dump out all remaining arguments and return
				for j=i+1,#argv do
					yield(true, argv[i])
				end
				return
			elseif arg:match("^-") then
				-- short option(s) of the form "-abc"
				-- doShortOpts will handle them, and return true if we need to skip the next
				-- argument because it was consumed as an optarg
				if doShortOpts(arg:sub(2,-1), argv[i+1]) then
					i = i+1
				end
			else
				-- plain argument, no flags
				yield(true,arg)
			end
			i = i+1
		end
	end)
end
