local LOG_LEVEL = 2 -- WARNING
local OUT = io.stdout
local set_log_level

if flags then
  flags.register "log-level" {
    type = flags.string;
    help = "Maximum level to log at (error, warning, info, debug, or trace).";
    default = os.getenv("LOG_LEVEL") or "warning";
    set = function(k, level) return set_log_level(level) end;
  }
  flags.register "log-to" {
    type = flags.string;
    help = "File to log to. Defaults to stdout.";
    set = function(k, file) OUT = assert(io.open(file, 'w')) end;
  }
end

log = {}

local log_levels = { "error", "warning", "info", "debug", "trace" }
function set_log_level(log_level)
  if tonumber(log_level) then
    LOG_LEVEL = tonumber(log_level) return
  end
  for i,name in ipairs(log_levels) do
    if name == log_level then
      LOG_LEVEL = i return
    end
  end
  log.warning("set_log_level called with invalid log-level: %s", tostring(log_level))
end

local function caller()
  local frame = debug.getinfo(3)
  return frame.source .. ":" .. frame.currentline
end

local function logger(level, name)
  return function(format, ...)
    if level > LOG_LEVEL then return end
    OUT:write(string.format("%s %s] "..format.."\n", name, caller(), ...))
  end
end

for i,level in ipairs(log_levels) do
  log[level] = logger(i, level:upper():sub(1,1))
end

set_log_level(os.getenv("LOG_LEVEL") or "warning")
