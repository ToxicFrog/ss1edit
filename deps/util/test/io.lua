-- Clear this so that we get the util io.lua rather than merely returning the
-- cached io from the lua stdlib
package.loaded.io = nil; require 'io'

TestIO = {}

function TestIO:setUp()
  if not self.path then
    self.path = assert(os.tmpname())
    assert(io.open(self.path, 'w')):close()
  end
  io.output(io.stdout)
  io.input(io.stdin)
end

function TestIO:test_readwritefile()
  lu.assertTrue(io.writefile(self.path, 'test file content'))
  lu.assertEquals(io.readfile(self.path), 'test file content')
end

function TestIO:test_exists()
  lu.assertTrue(io.exists(self.path))
  lu.assertFalse(io.exists('/no/such/file'))
end

function TestIO:test_printf()
  local fd = io.open(self.path, 'w+')
  io.output(fd)
  lu.assertTrue(printf('%d %s', 6, 'bar'))
  fd:seek('set', 0)
  lu.assertEquals(fd:read('*a'), '6 bar')
  fd:close()
end

function TestIO:test_fprintf()
  local fd = io.open(self.path, 'w+')
  lu.assertTrue(fd:printf('%d %s', 3, 'foo'))
  fd:seek('set', 0)
  lu.assertEquals(fd:read('*a'), '3 foo')
  fd:close()
end

function TestIO:test_memfile()
  local mf = io.memfile("one\ntwo\nthree")
  lu.assertEquals(type(mf), "memfile")
  lu.assertEquals(tostring(mf), "memfile:0/13")
end

function TestIO:test_memfile_read()
  local mf = io.memfile("one\ntwo\nthree\n123foo\n456")
  lu.assertEquals(mf:read('a'), "one\ntwo\nthree\n123foo\n456")
  lu.assertTrue(mf:seek('set', 0))
  lu.assertEquals(mf:read('l'), "one")
  lu.assertEquals(mf:read('L'), "two\n")
  lu.assertEquals(mf:read('n'), nil)
  lu.assertEquals(mf:read('l'), "three")
  lu.assertEquals(mf:read('n'), 123)
  lu.assertEquals(mf:read('l'), 'foo')
  lu.assertEquals(mf:read('L'), '456')
end

function TestIO:test_memfile_seek()
  local mf = io.memfile("12345678")
  lu.assertEquals(mf:seek('set', 0), 0)
  lu.assertEquals(mf:seek('cur', 0), 0)
  lu.assertEquals(mf:seek('end', 0), 8)
  lu.assertEquals(mf:seek('cur', -2), 6)
  lu.assertEquals(mf:seek('cur', 4), 10)
  lu.assertEquals(mf:seek('set', -1), nil)
end

function TestIO:test_memfile_write()
  local mf = io.memfile("one two three")
  -- Overwrite first word
  lu.assertTrue(mf:write("ONE"))
  -- Append to file
  lu.assertTrue(mf:seek('end'))
  lu.assertTrue(mf:write(' four'))
  -- Write past end of file
  lu.assertTrue(mf:seek('cur', 1))
  lu.assertTrue(mf:write('five'))
  -- Verify contents
  lu.assertTrue(mf:seek('set'))
  lu.assertEquals(mf:str(), 'ONE two three four\0five')
  lu.assertEquals(mf:close(), 'ONE two three four\0five')
end

function TestIO:test_memfile_lines()
  local mf = io.memfile('1\n2\n3\n\n5\n6\n')
  local L = {}
  for line in mf:lines() do
    table.insert(L, line)
  end
  lu.assertEquals(L, {'1', '2', '3', '', '5', '6'})
end

function TestIO:test_memfile_close()
  local mf = io.memfile('foo')
  lu.assertEquals(mf:close(), 'foo')
  lu.assertErrorMsgContains(
    'Attempt to index a closed memfile',
    function() return mf:str() end)
end
