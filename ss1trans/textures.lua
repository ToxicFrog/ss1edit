local ids = require 'ss1trans.ids'

local TEX_HEADER = [[
-- textures.txt: strings for wall, floor, and ceiling textures.
-- `name` is what appears when you click on a texture.
-- `use` is what appears when you double-click (i.e. attempt to use) it.
-- `texids` is a list of texture IDs (0-511); most textures have a few variants
-- with the same name and usage message, and thus, multiple texids.

]]
local TEX_TEMPLATE = [[
-- %s
texture {
  texids = { %s };
  name = %q;
  use = %q;
}

]]

-- Given a resfile, unpacks the texture name and usage messages and returns
-- a string containing them.
return function(rf)
  local names = rf:read(ids.TEX_NAMES)
  local msgs = rf:read(ids.TEX_MSGS)
  local textures = {} -- ordered list of textures and map (name => texture)

  for texid = 0,#names do
    -- strings are nul terminated
    local name = names[texid]
    local msg = msgs[texid]
    local key = name .. '\n' .. msg

    if textures[key] then
      table.insert(textures[key].texids, texid)
    else
      textures[key] = {
        texids = { texid };
        name = name;
        use = msg;
      }
      table.insert(textures, textures[key])
    end
  end

  local buf = { TEX_HEADER }
  for _,tex in ipairs(textures) do
    table.insert(buf, TEX_TEMPLATE:format(
      tex.name, table.concat(tex.texids, ', '), tex.name, tex.use))
  end
  return table.concat(buf, '')
end
