local struct = require "vstruct"

local map = {}
local mt = { __index = map }

local names = require "ss1.names".levels

function chunkid(level, type)
  local ids = {
    info = 4;
    tiles = 5;
    objects = 8;
  }

  return 4000 + 100*level + ids[type]
end


function map.load(rf, index)
  local function loadinfo(self)
    local MAP_INFO = [[
      width:u4 height:u4
      log2w:u4 log2h:u4
      step_power:u4
      map_pointer:u4
      cyberspace:b4
      magic:s30
    ]]

    self.info = struct.unpack(MAP_INFO, rf:get(chunkid(index, "info")).data)
  end

  local function loadtiles(self)
    local MAP_TILES = [[
      %d * %d * {
        shape:u1
        ceiling:{} floor:{}
        [1|biohazard:b1 floor.dir:u2 floor.height:u5]
        [1|radiation:b1 ceiling.dir:u2 ceiling.height:u5]
        slope:u1
        xref:u2
        texture:{
          [2|floor:u5 ceiling:u5 wall:u6]
        }
        flags:{
          [4|
            mapped:b1 x3
            shade: u12
            music: u4
            slope: u2
            spooky:b1
            textures:b1
            vtex:u8
          ]
        }
        magic:u4
      }
    ]]

    self.tiles = struct.unpack(MAP_TILES % {self.info.width, self.info.height}, rf:get(chunkid(index, "tiles")).data)
  end

  local function loadobjects(self)
    local MAP_OBJECTS = [[
      %d * {
        used:b1
        class:u1
        subclass:u1
        info_index:u2
        xref_index:u2
        prev:u2
        next:u2
        x:u2
        y:u2
        z:u1
        pitch:u1
        yaw:u1
        roll:u1
        ai_maybe:u1
        type:u1
        hp_maybe:u2
        state:u1
        unknown:s3
      }
    ]]

    local objbuf = rf:get(chunkid(index, "objects")).data
    assert(#objbuf % 27 == 0, "confusing object table length")
    self.objects = struct.unpack(MAP_OBJECTS % (#objbuf/27), objbuf)
  end

  local self = { index = index, res = rf }
  self.name = names[index] or "UNKNOWN LEVEL"

  loadinfo(self)
  loadtiles(self)
  loadobjects(self)

  return setmetatable(self, mt)
end

-- tiles are packed bottom to top, left to right, row-major in the resource file
function map:tile(x,y)
  local w,h = self.info.width,self.info.height

  --print(w*h, x, y, (h - y - 1)*w + x + 1)

  return self.tiles[y*w + x + 1]
end

--[[
0000  uint8    tile shape.
      00      solid
      01      open
      02-05    diagonal, open SE, SW, NW, NE
      06-09    slope, S->N, W->E, N->S, E->W (all slopes are low->high)
      0A-0D    valley slope, SE->NW, SW->NE, NW->SE, NE->SW
      0E-11    ridge slope, NW->SE, NE->SW, SE->NW, SW->NE
0008  uint32    flags:
      8000 0000  tile has been visited/automapped
      0F0F 0000  ?? shade control ??
      0000 F000  ?? music nibble ??
      0000 0C00  slope control:
        x0xx  floor & ceiling, same direction
        x4xx  floor & ceiling, opposite directions
        x8xx  floor only
        xCxx  ceiling only
      0000 0200  ?? spooky music flag ??
      0000 0100  use adjacent rather than local wall textures
      0000 001F  vertical texture offset adjustment
]]

-- table of cell shapes indicating which directions they are solid in
-- "solid" means the cell is solid in that direction; "slope" means that it
-- slopes upwards in that direction (and thus the height of that edge doesn't
-- match the configured height of the tile). No value means the tile is open
-- and non-sloping in that direction.
local walls = {
  [0] = { n = "solid", s = "solid", e = "solid", w = "solid" },  -- solid space
  {},              -- open space
  { w = "solid", n = "solid" },    -- diagonal open SE
  { e = "solid", n = "solid" },    -- SW
  { e = "solid", s = "solid" },    -- NW
  { w = "solid", s = "solid" },    -- NE
  { n = "slope" },          -- flat slopes
  { e = "slope" },
  { s = "slope" },
  { w = "slope" },
  { n = "slope", w = "slope" },    -- valleys
  { n = "slope", e = "slope" },
  { s = "slope", e = "slope" },
  { s = "slope", w = "slope" },
  {}, {}, {}, {},        -- ridges
}

function map:walls(x, y)
  local w = {}
  for k,v in pairs(walls[self:tile(x,y).shape]) do
    w[k] = v
  end
  return w
end

local function flip(dir)
  local t = { n = "s", s = "n", e = "w", w = "e" }
  return t[dir]
end

-- return the effective floor height in each direction
-- if solid, return math.huge
-- this is not always the same as the recorded floor height because of slopes
function map:floorHeight(x, y)
  local walls = self:walls(x, y)
  local tile = self:tile(x, y)

  for _,dir in pairs { "n", "s", "e", "w" } do
    local height = tile.floor.height

    if walls[dir] == "solid" then
      height = math.huge
    elseif walls[dir] == "slope" and tile.flags.slope ~= 3 then
      height = tile.floor.height + tile.slope
    end

    walls[dir] = height
  end

  return walls
end

-- return the effective ceiling height in each direction, in units UP FROM BOTTOM
-- if solid, return math.huge
-- this is not always the same as the recorded ceiling height because of slopes
function map:ceilingHeight(x, y)
  local walls = self:walls(x, y)
  local tile = self:tile(x, y)
  local heights = {}

  for _,dir in pairs { "n", "s", "e", "w" } do
    local height = 32 - tile.ceiling.height
    local actual_dir = dir

    if tile.flags.slope ~= 1 and (walls[dir] == "slope" or walls[flip(dir)] == "slope") then
      actual_dir = flip(dir)
    end

    if walls[dir] == "solid" then
      height = math.huge
    elseif tile.flags.slope ~= 2 and walls[dir] == "slope" then
      height = 32 - tile.ceiling.height - tile.slope
    end

    heights[actual_dir] = height
  end

  return heights
end

-- reports the change in height between two cells
-- 0 means there is no height change, >0 means there is a height
-- change of that many map height units; infinity means that there
-- is no connection between cells (i.e. a wall).
-- does not support slopes yet, so it may report incorrect values
-- when one of the cells is sloped
function map:ledgeHeight(x1, y1, x2, y2)
  assert(x1 == x2 or y1 == y2, "tiles must be adjacent")

  -- t1 should be to the left/above t2
  if x1 > x2 or y1 > y2 then
    x1,y1,x2,y2 = x2,y2,x1,y1
  end

  local t1,t2 = self:tile(x1,y1),self:tile(x2,y2)
  local w1,w2 = self:walls(x1,y1),self:walls(x2,y2)
  local delta

  if x1 < x2 then -- t1 is west of t2
    w1,w2 = w1.e,w2.w
    delta = math.min(self:ceilingHeight(x1, y1).e - self:floorHeight(x2, y2).w,
                     self:ceilingHeight(x2, y2).w - self:floorHeight(x1, y1).e,
                     self:ceilingHeight(x1, y1).e - self:floorHeight(x1, y1).e,
                     self:ceilingHeight(x2, y2).w - self:floorHeight(x2, y2).w)
  else -- t1 is south of t2
    w1,w2 = w1.n,w2.s
    delta = math.min(self:ceilingHeight(x1, y1).n - self:floorHeight(x2, y2).s,
                     self:ceilingHeight(x2, y2).s - self:floorHeight(x1, y1).n,
                     self:ceilingHeight(x1, y1).n - self:floorHeight(x1, y1).n,
                     self:ceilingHeight(x2, y2).s - self:floorHeight(x2, y2).s)
  end

  if w1 == "solid" and w2 == "solid" then
    return 0 -- both tiles have solid faces
  elseif w1 == "solid" or w2 == "solid" then
    return math.huge -- one tile has a solid face, the other doesn't
  end

  if delta <= 0 then
    return math.huge
  end

  -- now we need to check relative heights
  -- first we check for inferred walls, where the ceiling of one tile is <= the
  -- floor of the other
  -- ceiling is in units down from the top of the map, so we take the *highest*
  -- ceiling value and then subtract it from 32 (the maximum height value)
  if 32 - math.max(t1.ceiling.height, t2.ceiling.height) <= math.max(t1.floor.height, t2.floor.height) then
    return math.huge
  end

  -- if there is no inferred wall, just return the difference between the two floor
  -- heights for now (i.e. without taking slope into account). The length of a height
  -- unit varies from map to map, so we convert it to world units first; the resulting
  -- value will be somewhere between 1/32 (one height unit with the smallest possible
  -- value) and 31 (31 height units with the greatest possible value).
  -- FIXME: we need to understand and handle slopes, which will mean the height of the
  -- tile will be different depending on which edge you're measuring. Ick.
  return math.abs(t1.floor.height - t2.floor.height) * (1/2^self.info.step_power)
end


return map
