#!/usr/bin/env lua5.2
-- :mode=lua: --

package.path = package.path .. ";lib/?.lua;lib/?/init.lua"

require "util"
local res = require "ss1.res"

flags.register("help", "h", "?") {
  help = "display this text";
  key = "mode"; value = "help";
  exclusive = true;
  default = "help";
}

flags.register("list", "l") {
  help = "list resfile contents";
  key = "mode"; value = "list";
}

flags.register("extract", "x") {
  help = "extract resfile contents";
  key = "mode"; value = "extract";
}

flags.register("decompress", "d") {
  help = "decompress a resfile";
  key = "mode"; value = "decompress";
}

flags.register("update", "u") {
  help = "update resfile contents";
  key = "mode"; value = "update";
}

flags.register("res", "r") {
  help = "use this resfile as input";
  type = flags.string;
}

flags.register("out", "o") {
  help = "output to this file when decompressing or updating";
  type = flags.string;
}

flags.register("prefix", "p") {
  help = "directory to save chunks in (extract) or read chunks from (update)";
  type = flags.string;
  default = ".";
}

flags.register("in-place", "i") {
  help = "modify the resfile in-place (for update and decompress)";
}

flags.register("subchunks") {
  help = "extract subchunks into directories";
}

local mode = {}

-- List
function mode.list(...)
  local file = flags.require "res"
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
function mode.extract(...)
  local file = flags.require "res"
  local prefix = flag.prefix
  local rf = res.load(file)

  for id,chunk in rf:chunks(unpack(table.map({...}, tonumber))) do
    if chunk.dir and flag "subchunks" then
      require("lfs").mkdir(prefix.."/"..tostring(chunk.id))
      for index,subchunk in ipairs(chunk.subchunks) do
        io.writefile(prefix.."/"..tostring(chunk.id).."/"..tostring(index-1), subchunk)
      end
    else
      local fd = io.open(prefix .. "/" .. tostring(chunk.id), "wb")
      fd:write(chunk.data)
      fd:close()
    end
  end
end

-- Update
function mode.update(...)
  local infile = flags.require "res"
  local outfile = flag.in_place and infile or flag.out or error("--update requires both --res and --out")
  local prefix = flag.prefix
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

function mode.decompress()
  local infile = flags.require "res"
  local outfile = flag.in_place and infile or flag.out or error("--decompress requires both --res and --out")
  local rf = res.load(infile)
  rf:save(outfile)
end

mode.help = flags.help

local function main(...)
  local opts = flags.parse(...)
  return mode[opts.mode](unpack(opts))
end

return main(...)
