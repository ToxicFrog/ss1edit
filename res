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

flags.register("hex-ids", "X") {
  help = "name extracted files using hexadecimal rather than base-10 IDs";
  key = "idformat"; value = "x%04X";
  default = "%05d";
}

local mode = {}

local function extension(chunk)
  if chunk.typename ~= "unknown" then
    return "ss1"..chunk.typename
  else
    return "ss1x%02X" % chunk.type
  end
end

local function filename(chunk)
  return (flag.idformat..".%s") % { chunk.id, extension(chunk) }
end

-- List
function mode.list(...)
  local file = flags.require "res"
  local rf = res.load(file)

  printf("Comment: %s\n", rf.comment)
  printf("File contains %u chunks\n", rf.count)

  printf("   id    size      type  packed   dir\n")
  for id,chunk in rf:chunks(...) do
    printf(flag.idformat .. "  %6u  %8s  %6s  %4s\n",
      id,
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

  for id,chunk in rf:chunks(...) do
    if chunk.dir and flag "subchunks" then
      local dir = "%s/%s" % { prefix, filename(chunk) }
      require("lfs").mkdir(dir)
      for index,subchunk in ipairs(chunk.subchunks) do
        io.writefile(("%s/"..flag.idformat) % { dir, index-1 }, subchunk)
      end
      io.writefile("%s/data" % dir, chunk.data)
    else
      io.writefile("%s/%s" % { prefix, filename(chunk) }, chunk.data)
    end
  end
end

-- Update
function mode.update(...)
  local infile = flags.require "res"
  local outfile = flag.in_place and infile or flag.out or error("--update requires both --res and --out")
  local prefix = flag.prefix
  local rf = res.load(infile)

  for _,id in ipairs {...} do
    if rf:get(id) then
      rf:get(id).data = assert(io.readfile("%s/%d" % { prefix, id }))
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
  for i,chunk in ipairs(opts) do
    opts[i] = assert(tonumber(opts[i]),
      "can't convert argument '%s' into a chunk ID -- did you mean to use --res?" % opts[i])
  end
  return mode[opts.mode](unpack(opts))
end

return main(...)
