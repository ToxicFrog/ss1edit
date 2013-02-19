#!/usr/bin/env lua5.2
-- :mode=lua: --

require "util"
local res = require "res"

local HELP_TEXT = [[
Usage: res <mode> <args>
Modes:
    l <file>        list file contents
    x <file>        extract file contents
    c <file> <dir>  pack contents of dir into file
]]

local mode = {}

-- List
function mode.l(file)
	local rf = res.load(file)

	printf("Comment: %s\n", rf.comment)
	printf("File contains %u chunks\n", rf.count)

	printf("id      id      size    type\n")
	for id,chunk in rf:chunks() do
		printf("%05u   %04x    %-7u %s\n", id, id, chunk.size, chunk.typename)
	end
end

-- eXtract
function mode.x(file)
	error "extraction is not yet implemented"
end

-- Create
function mode.c(...)
	error "creation is not yet implemented"
end

local function main(...)
	local argv = {...}

	if not mode[argv[1]] then
		print(HELP_TEXT)
		return
	end

	return mode[argv[1]](select(2, ...))
end

do return main(...) end

function main(filename)
	local rf = assert(ss1.res.load(filename))
	
	print('%s: %d chunks' % { filename, rf.count })
	print('Comment: "%s"' % rf.comment:gsub('[\r\n]', '\\n'))
	
	print("   ID              type      size")
	for id,chunk in ipairs(rf) do
		printf("%5d  %16s  %8d%s%s\n",
			chunk.id,
			tostring(chunk.type), --res.typename(chunk.type),
			chunk.size,
			chunk.compressed and " (compressed %d)" % chunk.packsize or "",
			chunk.directory and " (directory: %d subchunks)" % #chunk.content or ""
		)
	end
end

do return main(...) end
