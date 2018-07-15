-- Helper functions for resfile handling not exposed as part of the main API.

local vstruct = require 'vstruct'
local helpers = {}

-- Unpack a compound resource into a table.
-- N.b. to match the resource numbering used by SS1, indexing starts at 0, not 1.
-- Be careful using # on it.
-- TODO: use __ipairs and __len so that it does the right thing.
function helpers.unpack_compound(data)
  local data = vstruct.cursor(data)
  local count = vstruct.readvals('u2', data)
  local toc = vstruct.read('%d * u4' % (count+1), data)

  local blocks = {}
  for i=1,count do
    blocks[i-1] = vstruct.readvals("@%d s%d" % {toc[i], toc[i+1] - toc[i]}, data)
  end
  return blocks
end

-- Pack a table into a compound resource.
-- Like unpack_compound, this expects 0-indexing.
function helpers.pack_compound(blocks)
  local data = vstruct.cursor('')
  local data_offs = 6 + 4 * (#blocks+1)
  vstruct.write('u2', data, { #blocks+1 })
  for i=0,#blocks do
    vstruct.write('u4', data, { data_offs })
    data_offs = data_offs + #blocks[i]
  end
  vstruct.write('u4 s s', data, { data_offs, blocks[0], table.concat(blocks, '') })
  return data.str
end

-- Given a table, return a readonly shadow of it.
-- [], pairs, and ipairs all work normally, but attempting to assign to any field
-- in the table will throw.
function helpers.readonly(t)
  local mt = {
    __index = t;
    __newindex = function(self, key)
      error("Attempt to set readonly field '%s' of table %s" % {
        tostring(key), tostring(self)
      })
    end;
    __pairs = function() return pairs(t) end;
    __ipairs = function() return ipairs(t) end;
  }
  return setmetatable(t, mt)
end

local cp437 = require 'ss1.res.cp437'

-- Called just after :read to turn the data into something the caller can more
-- easily digest. Eventually this might convert image formats, sound formats,
-- etc; at the moment it just strips null termination from strings and converts
-- them from cp437 to utf8.
function helpers.postprocess(meta, data)
  if meta.typename ~= 'string' then
    return data
  elseif meta.compound then
    for k,v in pairs(data) do
      -- postprocess is called on the copy of the data we're going to return to
      -- the caller, not the original data in the res file, so it's safe to
      -- mutate here.
      data[k] = cp437.CP437toUTF8(v:gsub('%z$', ''))
    end
    return data
  else
    return cp437.CP437toUTF8(data:gsub('%z$', ''))
  end
end

-- Called just before :write to turn the data into something that is valid for
-- SS1. At present this just adds null termination to strings and converts them
-- from utf8 to cp437.
function helpers.preprocess(meta, data)
  if meta.typename ~= 'string' then
    return data
  elseif meta.compound then
    -- Make a copy, since we don't know if the caller wants to keep it and do
    -- more stuff with it.
    return table.mapv(data, function(s) return cp437.UTF8toCP437(s)..'\0' end)
  else
    return cp437.UTF8toCP437(data) .. '\0'
  end
end

return helpers
