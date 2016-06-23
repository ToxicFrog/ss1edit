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
    set = function(k, file) OUT = assert(io.open(file, 'w')) end;
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

local function caller()
  local frame = debug.getinfo(3)
  return frame.source .. ":" .. frame.currentline
end

local function logger(level, name)
  return function(format, ...)
    if level > LOG_LEVEL then return end
    local prefix = ("%s %s]"):format(name, caller())
    local suffix = format:format(...)
    log.hook(prefix, suffix)
    OUT:write(prefix .. ' ' .. suffix .. '\n')
    if flush then
      OUT:flush()
    end
  end
end

for i,level in ipairs(log_levels) do
  log[level] = logger(i, level:upper():sub(1,1))
end

local _fatal = logger(0, 'F')
function log.fatal(...)
  _fatal(...)
  error(string.format(...))
end

function log.hook(prefix, message) end

log.setlevel(os.getenv("LOG_LEVEL") or "warning")
