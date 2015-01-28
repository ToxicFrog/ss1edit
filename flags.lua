--[[
flags.register("v", "verbose")
flags.register("x", "extract") {
  key = "mode";
}
flags.register("l", "list") {
  key = "mode";
}
flags.register("r", "res") {
  type = flags.list;
}
flags.register(nil) {
  type = flags.number;
}

Default type is boolean, meaning that -f, --foo, or --foo=true are all valid;
at parse time, it will also accept +f, --no-foo, or --foo=false to disable it.

If type is anything other than boolean, it requires an argument, e.g. -f bar
or --foo=bar.

All equivalent, if foo requires an argument:
  -f bar
  -fbar
  --foo bar
  --foo=bar
]]

flags = {
  registered = {};
  defaults = {};
  name = (arg and arg[0]) or "(unknown)";
  max_length = 0;
}
flags.parsed = flags.defaults

local function asId(str)
  return (str:gsub("^(%d)", "_%1"):gsub("%W", "_"))
end

function flags.register(...)
  local aliases = {...}
  assert(#aliases > 0, "no arguments provided to flags.register")

  local flag = {}
  flag.key = asId(aliases[1])
  flag.name = (#aliases[1] == 1 and "-%s" or "--%s"):format(aliases[1])
  flag.type = flags.boolean
  flag.aliases = aliases
  for _,alias in ipairs(aliases) do
    assert(not flags.registered[alias], "Flag '"..alias.."' defined in multiple places!")
    flags.registered[alias] = flag
  end
  flags.registered[flag.key] = flag

  assert(not (flag.default ~= nil and flag.required), "Required flags must not have default values")

  flags.max_length = math.max(flags.max_length, unpack(table.map(aliases, string.len)))

  return flags.configure(flag)
end

function flags.configure(flag)
  return function(init)
    table.merge(flag, init, "overwrite")
    if flag.type ~= flags.boolean then
      flag.needs_value = true
    end
    if flag.default ~= nil then
      flags.defaults[flag.key] = flag.default
    end
  end
end

function flags.help()
  local seen = {}
  local template = string.format("%%%ds  %%s", flags.max_length + 4)
  for k,v in pairs(flags.registered) do
    if not seen[v] then
      seen[v] = true
      printf(template, "", v.help.."\r")
      for _,alias in ipairs(v.aliases) do
        printf(template, (#alias == 1 and "-" or "--")..alias, "\n")
      end
    end
  end
end

function flags.parse(...)
  local opts = setmetatable({}, { __index = flags.defaults })
  local argv = {...}
  local skip = 0
  local i = 1

  local function set(info, value)
    if rawget(opts, info.key) ~= nil and not info.repeated then
      if info.seen then
        error("option '"..info.name.."' repeated multiple times")
      else
        error("option '"..info.name.."' incompatible with earlier options")
      end
    elseif info.value ~= nil then
      opts[info.key] = info.value
    else
      opts[info.key] = info.type(info.name, value)
    end
    info.seen = true
    if info.set then
      info.set(info.key, opts[info.key])
    end
  end

  local function parseLongWithValue(flag, value)
    local invert = false
    if flag:match("^no%-") then
      invert = true
    end
    local info = flags.registered[flag]

    if not info then
      error("unrecognized option '"..flag.."'")
    elseif not info.needs_value then
      error("option '--"..flag.."' doesn't allow an argument")
    elseif invert then
      error("option '--"..flag.."' requires an argument and cannot be inverted with --no")
    end

    set(info, value)
    return 1
  end

  local function parseLong(flag, next)
    local invert = false
    if flag:match("^no%-") then
      flag = flag:sub(4)
      invert = true
    end
    local info = flags.registered[flag]

    if not info then
      error("unrecognized option '--"..flag.."'")
    elseif not info.needs_value then
      set(info, not invert)
      return 1
    end

    set(info, next)
    return 2
  end

  local function parseShort(arg, next)
    local invert = arg:sub(1,1) == "+"
    while #arg > 1 do
      arg = arg:sub(2)
      local flag = arg:sub(1,1)
      local info = flags.registered[flag]
      if not info then
        error("unrecognized option '-"..flag.."'")
      elseif not info.needs_value then
        -- Boolean flag; its mere presence or absense sets it.
        set(info, not invert)
      elseif invert then
        -- Non-boolean flag, but they tried to invert it with +
        error("option '-"..flag.."' requires an argument and cannot be inverted with +")
      else
        -- Non-boolean flag; collect value and assign.
        if #arg > 1 then
          set(info, arg:sub(2))
          return 1
        else
          set(info, next)
          return 2
        end
      end
    end
    return 1
  end

  -- clear the 'seen' bit on all flags
  for _,flag in pairs(flags.registered) do
    flag.seen = false
  end

  -- parse command line arguments
  while argv[i] do
    local arg = argv[i]

    if arg == "--" then
      -- end of option parsing
      for i=i+1,#argv do
        table.insert(opts, argv[i])
      end
      break
    elseif arg:match("^%-%-([^=]+)=(.*)") then
      -- long option with baked-in value
      i = i + parseLongWithValue(arg:match("^%-%-([^=]+)=(.*)"))
    elseif arg:match("^%-%-..+") then
      -- long option without baked-in value
      i = i + parseLong(arg:sub(3), argv[i+1])
    elseif arg:match("^[-+].+") then
      -- short options
      i = i + parseShort(arg, argv[i+1])
    else
      table.insert(opts, arg)
      i = i + 1
    end
  end

  -- check that all mandatory arguments are provided
  for _,flag in pairs(flags.registered) do
    if flag.required then flags.require(flag.key) end
  end

  flags.parsed = opts
  return opts
end

function flags.require(key)
  local info = flags.registered[key]
  if not info then
    error("attempt to require unknown option '"..key.."'")
  elseif not info.seen then
    error("required option '"..info.name.."' not specified")
  else
    return flags.parsed[key]
  end
end

function flags.get(key)
  return flags.parsed[key]
end

-- Type functions. --
function flags.boolean(flag, arg)
  -- As a special case, flags.boolean is passed either true or false
  return arg
end

function flags.string(flag, arg)
  return arg
end

function flags.number(flag, arg)
  return tonumber(arg) or error("option '"..flag.."' requires a numeric argument")
end

function flags.list(flag, arg)
  return {arg:split(",")}
end
