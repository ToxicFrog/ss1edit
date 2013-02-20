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
	local offs_token,len_token,org_token = {},{},{}
	local unpacked = ""

	local function bytes(offset, length)
		return data:sub(offset, offset+(length or 1)-1)
	end

	local ntokens = 0
	for i=0,16383 do
		len_token[i] = 1
		org_token[i] = -1
	end

	local nbits,word,byteptr,exptr = 0,0,0,0
	while #unpacked < unpacksize do
		while nbits < 14 do
			word = bit32.bor(bit32.lshift(word, 8), bytes(byteptr):byte())
			nbits = nbits + 8
			byteptr = byteptr + 1
		end

		nbits = nbits - 14
		local val = bit32.band(bit32.rshift(word, nbits), 0x3FFF)
		eprintf("BITS: %04x\n", val)
		if val == 0x3FFF then
			eprintf("WARNING: unpack break early after %d/%d bytes due to STOP marker\n", #unpacked, unpacksize)
			break
		end

		if val == 0x3FFE then
			ntokens = 0
			eprintf("UNPACK resetting dictionary\n")
			for i=0,16383 do
				len_token[i] = 1
				org_token[i] = -1
			end
			goto continue
		end

		if ntokens < 16384 then
			eprintf("UNPACK recording unpack offset of token %d as %d\n", ntokens, exptr)
			offs_token[ntokens] = exptr
			if val >= 0x100 then
				org_token[ntokens] = val - 0x100
			end
			ntokens = ntokens +1
		end

		if val < 0x100 then
			eprintf("UNPACK writing literal %02x\n", val)
			exptr = exptr + 1
			unpacked = unpacked .. string.char(val)
		else
			val = val - 0x100
			eprintf("UNPACK expanding compressed word %d (orig=%d, length=%d)\n", val, org_token[val], len_token[val])

			if len_token[val] == 1 then
				if org_token[val] ~= -1 then
					len_token[val] = len_token[val] + len_token[org_token[val]]
				else
					len_token[val] = len_token[val] + 1
				end
			end

			unpacked = unpacked .. data:sub(offs_token[val]+1, offs_token[val] + len_token[val])
			exptr = exptr + len_token[val]
		end

		::continue::
	end

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
			eprintf("DECOMPRESS %d %d->%d\n", chunk.id, chunk.packed_size, chunk.size)
			eprintf("%s\n", chunk.packed_data:sub(1,20):gsub(".", f "c => string.format('%02x ', c:byte())"))
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