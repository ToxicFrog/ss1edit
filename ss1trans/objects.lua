local ids = require 'ids'

local ids = require 'ids'

local OBJ_HEADER = [[
-- objects.txt: long and short names for in-game objects.
-- `name` is the object's full name.
-- `shortname` is the object's short name; for some objects this appears in
-- certain in-game messages, for others it is only used in the editor.
-- `objid` is the internal object ID (not resource ID).

]]
local OBJ_TEMPLATE = [[
-- %s
object {
  objid = %d;
  name = %q;
  shortname = %q;
}

]]

-- Given a resfile, unpacks the texture name and usage messages and returns
-- a string containing them.
return function(rf)
  local longnames = rf:read(ids.OBJ_LONG_NAMES)
  local shortnames = rf:read(ids.OBJ_SHORT_NAMES)
  local buf = { OBJ_HEADER }

  for objid = 0,#longnames do
    table.insert(buf, OBJ_TEMPLATE:format(
      longnames[objid]:gsub('\n', ' '),
      objid,
      longnames[objid],
      shortnames[objid]))
  end

  return table.concat(buf, '')
end
