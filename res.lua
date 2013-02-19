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


function res.load(filename)
	local RES_TOCENTRY = [[%d * { id:u2 size:u3 [1|compressed:b1 dir:b1 x6] packed_size:u3 type:u1 }]]
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

    	if chunk.compressed then
    		eprintf("WARNING: skipping compressed chunk %05d (%04x)\n", chunk.id, chunk.id)
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