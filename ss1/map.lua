local vstruct = require "vstruct"

local map = {}
local mt = { __index = map }

local names = require "ss1.names".levels
local objprop = require "ss1.map.objprop"
local tiles = require "ss1.map.tiles"

function map.load(rf, level)
  local function loadinfo(self)
    local MAP_INFO = [[
      width:u4 height:u4
      log2w:u4 log2h:u4
      step_power:u4
      map_pointer:u4
      cyberspace:b4
      magic:s30
    ]]

    return vstruct.read(MAP_INFO, rf:get(self.id + 4).data)
  end

  local self = {
    level = level;
    id = 4000 + 100*level; -- base chunk ID of this level
    res = rf;
  }

  self.name = names[index] or "UNKNOWN LEVEL"
  self.info = loadinfo(self)
  self.objects = objprop.load(self)
  self._tiles = tiles.load(self)

  return setmetatable(self, mt)
end

-- Tiles are packed bottom to top, left to right, row-major in the resource
-- file. The API expects tile indexes using System Shock coordinates, i.e.
-- 0-indexed; a typical map contains tiles tiles in the range (0,0)-(63,63).
function map:tile(x,y)
  local w,h = self.info.width,self.info.height
  return self._tiles[y*w + x + 1]
end

-- Return an iterator over all tiles within the given bounding box.
-- If no bounds specified, iterates over all tiles row by row.
function map:tiles(x1, y1, x2, y2)
  x1 = x1 or 0
  y1 = y1 or 0
  x2 = x2 or self.info.width-1
  y2 = y2 or self.info.height-1
  local function iter()
    for y=y1,y2 do
      for x=x1,x2 do
        coroutine.yield(x, y, self:tile(x,y))
      end
    end
  end
  return coroutine.wrap(iter)
end

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
