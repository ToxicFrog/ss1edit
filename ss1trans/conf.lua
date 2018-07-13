-- love2d configuration file
-- this is used for the standalone build to embed it in a love2d executable.

function love.conf(t)
  t.identity = nil
  t.version = "11.0"
  t.console = true
  t.modules = {}
end
