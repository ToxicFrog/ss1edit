function math.oct(n)
	return tonumber(n, 8)
end

function math.bin(n)
	return tonumber(n, 2)
end

-- degree-based trig:
-- dcos dsin dtan dacos dasin datan
for k,v in ipairs({ "cos", "sin", "tan", "tan2" }) do
	math["d"..v] = function(r) return math[v](math.rad(r)) end
	math["da"..v] = function(r) return math.deg(math["a"..v](r)) end
end
math.dtan2 = nil
