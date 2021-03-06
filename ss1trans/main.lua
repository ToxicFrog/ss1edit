#!/usr/bin/env luajit

-- Translation tool for System Shock 1
-- Converts a res file into a bunch of .txt files ready for editing, or vice versa.
-- Try me with:
--   ss1trans CYBSTRNG.RES
--   $EDITOR CYBSTRNG.d/textures.txt
--   $EDITOR CYBSTRNG.d/papers.txt
--   ss1trans CYBSTRNG.d
-- to get a TRNSTRNG.RES file containing the results of the patches in
-- textures.txt and papers.txt.

function main(...)
  require "util"
  local res = require "ss1.res"

  if select('#', ...) ~= 1 then
    print('Run me by dragging a ___STRNG.RES file or ___STRNG.d directory onto ss1trans.exe')
    return 1
  end

  local _RF,_DIR
  local loader_environment = {
    load = function(path)
      printf('Loading resource file %s\n', path)
      _RF = assert(res.load(path))
    end;
    save = function(path)
      printf('Saving resource file %s\n', path)
      _RF:save(path)
    end;
    patch = function(path)
      printf('Applying patch %s\n', path)
      local fn = assert(loadfile(_DIR .. '/' .. path))
      local env = {}
      for k,v in pairs(require 'repack') do
        env[k] = function(data) return v(_RF, data) end
      end
      setfenv(fn, env)
      fn()
    end;
  }

  local input = ...
  if input:match('%.[Rr][Ee][Ss]$') then
    printf('Loading resource file %s\n', input)
    local rf = assert(res.load(input))

    local dir = input:gsub('%.[Rr][Ee][Ss]$', '.d')
    printf('Creating output directory %s\n', dir)
    os.execute('mkdir "%s"' % dir) -- HACK HACK HACK

    local fd = assert(io.open(dir .. '/trnstrng.txt', 'w'))

    fd:printf('-- edit this file to control the patch process:\n')
    fd:printf('-- which file is used as a basis (load)\n')
    fd:printf('-- which patches are loaded (patch)\n')
    fd:printf('-- and what name to save the output under (save)\n\n')
    fd:printf('load %q\n', input)

    for _,file in ipairs { 'textures', 'papers', 'logs', 'objects' } do
      printf('Extracting %s\n', file)
      io.writefile(dir .. '/' .. file .. '.txt', require(file)(rf))
      fd:printf("patch '%s.txt'\n", file)
    end

    printf('Finishing trnstrng.txt\n')
    fd:printf("save 'TRNSTRNG.RES'\n")
    fd:close()
  elseif input:match('%.d$') then
    printf('Reading %s/trnstrng.txt and generating new res file\n', input)
    _DIR = input
    fn = assert(loadfile(input .. '/trnstrng.txt'))
    setfenv(fn, loader_environment)
    fn()
  else
    print('Run me by dragging a ___STRNG.RES file or ___STRNG.d directory onto ss1trans.exe')
  end
end

package.path = "?.lua;deps/?.lua;deps/?/init.lua;" .. package.path

if love then
  -- love2d compatibility
  function love.load(argv)
    love.filesystem.setRequirePath(package.path)
    print('argv:', unpack(argv))
    print('pwd:', love.filesystem.getWorkingDirectory())
    if argv[1] and argv[1]:match('%.love$') then
      -- we were invoked as `love ss1trans.love CYBSTRNG.RES` or similar
      -- this means argv[1] is the name of the love archive, not the name of the res file
      table.remove(argv, 1)
    end
    local success,err = xpcall(main, debug.traceback, unpack(argv))
    if success then
      print('Done! Press enter...')
      io.read()
      os.exit(0)
    else
      print(err)
      print('An error occurred. Please report this as a bug.')
      print('Press enter...')
      io.read()
      os.exit(1)
    end
  end
else
  return main(...)
end
