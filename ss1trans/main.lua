#!/usr/bin/env luajit

-- Translation tool for System Shock 1
-- Converts a res file into a bunch of .txt files ready for editing, or vice versa.
-- Try me with:
--   ss1trans CYBSTRNG.RES
--   $EDITOR textures.txt
--   $EDITOR papers.txt
--   ss1trans trnstrng.txt
-- to get a TRNSTRNG.RES file containing the results of the patches in
-- textures.txt and papers.txt.

function main(...)
  package.path = "?.lua;deps/?.lua;deps/?/init.lua;" .. package.path

  require "util"
  local res = require "ss1.res"

  if select('#', ...) ~= 1 then
    print('Usage: ss1trans (foo.res|foo.txt)')
    return 1
  end

  local loader_environment = {
    load = function(path) _RF = assert(res.load(path)) end;
    save = function(path) _RF:save(path) end;
    patch = function(path)
      local fn = assert(loadfile(path))
      local env = {}
      for k,v in pairs(require 'repack') do
        env[k] = function(data) return v(_RF, data) end
      end
      setfenv(fn, env)
      fn()
    end;
  }

  local input = ...
  if input:match('%.RES$') then
    local rf = assert(res.load(input))

    io.writefile('trnstrng.txt', [[
  load 'CYBSTRNG.RES'
  patch 'logs.txt'
  patch 'objects.txt'
  patch 'papers.txt'
  patch 'textures.txt'
  save 'TRNSTRNG.RES'
  ]])

    for _,file in ipairs { 'textures', 'papers', 'logs', 'objects' } do
      io.writefile(file .. '.txt', require(file)(rf))
    end
  else
    fn = assert(loadfile(input))
    setfenv(fn, loader_environment)
    fn()
  end
end

if love then
  -- love2d compatibility
  function love.load(argv)
    main(unpack(argv, 2)) -- drop first argument, since it's the name of the .love file
    os.exit(0)
  end
else
  main(...)
end
