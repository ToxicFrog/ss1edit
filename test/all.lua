lu = require('test.luaunit')

require 'test.misc'
-- io requires something like memfile to test. Can probably adapt cursor
-- from vstruct for this (and share code between util and vstruct).
-- lfs requires mocking out lfs.
-- strings
-- math
-- table
-- logging also requires memfile, I think
require 'test.flags'

runner = lu.LuaUnit.new()
os.exit( runner:runSuite() )
