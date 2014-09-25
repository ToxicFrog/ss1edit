## Contents ##

1. Introduction
2. Global functions
3. File IO
4. Math
5. String manipulation
6. Tables and lists


## 1. Introduction ##

This is a collection of utility functions for Lua that I use in some of my programs. You may find it useful.

Note that this library does various bad things such as *modifying the metadatables for built in types*, *overwriting builtin functions* and *unconditionally creating new globals*. This is not an issue if you're writing a program. If you're writing a *library* that other people are going to use, depending on this will make all of your users sad and angry. So don't do that.


## 2. Global Functions ##

    eprintf(fmt, ...)

Equivalent to `io.stderr:printf(fmt, ...)`.

-------

    f(body)

Concise creation of simple anonymous functions. `f "x => not x"` is converted into `function(x) return not x end`. Note that this uses `loadstring` and thus the resulting function is *not* lexically scoped inside `f`'s caller; in particular, this means that it has no upvalues.

-------

    memoize(fn)

Returns a version of fn that is memoized; that is to say, return values from fn are cached, and when called again with the same arguments, the cached value is returned. Memoize is itself memoized.

-------

    partial(f, ...)

Return a function based on f with the given arguments already applied, such that `partial(f, x)(...)` is equivalent to `f(x, ...)`.

-------

    printf(fmt, ...)

Equivalent to `io.stdout:printf(fmt, ...)`.

-------

    srequire(module)

Equivalent to `require`, but returns `nil,error` on failure rather than throwing.

-------

    type(v)

Identical to the builtin, except that if v has a __type metamethod, it calls that instead and returns the result. Original type is still available as `rawtype`.


## 3. File IO ##

    file:printf(...)

Equivalent to `file:write(string.format(...))`.

-------

    io.readfile(path)

Reads and returns the contents of the file `path`.

-------

    io.writefile(path, data)

Writes `data` to the file `path`. The file is created if it didn't already exist, and overwritten if it did.


## 4. Math ##

    math.dsin(deg)
    math.dcos(deg)
    math.dtan(deg)

Versions of `sin`, `cos` and `tan` that take arguments in degrees rather than in radians.

-------

    math.dasin(sin)
    math.dacos(cos)
    math.datan(tan)
    math.datan2(tan)

-------

Versions of `asin`, `acos`, `atan`, and `atan2` that return values in degrees rather than in radians.


## 5. String manipulation ##

Functions for string manipulation. As with the standard lua string functions, all of these are usable as methods on strings as well, e.g. `buf:split(",")`.

-------

    str % values

A new `%` operator for strings, borrowed from Python. `str % {...}` is equivalent to `string.format(str, ...)`. When only a single argument is needed, the enclosing table can be omitted, as in `"%02X" % 5`.

-------

    string.count(s, pattern)

Returns the number of (non-overlapping) ocurrences of pattern in string.

-------

    string.interpolate(s, data, seeall)

Searches `s` for sequences of the form `${expr}` or `${expr|format}` and recursively expands them. This is effectively the same as replacing `${expr}` with the result of `tostring(dostring(expr))`, and `${expr|format}` with the result of `string.format(format, dostring(expr))`, except that any `${...}` sequences in `expr` itself will be expanded before `expr` is evaluated, and any `${...}` sequences in the result of the expansion will themselves be expanded.

When evaluating `expr`, `data` is used as the environment; if `seeall` is true, failed lookups in `data` will fall back to the caller's environment.

    > str = "The Lua version is ${_VERSION}, and I am currently using ${collectgarbage 'count'|%d}KB of memory."
    > print(str:interpolate(_G))
    The Lua version is Lua 5.1, and I am currently using 22KB of memory.

-------

    string.join(separator, ...)

Equivalent to table.concat( {...}, separator)

-------

    string.rfind(s, pattern, init, plain)

Equivalent to string.find(), but returns the -last- occurence of the pattern in the string (ie, searches in reverse). Init can be either positive or negative and has the same meaning as in other string functions in either case.

-------

    string.split(s, pattern)

Splits s into multiple substrings by removing all occurrences of pattern, and returns these substrings. For example, the call:

    string.split("one two    three  ", "%s+")

would return "one","two","three". Note that there is no enclosing table; the results are returned directly.

-------

    string.trim(s)

Returns a copy of s with all leading and trailing whitespace removed.


## 6. Tables ##

    table.copy(table, depth)

Returns a copy of table, duplicated down to depth. Beyond depth, subtables are copied by reference rather than duplicated. Other objects are copied by reference or by value according to the = operator. Note that metatables are not copied; any resulting tables will be metatable-less.

Omitting depth is equivalent to specifying math.huge. A depth of 0 causes it to return table without copying anything.

--------

    table.dump(t)

Returns a string that, when loaded (with `loadstring()` or similar), produces a function that when called returns a copy of `t`. The serialization is not perfect; in particular:

  * any key-value pair which contains a userdata or coroutine will be cleared
  * upvalues will be nil once serialized closures are deserialized

To save and load a table, you would do something like this:

    saved = table.dump(T)
    -- maybe you save it to a file now and read it back later or something
    T = loadstring(saved)()

Note that since this outputs executable Lua code, you should use it only in circumstances where people tampering with the output is not a concern. In particular, you probably shouldn't use this for network communications, or for configuration files for setuid programs, or the like.

--------

    table.map(t, f)

Iterates `t` using `ipairs`, calling `f(v)` on each value `v` in it and storing the result in a new sequence, which it returns.

--------

    table.mapk(t, f)
    table.mapv(t, f)

As `table.map`, but iterates using `pairs` and transforms either keys (`mapk`) or values (`mapv`). The results of `mapk` are undefined if two calls to `f(k)` with different inputs return the same key.

--------

    table.mapkv(t, f)

As `table.mapv`, except that `f` is passed both the key and the value and is expected to return a new key and value.

--------

    table.merge(dst, src, collisions)

Shallowly merge `src` into `dst`. The `collisions` argument controls the behaviour in case of key collision: if `"overwrite"` the value in `src` takes precedence, if `"ignore"` the value in `dst` does, and if `"error"` an immediate error is raised. The default is `"overwrite"`.

--------

    table.print(t)

Equivalent to `print(table.tostring(t))`.

--------

    table.tostring(t)

Pretty-print `t` and all of it subtables in an indented, human-readable form. If the same table appears multiple times it will print the table pointer but not any of its contents on occurences after the first. This does not generate output in a form the interpreter will understand; if you are trying to serialize a table, use table.dump.


## License

Copyright © 2014 Ben "ToxicFrog" Kelly, Google Inc.

Distributed under the MIT license; see the file COPYING for details.


### Disclaimer

This is not an official Google product and is not supported by Google.

