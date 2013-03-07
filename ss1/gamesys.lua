local names = require "ss1.names"

local gamesys = {}

local sizes = {
	n=16;
	{ n=6, 5,2,2,2,3,2; }; -- weapons			16	16
	{ n=7, 2,2,3,2,2,2,2; };	-- ammo 		15	31
	{ n=3, 6,16,2; }; -- projectiles			24	55
	{ n=2, 5,3; }; -- explosives				 8	63
	{ n=1, 7; }; -- patches 					 7	70
	{ n=2, 5,10; }; -- hardware					15	85
	{ n=6, 7,3,4,5,2,1; }; -- software 			22	107
	{ n=8, 9,10,11,4,9,8,16,10; }; -- fixtures	77	184
	{ n=8, 8,10,15,6,12,12,9,8; }; -- items		80	264
	{ n=6, 9,7,3,11,2,3; }; -- switches 		35	299
	{ n=5, 9,10,7,5,10 }; -- doors
	{ n=1, 34 }; -- animations
	{ n=3, 13,1,5 };
	{ n=7, 3,3,4,8,13,7,8 }; -- containers
	{ n=5, 9,12,7,7,2 }; -- critters
	{ n=1, 1; }; -- LAST_CLASS
}


-- given a (c,sc,k) triple, return the index of that object kind
-- e.g. 0/2/1 (WEAPONS, KINETIC PROJECTILE, RAILGUN) has index 8
function gamesys.id2index(cat, subcat, kind)
	local index = 0

	for c=1,cat do
		for sc=1,sizes[c].n do
			index = index + sizes[c][sc]
		end
	end

	for sc=1,subcat do
		index = index + sizes[cat+1][sc]
	end

	index = index + kind

	return index
end

-- the inverse of id2index; given an index, return the (c,sc,k)
-- triple for that object kind
function gamesys.index2id(index)
end

-- given an index or id, return the name of the object
function gamesys.name(index, subcat, kind)
	if subcat and kind then
		return gamesys.name(gamesys.id2index(index, subcat, kind))
	end

	return names[index]
end

return gamesys