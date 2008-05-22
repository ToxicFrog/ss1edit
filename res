#!/bin/env lua

-- a simple command line program for packing and unpacking res files
-- stage 1: simply list the contents

package.path = "lib/?.lua;lib/?/init.lua;"..package.path

require "res"

function main(filename)
	local rf = assert(res.open(filename))
	
	print('%s: %d chunks' % { filename, rf.count })
	print('Comment: "%s"' % rf.comment:gsub('\n', '\\n'))
	
	print("   ID              type      size")
	for id,chunk in ipairs(rf) do
		printf("%5d  %16s  %8d%s%s\n",
			chunk.id,
			res.typename(chunk.type),
			chunk.size,
			chunk.compressed and " (compressed %d)" % chunk.packsize or "",
			chunk.nested and " (directory: %d subchunks)" % #chunk.content or ""
		)
	end
end

do return main(...) end
