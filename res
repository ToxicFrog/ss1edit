#!/usr/bin/env lua5.2
-- :mode=lua: --

package.path = package.path .. ";lib/?.lua;lib/?/init.lua"

require "util"
local res = require "ss1.res"

local HELP_TEXT = [[
Usage: res <mode> <args>
Modes:
    l <file>
        list file contents
    x <file> <prefix> [chunk...]
        extract file contents to prefix/<chunk id>
        if no chunks specified, unpack entire file
    c (not implemented)
        pack chunks into new file
    d <infile> <outfile>
        decompress all chunks in infile and store in outfile
    u <file> <prefix> [chunk...]
      update chunks already present in file
      read chunks from prefix/<chunk id>
      if no chunks specified, is a no-op! FIXME..
]]

local mode = {}

-- List
function mode.l(file, ...)
  local rf = res.load(file)

  printf("Comment: %s\n", rf.comment)
  printf("File contains %u chunks\n", rf.count)

  printf("id      id      size    type        packed  dir\n")
  for id,chunk in rf:chunks(unpack(table.map({...}, tonumber))) do
    printf("%05u   %04x    %-7u %-11s %-8s%s\n", id, id,
      chunk.size,
      chunk.typename,
      chunk.compressed and tostring(chunk.packed_size) or "",
      chunk.dir and tostring(#chunk.subchunks) or "")
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

    if chunk.data then
  for id,chunk in rf:chunks(unpack(table.map({...}, tonumber))) do
      local fd = io.open(prefix .. tostring(chunk.id), "wb")
      fd:write(chunk.data)
      fd:close()
    end
  end
end

-- Create
function mode.c(file, chunks)
  error "creation is not yet implemented"
end

-- Update
function mode.u(infile, outfile, prefix, ...)
  local rf = res.load(infile)

  for _,id in ipairs(table.map({...}, tonumber)) do
    if rf:get(id) then
      local data = assert(io.open(prefix .. "/" .. tostring(id), "rb")):read("*a")
      rf:get(id).data = data
    else
      error("Attempted to add chunk "..id.." that does not exist in file!")
    end
  end

  rf:save(outfile)
end

function mode.d(infile, outfile)
  local rf = res.load(infile)
  rf:save(outfile)
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
