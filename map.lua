local struct = require "vstruct"

local map = {}
local mt = { __index = map }

function chunkid(level, type)
	local ids = {
		info = 4;
		tiles = 5;
	}

	return 4000 + 100*level + ids[type]
end

function map.load(rf, index)
	local MAP_INFO = [[
		width:u4 height:u4
		log2w:u4 log2h:u4
		step_power:u4
		map_pointer:u4
		cyberspace:b4
		magic:s30
	]]
	local MAP_TILES = [[
		%d * %d * {
			shape:u1
			ceiling:{} floor:{}
			[1|radiation:b1 ceiling.dir:u2 ceiling.height:u5]
			[1|biohazard:b1 floor.dir:u2 floor.height:u5]
			slope:u1
			xref:u2
			texture:{}
			[2|floor:u5 ceiling:u5 wall:u6]
			flags:u4
			magic:u4
		}
	]]

	-- for now we just load the world geometry
	local self = { index = index }

	self.info = struct.unpack(MAP_INFO, rf:get(chunkid(index, "info")).data)
	self.tiles = struct.unpack(MAP_TILES % {self.info.width, self.info.height}, rf:get(chunkid(index, "tiles")).data)

	return setmetatable(self, mt)
end

-- tiles are packed bottom to top, left to right, row-major in the resource file
function map:tile(x,y)
	local w,h = self.info.width,self.info.height

	--print(w*h, x, y, (h - y - 1)*w + x + 1)

	return self.tiles[(h - y - 1)*w + x + 1]
end

--[[
0000	uint8		tile shape.
			00			solid
			01			open
			02			diagonal, open S+E
			03			diagonal, open S+W
			04			diagonal, open N+W
			05			diagonal, open N+E
			06			slope, S->N (all slopes expressed as low->high)
			07			slope, W->E
			08			slope, N->S
			09			slope, E->W
			0A			slope, valley SE->NW
			0B			slope, valley SW->NE
			0C			slope, valley NW->SE
			0D			slope, valley NE->SW
			0E			slope, ridge NW->SE
			0F			slope, ridge NE->SW
			10			slope, ridge SE->NW
			11			slope, ridge SW->NE
0008	uint32		flags:
			8000 0000	tile has been visited/automapped
			0F0F 0000	?? shade control ??
			0000 F000	?? music nibble ??
			0000 0C00	slope control:
			     x0xx	floor & ceiling, same direction
				 x4xx	floor & ceiling, opposite directions
				 x8xx	floor only
				 xCxx	ceiling only
			0000 0200	?? spooky music flag ??
			0000 0100	use adjacent rather than local wall textures
			0000 001F	vertical texture offset adjustment
]]



return map