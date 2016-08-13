require 'misc'

-- 5.3 compatibility
local unpack = unpack or table.unpack

TestMisc = {}

function TestMisc:test_assertf()
  lu.assertErrorMsgContains(
    "0 = 1", assertf, false, "%d = %d", 0, 1)
  lu.assertTrue(assertf(true, "%d = %d", 0, 1))
end

function TestMisc:test_error()
  lu.assertErrorMsgContains(
    "0 = 1", error, "%d = %d", 0, 1)
  lu.assertErrorMsgContains(
    "%d = %d", error, "%d = %d")
end

function TestMisc:test_f()
  local fn = f 'x,y => x*y'
  lu.assertEquals(fn(2,3), 6)
  lu.assertErrorMsgMatches(
    ".*attempt to perform arithmetic.*local 'y'.*",
    fn, 2)
end

function TestMisc:test_getmetafield()
  lu.assertEquals(getmetafield("", "__index").gsub, string.gsub)
  lu.assertEquals(getmetafield("", ""), nil)
  lu.assertEquals(getmetafield({}, "__index"), nil)
end

function TestMisc:test_partial()
  local fn = partial(string.gsub, "abcdef", "[bcd]")
  lu.assertEquals(fn('-'), 'a---ef')
  lu.assertEquals(fn('.'), 'a...ef')
end

function TestMisc:test_pairs_metamethods()
  local data = {a=1, b=2, c=3, "A", "B", "C"}

  local t = setmetatable({}, {
    __pairs = function(t) return pairs(data) end;
    __ipairs = function(t) return ipairs(data) end;
  })

  local pairs_result,ipairs_result = {},{}
  for k,v in pairs(t) do pairs_result[k] = v end
  for k,v in ipairs(t) do ipairs_result[k] = v end

  lu.assertEquals(data, pairs_result)
  lu.assertEquals({unpack(data)}, ipairs_result)
end

function TestMisc:test_srequire()
  lu.assertEquals(srequire 'debug', debug)
  local r,e = srequire('no.such.module')
  lu.assertNil(r)
  lu.assertStrContains(e, "module 'no.such.module' not found")
end

function TestMisc:test_toboolean()
  lu.assertTrue(toboolean({}))
  lu.assertTrue(toboolean(0))
  lu.assertTrue(toboolean(0/0))
  lu.assertTrue(toboolean("false"))
  lu.assertTrue(toboolean(true))
  lu.assertFalse(toboolean(false))
  lu.assertFalse(toboolean(nil))
end

function TestMisc:test_type()
  local t = setmetatable({}, {__type = function() return "test" end})
  lu.assertEquals(type(t), "test")
  lu.assertEquals(rawtype(t), "table")
end
