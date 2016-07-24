## Contents ##

1. Introduction
2. Modules
  Global Functions -- misc.lua
  IO -- io.lua
  LuaFilesystem -- lfs.lua
  Strings -- string.lua
  Math -- math.lua
  Tables and Lists -- table.lua
  Command Line Flag Parsing -- flags.lua
  Logging -- logging.lua
3. License


## 1. Introduction ##

This is a collection of utility functions for Lua that I use in some of my programs. You may find it useful.

It is organized into a number of modules; these modules are independent of each other, so you can load only the ones you need.

Note that this library does various bad things such as *modifying the metatables for built in types*, *overwriting builtin functions* and *unconditionally creating new globals*. There is currently no way to disable this behaviour except by not loading the modules that do these things.


## 2. Modules ##

This library is organized into a number of individual modules. None of them have any additional dependencies, although some enable additional features if certain other libraries (such as lfs) are loaded first. You can also load the entire library at once via `init.lua`.


### Global Functions -- misc.lua ###

This module creates a number of global functions that don't belong in any other module. It also overrides some existing functions.

-------

    assertf(exp, err, ...)

As `assert(exp, err:format(...))`. This isn't particularly useful for turning 'soft errors' into 'hard errors' as in `assertf(io.read(...))`, because the error returned by the call may not be format-clean; it's mainly intended for runtime checks, as in `assertf(precondition, err, ...)`. (Perhaps it should be called `check()` instead?)

-------

    error(err, ...)

As stock `error`, but if the `...` is nonempty, calls `err:format(...)` and then throws the result.

-------

    f(body)

Concise creation of simple anonymous functions. `f "x => not x"` is converted into `function(x) return not x end`. Note that this uses `loadstring` and thus the resulting function is *not* lexically scoped inside `f`'s caller; in particular, this means that it has no upvalues.

-------

    getmetafield(v, k)

As `getmetatable(v)[k]`, except that it returns `nil` rather than throwing if `v` has no metatable.

-------

    memoize(fn)

Returns a version of fn that is memoized; that is to say, return values from fn are cached, and when called again with the same arguments, the cached value is returned. Memoize is itself memoized.

-------

    partial(f, ...)

Return a function based on f with the given arguments already applied, such that `partial(f, x)(...)` is equivalent to `f(x, ...)`.

-------

    pairs(v)
    ipairs(v)

These are defined only if running under Lua 5.1, and are equivalent to the Lua 5.2 versions that respect the `__pairs` and `__ipairs` metamethods.

-------

    srequire(module)

"Safe require". Equivalent to `require`, but returns `nil,error` on failure rather than throwing.

-------

    toboolean(v)

Returns the truth-value of `v`; this is `false` for false or nil and `true` for everything else (including the empty string, the empty table, and 0).

-------

    type(v)

Identical to the builtin, except that if v has a __type metamethod, it calls that instead and returns the result. Original type is still available as `rawtype`.


### IO -- io.lua ###

This module modifies the `io` library by adding new functions, and modifies the `__index` for file objects so that `:printf` is callable on them as a method.

-------

    eprintf(fmt, ...)

Equivalent to `io.stderr:printf(fmt, ...)`.

-------

    file:printf(...)

Equivalent to `file:write(string.format(...))`.

-------

    io.readfile(path)

Reads and returns the contents of the file `path`. Raises an error on failure.

-------

    io.writefile(path, data)

Writes `data` to the file `path`. The file is created if it didn't already exist, and overwritten if it did. Raises an error on failure.

-------

    io.exists(file, [mode])

Checks if `file` can be opened with the given `mode` (default `'r'`). This is not as good as the lfs version -- in particular, if the file exists but you cannot open it in any mode due to permissions, this function can never return true -- but it doesn't require LFS to be installed.

-------

    printf(fmt, ...)

Equivalent to `io.stdout:printf(fmt, ...)`.

### LuaFilesystem -- lfs.lua ###

This module contains extension for the LuaFilesystem library, which it assumes is present in the global `lfs`. It is only loaded through `init.lua` if `lfs` is already available; if you load it directly, you are responsible for making sure `lfs` is loaded first!

It modifies the `lfs` table, and wraps the `lfs.attributes` function.

-------

    lfs.normalize(path)

