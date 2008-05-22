--[[
	File specification:
		type: "resfile"
		tostring: "resfile: 0x12345678"
		members:
			comment 	header comment from res file
		RO	count		number of chunks in file
		IN	index		mapping of id => chunk
	Chunk specifications:
		type: "reschunk"
		tostring: "reschunk: 0x12345678"
		members:
			type		numeric type of content
			compressed	true if chunk was compressed in file
			directory	true if chunk is a directory
			packsize	size of chunk on disk after compression
			size		size of chunk on disk before compression
						for directories, this is the sum of the sizes of all
						contained chunks + the size of the directory header
			content 	flat: the raw content of the chunk
						dir: a table containing a list of contents
			flags		raw boolean flag table
			
]]

require "struct"
require "util"

res = {}

local rh_metatable = {
	__index = res;
}

function rh_metatable:__type()
	return "resfile"
end

function rh_metatable:__tostring()
	return "resfile: "..tostring(self.index):gsub('table: ', '')
end

function rh_metatable:__pairs()
	return pairs(self.index)
end

function rh_metatable:__ipairs()
	return coroutine.wrap(function()
		for i=1,2^16 do
			if self.index[i] then
				coroutine.yield(i,self.index[i])
			end
		end
	end)
end

local res_types = {
	[0x00] = "palette/raw data";
	[0x01] = "text";
	[0x02] = "bitmap";
	[0x03] = "font";
	[0x04] = "video";
	[0x07] = "sound";
	[0x0F] = "3d model";
	[0x11] = "speech";
	[0x30] = "map";
}

-- map a numeric type id to a readable name
-- returns the type id if no name is known
function res.typename(t)
	return res_types[t] or ("0x%02X" % t)
end

-- FIXME
function res_decompress(c)
	return c
end

local function read_content(file, chunk)
	local content = struct.unpack(file, "a4 s%d" % chunk.packsize)
	
	if chunk.compressed then
		content = res_decompress(content)
		-- FIXME
		chunk.directory = false
	end
	
	if chunk.directory then
		chunk.content = {}
		local count = struct.unpack(content, "u2")
		local offsets = { struct.unpack(content, "@2 (u4)*%d" % (count+1)) }
		for i=1,count do
			chunk.content[i] = content:sub(offsets[i]+1, offsets[i+1])
		end
	else
		chunk.content = content
	end
	
	return chunk
end

-- res_file res.open(string filename | fd file)
-- open a file, read all metadata and chunk data, and return a resource handle
function res.open(file)
	local err,_
	
	-- if we were passed a filename, open it
	if type(file) == "string" then
		file,err = io.open(file, "rb")
		if not file then
			return file,err
		end
	end
	
	local rh = setmetatable({ index = {} }, rh_metatable)

	local toc_offs,data_offs
	
	rh.comment,toc_offs = struct.unpack(file, '@0 z124 u4')
	rh.count,data_offs = struct.unpack(file, '@%d u2 u4' % toc_offs)
		
	local chunks = { struct.unpack(file, "{ id:u2 size:u3 flags:m1 packsize:u3 type:u1 }*%d" % rh.count) }

	file:seek("set", data_offs)
	
	for i,chunk in ipairs(chunks) do
		chunk.compressed = chunk.flags[1]
		chunk.directory = chunk.flags[2]
		read_content(file, chunk)
		rh.index[chunk.id] = chunk
	end
		
	file:close()
	
	return rh
end

-- get a single chunk from the resource file
-- returns the chunk structure or nil
function res:get(id)
	return self.index[id]
end

return res

--[[
-- write out all changes to disk
-- use the given filename, or if none specified, use the filename
-- originally passed to res.open()
-- returns the number of chunks written
function res.save(rh, filename)
	filename = filename or rh.filename
end

-- write out all changes to disk as save(), then clear all resources held by
-- this handle
-- returns the number of chunks written
-- if the save fails, will not free the rh
function res.close(rh)
	local r,e = rh:save()
	if not r then return nil,e end
	
	rh:destroy()
	return r
end

-- write a new chunk into the file, or replace an old one
-- note that in most cases, chunk modification is done by modifying the
-- structure returned by :read(); this is for adding entirely new chunks
-- or copying chunks from other files
-- returns true if an existing chunk was overwritten, false otherwise
function res.write(rh, id, chunk)
	local exists = rh.index[id] ~= nil
	rh.index[id] = chunk
	return exists
end

function res.pool()
end

local function res_readdata(chunk, fin, offset)
	fin:seek("set", offset)
	
	print("DEBUG", chunk.packsize, type(chunk.packsize))
	chunk.data = fin:read(chunk.packsize)
	
	if chunk.compressed then
		chunk.data = res_decompress(chunk.data)
	end
	
	if chunk.nested then
		local buf,data = chunk.data,{}
		local count = struct.unpack(buf, "@0 u2")
		local offsets = { struct.unpack(buf, "@2 "..("u4"):rep(count+1)) }
		for i=1,count do
			data[i] = buf:sub(offsets[i]+1, offsets[i+1])
		end
		chunk.data = data
	end
end
--]]
