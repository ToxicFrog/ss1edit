-- first, we need a new type() that respects the __type metamethod
do
	local _type = type
	function type(v)
		local mt = getmetatable(v)
		if mt and mt.__type then
			return mt.__type(v)
		end
		return _type(v)
	end
end

-- internal bookkeeping
local proxies = {}

-- add infrastructure for type checking to a table
-- returns a proxy we can use to make typechecked assignments
local function typechecked_t(t)
	if proxies[t] then
		return proxies[t]
	end
	
	local types = {}	-- mapping of names to types
	local proxy = {}	-- __index, __newindex
	local mt = {}		-- metatable

	-- associate the given type with the given name
	-- return the typeset function so we can string declarations
	-- like var "string" "a" "b" "c" "d"
	types.var = "reserved by type checking system"
	function t.var(type)
		local function set_type(name)
			if types[name] then
				error("Attempt to redeclare variable: "..name)
			end
			types[name] = type
			return set_type
		end
		return set_type
	end

	-- check to make sure we're allowed to make assignments with this type
	function mt:__newindex(key, value)
		print("SET", self, key, value)
		if (not types[key])
		or types[key] == type(value) then
			t[key] = value
			return
		end
		print(type(value), types[key], types[key] == type(value), not false or true)
		error("Attempt to assign '"..type(value).."' to "..key..", which has type '"..types[key].."'")
	end
	
	-- accessor for real table
	mt.__index = t

	setmetatable(proxy, mt)
	proxies[t] = proxy
	return proxy
end

-- make the given function's environment type checked, if it wasn't already
-- given the environment a proxy as an environment
local function typechecked_f(f)
	local env = typechecked_t(getfenv(f))
	setfenv(f, env)
	return f
end

-- call the right underlying function based on argument type
function typechecked(v)
	if type(v) == "table" then
		return typechecked_t(v)
	elseif type(v) == "function" then
		return typechecked_f(v)
	elseif v == nil then
		-- make the caller type checked
		local env = typechecked(getfenv(2))
		return setfenv(2, env)
	else
		error("Invalid type to typechecked(): needs function or table")
	end
end
