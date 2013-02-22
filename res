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

	printf("id      id      size    type        packed  dir\n")
	for id,chunk in rf:chunks() do
		printf("%05u   %04x    %-7u %-11s %-8s%s\n", id, id,
			chunk.size,
			chunk.typename,
			chunk.compressed and tostring(chunk.packed_size) or "",
			chunk.dir and "yes" or "")
	end
end

-- eXtract
function mode.x(file, prefix, ...)
	local rf = res.load(file)
	if prefix then
		prefix = prefix .. "/"
	else
		prefix = ""
	end

	for id,chunk in rf:chunks() do
		if chunk.data then
			local fd = io.open(prefix .. tostring(chunk.id), "wb")
			fd:write(chunk.data)
			fd:close()
		end
	end
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

return main(...)
