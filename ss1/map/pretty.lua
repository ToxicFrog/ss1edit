-- Library for human-readable display of map objects

local gamesys = require "ss1.gamesys"

local pretty = {}
local details = {}

local function add(t, key, value)
  table.insert(t, { key=key, value=value })
  return t
end

function pretty.map(map)
  local info = {}
  add(info, "level", map.level)
  add(info, "name", map.name)
  add(info, "base chunk id", map.id)
  add(info, "dimensions", map.info.width.."x"..map.info.height)
  add(info, "vertical resolution", 2^map.info.step_power.." steps/cube")
  add(info, "type", map.info.cyberspace and "cyberspace" or "station")
  return info
end

function pretty.object(obj)
  local info = {}
  add(info, "id", "%d/%d/%d" % {obj.class, obj.subclass, obj.type})
  add(info, "class", gamesys.name(obj.class))
  add(info, "subclass", gamesys.name(obj.class, obj.subclass))
  add(info, "type", gamesys.name(obj.class, obj.subclass, obj.type))
  add(info, "position", "(%.2f, %.2f, %.2f)" % { obj.x, obj.y, obj.z })
  add(info, "orientation", "(%d, %d, %d)" % { obj.pitch, obj.yaw, obj.roll })
  add(info, "HP", tostring(obj.hp_maybe))
  -- add details
  if details[obj.class] then
    details[obj.class](info, obj)
  end
  return info
end

local tile_shape = {
  [0] = "solid",
  "open",
  "open-se", "open-sw", "open-nw", "open-ne",
  "slope-n", "slope-e", "slope-s", "slope-w",
  "valley-nw", "valley-ne", "valley-se", "valley-sw",
  "ridge-se", "ridge-sw", "ridge-nw", "ridge-ne",
}

function pretty.tile(tile)
  local info = {}
  --add(info, "position", "(%d,%d)" % { tile.x, tile.y })
  add(info, "shape", tile_shape[tile.shape])
  add(info, "height", tile.floor.height .. "-" .. (32-tile.ceiling.height))
  add(info, "slope", tile.slope)
  add(info, "hazards",
    (tile.biohazard
      and (tile.radiation and "biohazard & radiation" or "biohazard")
      or (tile.radiation and "radiation" or "none")))
  return info
end

details[13] = function(info, obj)
  if #obj.contents > 0 then
    add(info, "contents", table.concat(
      table.mapv(obj.contents,
        function(obj) return gamesys.name(obj.class, obj.subclass, obj.type) end),
      "<br>"))
  else
    add(info, "contents", "(empty)")
  end
  return info
end

return pretty
