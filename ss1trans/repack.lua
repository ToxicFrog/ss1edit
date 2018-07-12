local repack = {}

local TEX_NAMES = 2154
local TEX_USE = 2155

function repack.texture(rf, tex)
  local names = rf:read(TEX_NAMES)
  local msgs = rf:read(TEX_USE)
  for _,texid in ipairs(tex.texids) do
    names[texid] = tex.name .. '\0'
    msgs[texid] = tex.use .. '\0'
  end
  rf:write(TEX_NAMES, names)
  rf:write(TEX_USE, msgs)
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
    if n ~= #paper and n > 0 then
      table.insert(data, '\n\0')
    end
  end
  table.insert(data, '\0')
  rf:write(paper.resid, data)
end

return repack
