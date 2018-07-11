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

-- Decompress a compressed resource.
local function decompress(data, unpacksize)
  local words = coroutine.wrap(function()
    local yield = coroutine.yield
    local word,nbits = 0,0
    for char in data:gmatch(".") do
      word = bit32.bor(bit32.lshift(word, 8), char:byte())
      nbits = nbits + 8

      if nbits >= 14 then
        nbits = nbits - 14
        yield(bit32.band(bit32.rshift(word, nbits), 0x3FFF))
      end
    end
  end)

  local offs_token,len_token,org_token = {},{},{}

  local unpacked = ""

  local ntokens = 0
  for i=0,16383 do
    len_token[i] = 1
    org_token[i] = -1
  end

  local byteptr,exptr = 0,0,0,0
  for val in words do
    if val == 0x3FFF then
      if #unpacked < unpacksize then
        eprintf("WARNING: unpack break early after %d/%d bytes due to STOP marker\n", #unpacked, unpacksize)
      end
      break
    end

    if val == 0x3FFE then
      ntokens = 0
      for i=0,16383 do
        len_token[i] = 1
        org_token[i] = -1
      end
      goto continue
    end

    if ntokens < 16384 then
      offs_token[ntokens] = exptr
      if val >= 0x100 then
        org_token[ntokens] = val - 0x100
      end
      ntokens = ntokens +1
    end

    if val < 0x100 then
      exptr = exptr + 1
      unpacked = unpacked .. string.char(val)
    else
      val = val - 0x100

      if len_token[val] == 1 then
        if org_token[val] ~= -1 then
          len_token[val] = len_token[val] + len_token[org_token[val]]
        else
          len_token[val] = len_token[val] + 1
        end
      end

      local testbuf = unpacked:sub(offs_token[val] + 1, offs_token[val] + len_token[val])
      if #testbuf < len_token[val] then
        testbuf = testbuf .. string.char(0):rep(len_token[val] - #testbuf)
      end

      for i=1,len_token[val] do
        unpacked = unpacked .. unpacked:sub(offs_token[val] + i, offs_token[val] + i)
      end
      exptr = exptr + len_token[val]

      assert(#testbuf == len_token[val], "fencepost error")
      --assert(testbuf == unpacked:sub(-#testbuf), "unpack boundary error")
    end

    ::continue::
  end

  assert(#unpacked == unpacksize, "buffer size mismatch: %d != %d" % { #unpacked, unpacksize })
  return unpacked
end

-- Unpack a compound resource into a table.
local function unpack_compound(data)
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
local function pack_compound(blocks)
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
      error("No support for compressed compound resource %d in %s", meta.id, self.name)
    end

    if meta.compound then
      self.data[meta.id] = unpack_compound(self.data[meta.id])
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
      vstruct.write("a4 s%d" % meta.packed_size, fd, { pack_compound(self.data[id]) })
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

local function readonly(t)
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
function res:stat(id)
  assertf(self.meta[id],
    "Attempt to read missing resource %d in resfile %s", id, self.name)
  return readonly(self.meta[id])
end

-- Read a resource's data. Compressed resources are decompressed on the fly.
function res:read(id)
  assertf(self.meta[id],
    "Attempt to read missing resource %d in resfile %s", id, self.name)
  if self.meta[id].compound then
    return table.copy(self.data[id])
  elseif self.meta[id].compressed then
    return decompress(self.data[id], self.meta[id].size)
  else
    return self.data[id]
  end
end

-- res:write(id, data)
-- Write data to an existing resource. Ensures that the metadata is correctly
-- updated as well.
function res:write(id, data)
  assertf(self.meta[id],
    "Attempt to write missing resource %d in resfile %s", id, self.name)
  local meta = self.meta[id]

  if type(data) == 'string' then
    meta.size = #data
    meta.compound = false
  elseif type(data) == 'table' then
    assertf(data[0], "Compound resource %d must contain at least one entry", id)
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
    "Attempt to create resource %d, but that id is already used in %s", id, self.name)
  assertf(typenames[type],
    "Attempt to create resource %d with unrecognized type %s", id, tostring(typeid))

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
    "Attempt to delete missing resource %d from resfile %s", id, self.name)
  self.meta[id] = nil
  self.data[id] = nil
end

return res
