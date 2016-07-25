lu = require('test.luaunit')

require 'test.misc'
require 'test.flags'

runner = lu.LuaUnit.new()
os.exit( runner:runSuite() )
