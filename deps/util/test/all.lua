lu = require('test.luaunit')

require 'test.misc'
require 'test.io'
-- lfs requires mocking out lfs.
require 'test.string'
-- math
-- table
require 'test.logging'
require 'test.flags'

runner = lu.LuaUnit.new()
os.exit( runner:runSuite() )
