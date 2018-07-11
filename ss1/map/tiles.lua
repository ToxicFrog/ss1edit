local vstruct = require "vstruct"

-- offset from the base chunk ID of the level tile map
local OFFSET = 5

-- format of a level tile struct on disk
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

local function load(self)
  local buf = self.res:read(self.id + OFFSET)
  return vstruct.read(MAP_TILES % {self.info.width, self.info.height}, buf)
end

return {
  load = load;
}
