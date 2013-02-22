local struct = require "vstruct"

local res = {}

local mt = { __index = res }

local typenames = {
	[0x00] = "palette/data";
	[0x01] = "text";
	[0x02] = "bitmap";
	[0x03] = "font";
	[0x04] = "video";
	[0x07] = "sound";
	[0x0F] = "3d model";
	[0x11] = "audio log";
	[0x30] = "map";
}

-- decompress a compressed chunk
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

function res.load(filename)
	local RES_TOCENTRY = [[%d * { id:u2 size:u3 [1|x6 dir:b1 compressed:b1] packed_size:u3 type:u1 }]]
    local toc_offs,chunk_offs

	local fd,err = io.open(filename, "rb")
	if not fd then return nil,err end

    local self = {}
    
    -- read file header and TOC header
    -- self.comment,toc_offs,self.count,chunk_offs = struct.unpack("z124 u4 @$2 u2 u4")
    self.comment,toc_offs = struct.unpack("z124 u4", fd, true)
    self.count,chunk_offs = struct.unpack("@%d u2 u4" % toc_offs, fd, true)
    
    -- read the entire TOC into memory
    self.toc = struct.unpack(RES_TOCENTRY % self.count, fd, false)

    -- prepare to unpack the chunk data
    fd:seek("set", chunk_offs)
    
    for i,chunk in ipairs(self.toc) do
    	chunk.packed_data = struct.unpack("a4 s%d" % chunk.packed_size, fd, true)

    	if chunk.compressed and chunk.dir then
    		eprintf("WARNING: skipping compressed chunk directory %05d (%04x)\n", chunk.id, chunk.id)
		elseif chunk.compressed then
			chunk.data = decompress(chunk.packed_data, chunk.size)
    	else
    		chunk.data = chunk.packed_data
    	end

    	chunk.typename = typenames[chunk.type] or "unknown"
    end

    -- sort the TOC by ID
    list.sort(self.toc, function(x,y) return x.id < y.id end)
    
    return setmetatable(self, mt)
end

function res:chunks()
	return coroutine.wrap(function()
		for _,chunk in ipairs(self.toc) do
			coroutine.yield(chunk.id, chunk)
		end
	end)
end

return res