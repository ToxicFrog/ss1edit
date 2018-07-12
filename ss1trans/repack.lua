-- Environment for executing the edited repack scripts.

local repack = {}
local ids = require 'ss1trans.ids'

function repack.texture(rf, tex)
  local names = rf:read(ids.TEX_NAMES)
  local msgs = rf:read(ids.TEX_MSGS)
  for _,texid in ipairs(tex.texids) do
    names[texid] = tex.name .. '\0'
    msgs[texid] = tex.use .. '\0'
  end
  rf:write(TEX_NAMES, names)
  rf:write(TEX_MSGS, msgs)
end

function repack.object(rf, obj)
  local longnames = rf:read(ids.OBJ_LONG_NAMES)
  local shortnames = rf:read(ids.OBJ_SHORT_NAMES)
  longnames[obj.objid] = obj.name
  shortnames[obj.objid] = obj.shortname
  rf:write(ids.OBJ_LONG_NAMES, longnames)
  rf:write(ids.OBJ_SHORT_NAMES, shortnames)
  -- TODO: handle descriptions for those objects that have them
end

function repack.paper(rf, paper)
  -- paper contains a 1-indexed array of lines. We need to wrap them at 80 and
  -- store them in data 0-indexed
  local data = {}
  for n,line in ipairs(paper) do
    for _,subline in ipairs(line:wrap(80, true)) do
      if not data[0] then
        data[0] = subline .. '\0'
      else
        table.insert(data, subline .. '\0')
      end
    end
    if n ~= #paper then
      table.insert(data, '\n\0')
    end
  end
  table.insert(data, '\0')
  rf:write(paper.resid, data)
end

return repack
