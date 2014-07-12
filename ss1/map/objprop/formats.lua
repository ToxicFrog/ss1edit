local formats = { details = {} }

-- Common object properties.
formats.Object = [[
  used:b1
  class:u1
  subclass:u1
  detail_index:u2
  xref_index:u2
  prev:u2
  next:u2
  x:p2,8
  y:p2,8
  z:u1
  pitch:u1
  yaw:u1
  roll:u1
  ai_maybe:u1
  type:u1
  hp_maybe:u2
  state:u1
  unknown:s3
]]

-- Weapons.
formats[0] = [[
  x6
  ammo_type:u1
  ammo_count:u1
]]

-- Ammo has no interesting properties.
formats[1] = [[
  x6
]]

-- Projectiles have not been reverse engineered and exist only in save games.
-- I suspect it will contain at least vector information, but it may also
-- contain damage information for variable-power projectiles like plasma bolts.

-- Grenades and explosives have not been reverse engineered yet.

-- Dermal patches have no interesting properties.
formats[4] = [[
  x6
]]

-- Hardware.
formats[5] = [[
  x6
  version:u1
]]


-- Software, logs and notes.
formats[6] = [[
  x6
  version:u1
  log_id:u1
  log_level:u1
]]

-- Scenery and decorations. Too complicated right now.
formats[7] = [[
  x16
]]

-- Inventory items. Not yet reverse engineered.

-- Switches and panels.
formats[9] = [[
  x6
  unknown_9:s2
  condition_variable:u2
  condition_message:u2
  union:s18
]]

-- Doors and gratings.
formats[10] = [[
  x6
  trigger:u2
  message:u2
  access:u1
  unknown_10:s3
]]

-- Animations not yet reverse engineered.

-- Traps and triggers.
-- Too complicated to handle yet.
formats[12] = [[
  x28
]]

-- Containers.
formats[13] = [[
  x6
  contents:{ 4*u2 }
  width:u1
  height:u1
  depth:u1
  texture:{
    top:u1
    side:u1
  }
  unknown_13:s2
]]

-- Critters not yet reverse engineered.

return formats
