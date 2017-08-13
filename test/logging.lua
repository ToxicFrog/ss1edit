require 'logging'
require 'memfile'

-- 5.3 compatibility
local unpack = unpack or table.unpack

TestLogging = {
  LOGFILE_CONTENTS = [[
E [./test/logging.lua:23] error (1) message
W [./test/logging.lua:23] warning (2) message
I [./test/logging.lua:23] info (3) message
D [./test/logging.lua:23] debug (4) message
T [./test/logging.lua:23] trace (5) message
]]
}

function TestLogging:testAllLogFormats()
  local logfile = io.memfile()
  log.setfile(logfile)
  log.setlevel('trace')

  for n,level in pairs { "error", "warning", "info", "debug", "trace" } do
    log[level]('%s (%d) message', level, n)
  end

  lu.assertEquals(logfile:str(), self.LOGFILE_CONTENTS)
  lu.assertErrorMsgContains(
      'fatal (0) message',
      log.fatal, '%s (%d) message', 'fatal', 0)

end

function TestLogging:testLogLevel()
end
