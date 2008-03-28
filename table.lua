function table.resize(T, size, fill)
	local filler
	if type(fill) ~= "function" then
		filler = function() return fill end
	else
		filler = fill
	end
	
	if #T > size then
		for i=#T,size,-1 do
			T[i] = nil
		end
	elseif #T < size then
		for i=#T+1,size,1 do
			T[i] = filler()
		end
	end
	return T
end

-- tprint - recursively display the contents of a table
-- does not generate something the terp can read; use table.dump() for that
function table.print(T)
	local done = {}
	local function tprint_r(T, prefix)
		for k,v in pairs(T) do
			print(prefix..tostring(k),'=',tostring(v))
			if type(v) == 'table' then
				if not done[v] then
					done[v] = true
					tprint_r(v, prefix.."  ")
				end
			end
		end
	end
	done[T] = true
	tprint_r(T, "")
end

function table.dump(T)
	dump = "local loadstring = loadstring\nsetfenv(1, {})\n\n"
	ref = {}

	local getref

	local function check_kv(k,v)
		for _,val in ipairs { k, v } do
			if type(val) == 'coroutine'
				or type(val) == 'userdata'
			then
				return false
			end
		end
		return true
	end

	local function append_table(T)
		ref[T] = tostring(T):gsub("table: ", "table_")
		
		local S = string.format("%s = {\n", ref[T])
		for k,v in pairs(T) do
			if check_kv(k,v) then
				S = S..string.format("\t[%s] = %s;\n", getref(k), getref(v))
			end
		end
		
		dump = dump..S.."}\n\n"
	end

	function getref(v)
		if ref[v] then return ref[v] end
		
		local t = type(v)
		if t == 'nil'
			or t == 'boolean'
			or t == 'number'
		then
			return tostring(v)
		elseif t == 'string' then
			return string.format("%q", v)
		elseif t == 'function' then
			ref[v] = tostring(v):gsub("function: ", "func_")
			dump = dump..string.format("%s = assert(loadstring(%q, 'table.dump function serializer'))\n\n",
				ref[v], string.dump(v))
			return ref[v]
		elseif t == 'table' then
			append_table(v)
			return ref[v]
		else
			-- error
			error "Something bad has happened in table.dump()"
		end
	end

	append_table(T)
	return dump.."return "..getref(T)
end

function table.copy(from, depth)
	ref = {}
	depth = depth or math.huge
	
	local function tcopy(from, depth)
		local function getref(v)
			if type(v) ~= 'table' then
				return v
			elseif not ref[v] then
				ref[v] = tcopy(v, depth-1)
			end
			return ref[v]
		end
	
		if depth <= 0 then
			return from
		end
		
		local to = {}
		ref[from] = to
		
		for k,v in pairs(from) do
			to[getref(k)] = getref(v)
		end
		
		return to
	end
	
	return tcopy(from, depth)
end

function table.max(t, cmp)
	if #t == 0 then return nil end
	
	if not cmp then cmp = function(lhs, rhs) return lhs > rhs end end
	
	local max = t[1]
	for i,v in ipairs(t) do
		if cmp(v,max) then max = v end
	end
	return max
end

function table.map(f, t)
	local tprime = {}
	for k,v in pairs(t) do
		tprime[k] = f(v)
	end
	return tprime
end
