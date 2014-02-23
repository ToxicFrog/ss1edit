local vstruct = require "vstruct"

-- offset from the base chunk ID of the level object table
local OFFSET = 8

-- format of a common object instance properties struct
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

local function load(self)
  -- to fully realize an object, we need to read its information from five places
  -- first, we need to read the universal, category-specific, and subcategory-
  -- specific information from the gamesys
  -- then we need to read the common instance variables from the master object
  -- table in the map itself
  -- finally, the type-specific instance variables from the type specific info
  -- table in the map, indexed by info_index
  -- I'm not sure what a non-terrible API for this looks like.

  local buf = self.res:get(self.id + OFFSET).data
  assert(#buf % 27 == 0, "confusing object table length")
  return vstruct.unpack(MAP_OBJECTS % (#buf/27), buf)
end

return {
  load = load;
}
