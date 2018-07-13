-- Environment for executing the edited repack scripts.

local repack = {}
local ids = require 'ids'

function repack.texture(rf, tex)
  local names = rf:read(ids.TEX_NAMES)
  local msgs = rf:read(ids.TEX_MSGS)
  for _,texid in ipairs(tex.texids) do
    names[texid] = tex.name
    msgs[texid] = tex.use
  end
  rf:write(ids.TEX_NAMES, names)
  rf:write(ids.TEX_MSGS, msgs)
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
        data[0] = subline
      else
        table.insert(data, subline)
      end
    end
    if n ~= #paper then
      table.insert(data, '\n')
    end
  end
  table.insert(data, '')
  rf:write(paper.resid, data)
end

function repack.log(rf, log)
  -- Similar to paper, but we have more metadata to worry about.
  local data = {
    rf:read(log.resid)[0], -- metadata; unchanged from original
    log.title, log.sender, log.subject;
  }
  for _,line in ipairs(log.verbose) do
    table.insert(data, line)
  end
  table.insert(data, '')
  for _,line in ipairs(log.terse) do
    table.insert(data, line)
  end
  table.insert(data, '')
  end

return repack