On windows, returns the path with all backslashes (`\`) replaced with forward slashes (`/`). On not-windows, a no-op.

-------

    lfs.attributes(path, ...)

Equivalent to the original function, except that it runs `path` through `lfs.normalize`. On windows, it additionally appends a `.` to the path if the path ends with `/`, to work around a bug on windows where it will fail on paths with trailing slashes even if they reference a directory.

-------

    lfs.exists(path)

Returns true if the named file or directory exists, and false otherwise. A convenience function for `lfs.attributes(path, 'mode') ~= nil`.

-------

    lfs.dirname(path)

As the POSIX utility `dirname`, returns `path` with the trailing path element

-------

    lfs.rmkdir(path)

Recursive mkdir, akin to `mkdir -p`. Unlike `lfs.mkdir`, this will create any missing intermediate directories, and will succeed even if the destination directory already exists.


### Strings -- string.lua ###

This adds several functions to the `string` table, and also modifies the metatable for strings by adding a `__mod` metamethod. As with the standard string library, all of these functions are available as methods on individual strings as well.

-------

    str:tonumber()

Equivalent to `tonumber(str)`.

-------

    str % a % b % c
    str % { ... }

Equivalent to `str:format(a,b,c)` and `str:format(...)` respectively. The former is faster to type but has some edge cases related to `%%` escapes that it doesn't handle properly, so using the latter is recommended with complicated format strings.

------

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

The default for `pattern` is `%s`, i.e. whitespace; the default for `max` is infinity.

-------

    string.trim(s)

Returns a copy of s with all leading and trailing whitespace removed.

-------

    string.wrap(s, cols)

Wrap `s` to fit within `cols` columns; returns a table of individual lines. It inserts linebreaks only on whitespace or hyphens, so text containing very long words may not wrap well, resulting in lines that are still longer than `cols`.

### Math -- math.lua ###

A few convenience functions, all added to the global `math` table.

Additionally, it sets `math` as the `__index` for all numbers, so expressions like `x:floor()` will work, and sets math.huge as the value of the global `inf`.

-------

    math.bin(n)
    math.oct(n)
    math.hex(n)

As `tonumber(n, 2)`, `tonumber(n, 8)` and `tonumber(n, 16)` respectively.

-------

    math.dsin(deg)
    math.dcos(deg)
    math.dtan(deg)

Versions of `sin`, `cos` and `tan` that take arguments in degrees rather than in radians.

-------

    math.dasin(sin)
    math.dacos(cos)
    math.datan(tan)
    math.datan2(tan)

Versions of `asin`, `acos`, `atan`, and `atan2` that return values in degrees rather than in radians.

-------

    math.bound(n, min, max)

If `min` ≤ `n` ≤ `max`, returns `n`. Otherwise returns whichever of `min` or `max` is closer to `n`.

### Tables and Lists -- table.lua ###

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

    table.keys(t)

Returns a list of all the keys in `t`, in unspecified order.

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


### Command Line Flag Parsing -- flags.lua ###

This is a library to hopefully remove the pain from processing command line arguments. It supports both long and short flags, with and without arguments, and respects the convention of separating flags from positional arguments with `--`.

#### Terminology ####

A *flag* is a command line option starting with `-` or `--`. A *flag argument* (or just *argument*) is a parameter associated with a flag. A *positional argument* is a command line argument that is not a flag and not associated with any flag. For example, in the following command line:

    ls -l --all --sort=time foo bar

The flags are `l`, `all`, and `sort`; `sort` has the flag argument `time`; and the positional arguments are `foo` and `bar`.

A *flag key* is the lua identifier associated with a flag, and is derived from the first argument to `flags.register` by replacing any characters that would make an invalid identifier with `_`. For example, the flag key of `verbose` is `verbose`, and the flag key of `log-all` is `log_all`. This is done so that you can use them as field accessors, e.g:

    flags.register('log-all')
    local opts = flags.parse(...)
    if opts.log_all then ....

A *flag type* is the type of the value associated with a flag, which defaults to boolean. This library implements this with *type functions*, which are responsible for taking the flag argument parsed from the command line (which is, of necessity, a string) and either returning a value of the appropriate type or raising an error.

#### Flag Type Functions ####

The library comes with four builtin type functions, detailed below. Writing your own is as simple as defining a `function foo_type(flag, arg)` that takes the flag name and flag argument as arguments, and returns the value that should actually be set in the options.

------

    flags.boolean

The default type. Boolean flags don't require any argument; a flag registered with `flags.register('v', 'verbose')` can be set with `-v` or `--verbose`, and unset with `+v` or `--no-verbose`.

------

    flags.string

Flags with arbitrary strings as arguments.

------

    flags.number

Flags with base-10 numbers as arguments. The argument is fed to `tonumber` and an error is raised if it doesn't convert successfully.

------

    flags.list

A comma-separated list of strings.

------

    flags.listOf(type, separator)

A function for creating list types. `type` must be a type function as defined above, and `separator` a single character to split on. `flags.list` is defined as `flags.listOf(flags.string, ',')`; you can use `listOf` to define lists of other types, such as numbers.

#### Flags API ####

    flags.register(name, ...)

Register a boolean flag. The flag name is the first argument; subsequent arguments are aliases, e.g. `flags.register('verbose', 'v')`.

------

    flags.register(name, ...) {
        type = flags.boolean;
        default = nil;
        required = false;
        key = nil;
        value = nil;
        help = "";
        set = function(k, v) end;
    }

Register a flag with non-default settings. The settings listed are all optional and are detailed below; the values listed are the default values.

    type = flags.boolean

Set the type of the flag. See *flag type functions* above.

    default = nil

Set the default value of the flag. If the flag is not specified on the command line, it will have this value.

    required = false

If true, `flags.parse()` will raise an error if the given flag is not specified on the command line. You cannot set both `default` and `required` on the same flag.

    key = nil

Store the flag's value in this key rather than using the flag's canonical name.

    value = nil

If the flag is present on the command line, store this value instead of the flag's actual value. Most useful with boolean flags when you actually want them to store a special value in some other flag (by using this in conjunction with `key`). For example, you could make `--log-to-stderr` an alias for `--log-to=/dev/stderr` with `key = "log_to"; value = "/dev/stderr"`.

    help = ""

The help text for the flag, used by `flags.help()`.

    set = function(k, v) end

A function that will be called when the flag is set, passed the flag's canonical name and the value it was just set to.

------

    flags.help()

Returns a string containing help text for all currently registered flags, suitable for output to the terminal.

------

    flags.parse(...)

Parse the given arguments as the command line. Sets `flags.parsed` to the options parsed and returns it. The returned value will not be changed by future calls to `flags.parse()`, but the value of `flags.parsed` will be.

------

    flags.parsed[key]
    flags.get(key)

Returns the parsed value associated with the given flag key. If no flag parsing has happened yet, or if the flag was not specified, returns the default value.

------

    flags 'name'

Returns the parsed value associated with the given flag *name*. This is the preferred way to get "current" flag values. Note that this uses the name, not the key; given a flag `--log-level`, `flags.parsed.log_level`, `flags.get('log_level')`, and `flags 'log-level'` are all equivalent.

------

    flags.defaults[name]

Returns the default value associated with the flag `name`.

------

    flags.require(name)

As `flags.get`, but raises an error if the flag was not specified on the most recently parsed command line.


### Logging -- logging.lua ###

This module categorizes log messages into five levels: error, warning, info, debug, and trace. By default it logs to stdout and sets the log level based on the `LOG_LEVEL` environment variable, or warning otherwise.

If the `flags` module is loaded, it also registers three command line flags.

  * `--log-level` sets the log level, and overrides the `LOG_LEVEL` environment variable.
  * `--log-to` is the name of a file to write logs to. Logs will be appended to this file instead of stdout. It will not truncate the file if it already exists.
  * `--log-flush` causes it to fflush() the log after each write. This slows things down, but is useful when using `tail -f` on the log file.

------

    log.{error,warning,info,debug,trace}(format, ...)

Logs a message with the given level. The arguments will be fed to string.format and the result prefixed with the specified log level and the call site.

------

    log.fatal(format, ...)

Equivalent to `log.error`, but after logging, throws an error containing the log message.

------

    log.setlevel(level)

Sets the logging level. `level` can be either a number (lower numbers result in more logging; 1, `error`, is the lowest) or a string (one of the above mentioned log levels).

------

    log.hook(prefix, message)

If defined, this is called just before each message is logged. `prefix` is the prefix added by the logging library, containing the log level and call site; `message` is the user-provided message. This can be used to, e.g., send logs over the network, or log to both an in-game console and an external file.

## 3. License

Copyright © 2014 Ben "ToxicFrog" Kelly, Google Inc.

Distributed under the MIT license; see the file COPYING for details.


### Disclaimer

This is not an official Google product and is not supported by Google.

