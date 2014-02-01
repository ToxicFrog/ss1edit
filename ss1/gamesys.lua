
local gamesys = {}

local names = require "ss1.names".objects
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
local catnames = {
	{ name = "WEAPONS"; "SEMI-AUTOMATIC", "AUTOMATIC", "PROJECTILE", "MELEE", "BEAM", "ENERGY" };
	{ name = "AMMO"; "PISTOL", "DARTGUN", "MAGNUM & RIOTGUN", "ASSAULT RIFLE", "FLECHETTE RIFLE", "SKORPION", "MAGPULSE & RAILGUN" };
	{ name = "PROJECTILES"; "TRACERS", "PROJECTILES", "SEEKERS?" };
	{ name = "EXPLOSIVES"; "GRENADES", "EXPLOSIVES" };
	{ name = "PATCHES"; "PATCHES" };
	{ name = "HARDWARE"; "VISION MODES", "IMPLANTS" };
	{ name = "SOFTWARE"; "WEAPONS", "DEFENCES", "UTILITIES", "NON-C/SPACE", "INFORMATION", "??? FIXME ???" };
	{ name = "FIXTURES"; "ELECTRONICS", "FURNITURE", "TEXT & SCREENS", "LIGHTS", "??? FIXME 1 ???", "??? FIXME 2 ???", "PLANTS", "TERRAIN" };
	{ name = "ITEMS"; "JUNK", "DEBRIS", "CORPSES & BODY PARTS", "INVENTORY ITEMS", "ACCESS CARDS", "C/SPACE OBJECTS", "STAINS & DECALS", "PLOT ITEMS" };
	{ name = "SWITCHES"; "SWITCHES", "RECEPTACLES", "TERMINALS", "PANELS", "VENDING MACHINES", "CYBERTOGGLES" };
	{ name = "DOORS"; "HEAVY DOORS", "DOORWAYS", "ENERGY DOORS", "ELEVATOR DOORS", "OTHER DOORS" };
	{ name = "ANIMATIONS"; "??? FIXME ???" };
	{ name = "TRIGGERS"; "TRIGGERS", "TRIPBEAMS", "MARKS" };
	{ name = "CONTAINERS"; "CRATES", "HAZARDS", "LAB EQUIPMENT", "CORPSES", "DESTROYED BOTS", "DESTROYED CYBORGS", "DESTROYED PROGRAMS" };
	{ name = "CRITTERS"; "MUTANTS", "ROBOTS", "CYBORGS", "PROGRAMS", "BOSSES" };
	{ name = "LAST_CATEGORY"; "LAST_SUBCATEGORY" };
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

-- given an id, return the name of the cat/subclass/kind
function gamesys.name(cat, subcat, kind)
	if kind then
		return names[gamesys.id2index(cat, subcat, kind)]
	elseif subcat then
		return catnames[cat+1][subcat+1]
	else
		return catnames[cat+1].name
	end
end

return gamesys
