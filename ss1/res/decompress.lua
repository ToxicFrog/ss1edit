-- Depending on whether we're running in luajit or lua5.x, we might have one
-- or the other of these available.
local bit32 = bit32 or bit

-- Decompress a compressed resource.
-- This is a straightforward translation of the C implementation from TSSHP into
-- Lua; it is known to be quite slow, even in luajit.
return function(data, unpacksize)
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
