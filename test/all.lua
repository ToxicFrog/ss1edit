lu = require('test.luaunit')

require 'test.misc'
require 'test.io'
-- lfs requires mocking out lfs.
-- strings
-- math
-- table
-- logging also requires memfile, I think
require 'test.flags'

runner = lu.LuaUnit.new()
os.exit( runner:runSuite() )
