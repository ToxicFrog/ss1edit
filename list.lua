-- functions related to manipulating tables-as-lists
-- resize, max, foldl/foldr, scanl/scanr, zipn/unzipn, zipwith, reverse, split, partition
-- select, reject

-- resize a list-table to the given size
-- when shrinking it, simply removes excess elements
-- when growing it, fills new entries with the value of 'fill', which
-- can either be a function that returns a value, or a value which
-- will be copied directly
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

-- return the maximum value among the lists's values
-- uses cmp to do the comparison, it is expected to return
-- true if the first argument is > the second
-- if cmp is not provided, defaults to the standard operator >
function table.max(t, cmp)
	if #t == 0 then return nil end
	
	if not cmp then cmp = function(lhs, rhs) return lhs > rhs end end
	
	local max = t[1]
	for i,v in ipairs(t) do
		if cmp(v,max) then max = v end
	end
	return max
end

