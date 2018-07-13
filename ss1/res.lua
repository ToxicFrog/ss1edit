local vstruct = require "vstruct"

local res = {}
res.__index = res

local typenames = {
  [0x00] = "palette";
  [0x01] = "string";
  [0x02] = "image";
  [0x03] = "font";
  [0x04] = "animation";
  [0x07] = "sound";
  [0x0F] = "model";
  [0x11] = "movie";
  [0x30] = "map";
}
for k,v in pairs(typenames) do
  if type(k) == 'number' then
    typenames[v] = k
  end
end

local RES_TOC = [[
  %d * {
    id:u2
    size:u3
    [1|x6 compound:b1 compressed:b1]
    packed_size:u3
    type:u1
  }
]]

local decompress = require 'ss1.res.decompress'
local helpers = require 'ss1.res.helpers'

function res.new(name)
  local self = { name = name; data = {}; meta = {}; }
  return setmetatable(self, res)
end

function res.load(filename)
  local fd,err = io.open(filename, "rb")
  if not fd then return nil,err end

  local self = res.new(filename)

  -- Read file header.
  local toc_offs
  self.comment,toc_offs = vstruct.readvals("z124 u4", fd)

  -- Read TOC header, then read the entire TOC into memory.
  local nrof_resources,data_offs = vstruct.readvals("@%d u2 u4" % toc_offs, fd)
  local toc = vstruct.read(RES_TOC % nrof_resources, fd)

  -- Seek to start of resource data in preparation to read the resources.
  -- N.b. in unmodified resfiles this may be a no-op, since usually the data
  -- immediately follows the TOC. Files written by this library place the TOC
  -- at the *end*, however, so this seek is necessary.
  fd:seek("set", data_offs)

  for _,meta in ipairs(toc) do
    meta.typename = assertf(typenames[meta.type], "Resource %d has unknown type %d in %s",
      meta.id, meta.type, self.name)
    self.meta[meta.id] = meta
    self.data[meta.id] = vstruct.readvals("a4 s%d" % meta.packed_size, fd)

    if meta.compound and meta.compressed then
      error("No support for compressed compound resource %s in %s", meta.id, self.name)
    end

    if meta.compound then
      self.data[meta.id] = helpers.unpack_compound(self.data[meta.id])
    end
  end

  fd:close()

  return self
end

function res:save(filename)
  local fd,err = io.open(filename, "wb")
  if not fd then return nil,err end

  -- Write the header. Write 0 for offset to TOC, we'll fill that in later.
  vstruct.write("z124 u4", fd, { self.comment, 0 })

  -- Write the resource data and build the TOC in the same order.
  local toc = {}
  for id,meta in pairs(self.meta) do
    table.insert(toc, meta)
    if meta.compound then
      vstruct.write("a4 s%d" % meta.packed_size, fd, { helpers.pack_compound(self.data[id]) })
    else
      vstruct.write("a4 s%d" % meta.packed_size, fd, { self.data[id] })
    end
  end

  -- write TOC
  vstruct.write("a4", fd, {})
  local toc_offs = fd:seek("cur", 0)
  vstruct.write("u2 u4", fd, { #toc, 128 }) -- number of TOC entries and offset of file data
  vstruct.write(RES_TOC % #toc, fd, toc)

  -- write TOC pointer
  vstruct.write("@124 u4", fd, { toc_offs })

  -- commit
  fd:close()
end

-- Return an iterator over all resource metadata, equivalent to calling
-- res:stat() on each entry.
function res:ls()
  return coroutine.wrap(function()
    for id in pairs(self.meta) do
      coroutine.yield(self:stat(id))
    end
  end)
end

-- Return an iterator over all resources and their contents.
-- N.b. compressed resources will be decompressed as they are read. This is
-- potentially expensive. use res:ls() if you just want the metadata.
function res:contents()
  return coroutine.wrap(function()
    for id in pairs(self.meta) do
      coroutine.yield(self:stat(id), self:read(id))
    end
  end)
end

-- Return (readonly) metadata about a resource.
-- If the resource does not exist, returns nil.
function res:stat(id)
  if not self.meta[id] then
    return nil
  end
  return helpers.readonly(self.meta[id])
end

-- Read a resource's data. Compressed resources are decompressed on the fly.
-- Unlike stat, this throws if you attempt to read a missing resource.
-- This returns the contents of the resource with no postprocessing of any kind,
-- apart from decompression.
function res:raw_read(id)
  assertf(self.meta[id],
    "Attempt to read missing resource %s in resfile %s", id, self.name)
  if self.meta[id].compound then
    return table.copy(self.data[id])
  elseif self.meta[id].compressed then
    return decompress(self.data[id], self.meta[id].size)
  else
    return self.data[id]
  end
end

-- Like raw_read, but may do postprocessing to make the returned data easier to
-- work with.
-- At the moment this just means stripping the null termination from strings.
function res:read(id)
  return helpers.postprocess(self.meta[id], self:raw_read(id))
end

function res:write(id, data)
  return self:raw_write(id, helpers.preprocess(self.meta[id], data))
end

-- res:raw_write(id, data)
-- Write data to an existing resource. Ensures that the metadata is correctly
-- updated as well.
-- No preprocessing of the data is done.
function res:raw_write(id, data)
  assertf(self.meta[id],
    "Attempt to write missing resource %s in resfile %s", id, self.name)
  local meta = self.meta[id]

  if type(data) == 'string' then
    meta.size = #data
    meta.compound = false
  elseif type(data) == 'table' then
    assertf(data[0], "Compound resource %s must contain at least one entry", id)
    -- in-resource TOC is 6 bytes header/footer + 4 bytes per block
    meta.size = 6 + 4 * (#data + 1)
    meta.compound = true
    for i=0,#data do
      -- plus the size of each individual block
      meta.size = meta.size + #data[i]
    end
  else
    error("res.write: data must be a string or table")
  end

  self.data[id] = data
  meta.packed_size = meta.size
  meta.compressed = false
end

-- Create a new empty resource of the given type.
function res:create(id, typeid)
  assertf(not self.meta[id],
    "Attempt to create resource %s, but that id is already used in %s", id, self.name)
  assertf(typenames[type],
    "Attempt to create resource %s with unrecognized type %s", id, tostring(typeid))

  local typename
  if type(typeid) == 'number' then
    typename = typenames[typeid]
  else
    typeid,typename = typenames[typeid],typeid
  end

  self.meta = {
    id = id;
    type = typeid; typename = typename;
    size = 0; packed_size = 0;
    compound = false; compressed = false;
  }
  self.data = ''
end

-- Delete a resource.
function res:delete(id)
  assertf(self.meta[id],
    "Attempt to delete missing resource %s from resfile %s", id, self.name)
  self.meta[id] = nil
  self.data[id] = nil
end

return res
