local LOG_LEVEL = 2 -- WARNING
local OUT = io.stdout
local flush

if flags then
  flags.register "log-level" {
    type = flags.string;
    help = "Maximum level to log at (error, warning, info, debug, or trace).";
    default = os.getenv("LOG_LEVEL") or "warning";
    set = function(k, level) return log.setlevel(level) end;
  }
  flags.register "log-to" {
    type = flags.string;
    help = "File to log to. Defaults to stdout.";
    set = function(k, file) return log.setfile(assert(io.open(file, 'a'))) end;
  }
  flags.register "log-flush" {
    help = "Immediately flush all log lines to disk; useful with tail -f.";
    default = false;
    set = function(k, f) flush = f end;
  }
end

log = {}

local log_levels = { "error", "warning", "info", "debug", "trace" }

function log.setlevel(log_level)
  if tonumber(log_level) then
    LOG_LEVEL = tonumber(log_level) return
  end
  for i,name in ipairs(log_levels) do
    if name == log_level then
      LOG_LEVEL = i return
    end
  end
  log.warning("log.setlevel called with invalid log-level: %s", tostring(log_level))
end

function log.setfile(fd)
  OUT = fd
end

-- Find the innermost (lua) call site. C frames will be elided. If there are no
-- Lua frames in the stack, returns '!C code'.
local function caller(depth)
  local frame = debug.getinfo(depth)
  if not frame then
    return 'C code'
  elseif frame.currentline == -1 then
    return caller(depth+2) -- +2 because we're about to recurse, adding a stack frame
  end

  local source = frame.source
  if source:sub(1,1) == '@' then -- filename
    source = source:sub(2)
  elseif source:sub(1,1) == '=' then -- source code
    source = '(string "' .. source:sub(2,11) .. '...")'
  end

  if frame.currentline > 0 then
    return source .. ':' .. frame.currentline
  else
    return source
  end
end

local function logger(level, name, depth)
  return function(format, ...)
    if level > LOG_LEVEL then return end
    local prefix = ("%s [%s]"):format(name, caller(depth))
    local suffix = format:format(...)
    log.hook(prefix, suffix)
    OUT:write(prefix .. ' ' .. suffix .. '\n')
    if flush then
      OUT:flush()
    end
  end
end

for i,level in ipairs(log_levels) do
  log[level] = logger(i, level:upper():sub(1,1), 3)
end

local _fatal = logger(0, 'F', 4)
function log.fatal(...)
  _fatal(...)
  error(string.format(...), 3)
end

function log.hook(prefix, message) end

log.setlevel(os.getenv("LOG_LEVEL") or "warning")
