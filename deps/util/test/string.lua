package.loaded.string = nil; require 'string'

TestString = {}

function TestString:test_tonumber()
  lu.assertEquals(('asdf'):tonumber(), nil)
  lu.assertEquals(('10'):tonumber(), 10)
  lu.assertEquals(('10'):tonumber(16), 16)
end

function TestString:test_format_operator()
  lu.assertEquals('%d %d %d' % 1 % 2, '1 2 %d')
  lu.assertEquals('%d %d %d' % 1 % 2 % 3, '1 2 3')
  lu.assertEquals('%d %d %d' % { 1, 2, 3 }, '1 2 3')
end

function TestString:test_count()
  lu.assertEquals(('aaaaaa'):count('aa'), 3)
  lu.assertEquals(('a=1, b=23, c=45'):count('%d'), 5)
  lu.assertEquals(('a=1, b=23, c=45'):count('%d+'), 3)
end

function TestString:test_interpolate()
  local data = { d = 1; f = 2.2; s = "foo"; r = "${d}${d}"; R = "f" }
  lu.assertEquals(('${d} ${f} ${s}'):interpolate(data), "1 2.2 foo")
  lu.assertEquals(('${r}'):interpolate(data), '11')
  lu.assertEquals(('${${R}}'):interpolate(data), '2.2')
end

function TestString:test_join()
  lu.assertEquals((':'):join(1,2,3), '1:2:3')
  lu.assertEquals((':'):join(1), '1')
end

local function assertFind(start, finish, group, _start, _finish, _group)
  lu.assertEquals(_start, start)
  lu.assertEquals(_finish, finish)
  lu.assertEquals(_group, group)
end

function TestString:test_rfind()
  local str = "a b c a b c a b c"
  assertFind(11, 12, nil, str:rfind("c "))
  assertFind(17, 17, nil, str:rfind("c"))
  assertFind(2, 4, " b", str:rfind('( b) ', 7))
  assertFind(2, 4, " b", str:rfind('( b) ', -9))
end

function TestString:test_split()
  local str = "a-b c-d e-f"
  lu.assertEquals({str:split()}, {"a-b", "c-d", "e-f"})
  lu.assertEquals({str:split('%-')}, {"a", "b c", "d e", "f"})
  lu.assertEquals({str:split('%-', 2)}, {"a", "b c", "d e-f"})
  lu.assertEquals({str:split('[a-z ]+')}, {'', '-', '-', '-', ''})
end

function TestString:test_trim()
  lu.assertEquals(('  foo\t\r\n'):trim(), 'foo')
end

function TestString:test_wrap()
  local str = "With multi-hyphen-words -- and an emdash."
  lu.assertEquals(str:wrap(1), {'With', 'multi-', 'hyphen-', 'words', '--', 'and', 'an', 'emdash.'})
  lu.assertEquals(str:wrap(23), {'With multi-hyphen-words', '-- and an emdash.'})
end

--[[

    string.interpolate(s, data, seeall)

Searches `s` for sequences of the form `${expr}` or `${expr|format}` and recursively
expands them. This is effectively the same as replacing `${expr}` with the result
of `tostring(dostring(expr))`, and `${expr|format}` with the result of
`string.format(format, dostring(expr))`, except that any `${...}` sequences
in `expr` itself will be expanded before `expr` is evaluated, and any `${...}`
sequences in the result of the expansion will themselves be expanded.

When evaluating `expr`, `data` is used as the environment; if `seeall` is true,
failed lookups in `data` will fall back to the caller's environment.

    > str = "The Lua version is ${_VERSION}, and I am currently using ${collectgarbage 'count'|%d}KB of memory."
    > print(str:interpolate(_G))
    The Lua version is Lua 5.1, and I am currently using 22KB of memory.

-------

]]
