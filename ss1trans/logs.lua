local format_lines = require('helpers').format_lines

-- local EMAIL_START = 2441
-- local EMAIL_END = 2480
-- local VMAIL_START = 2481
-- local VMAIL_END = 2486
-- local ALOG_START = 2488
-- local ALOG_END = 2621
-- local CSPACE_START = 2712
-- local CSPACE_END = 2720

local LOG_START = 2441
local LOG_END = 2720

local LOG_HEADER = [[
-- logs.txt: emails, vmails, audio logs, and hidden messages from Lansing.
-- The text is formatted the same ways as in papers.txt, except that there are
-- two versions, verbose and terse; which one is displayed depends on the
-- player's settings.
-- Title is used in the data reader menu, and is usually a name and date; sender
-- and subject are displayed at the top when you actually open the log for reading.
-- Soft word breaks can be inserted with \2; the game will insert a hyphen there
-- if it needs to break the word across multiple lines.
-- Metadata like event IDs and left/right MFD portraits are not editable here.

]]
local LOG_TEMPLATE = [[
-- %s: %s
log {
  resid = %d;
  title = %q;
  sender = %q;
  subject = %q;
  verbose = {
%s};
  terse = {
%s};
}

]]

-- Given a resfile, unpacks the logs from it.
-- log format is:
-- 1-4 metadata, title, sender, subject
-- 5-n verbose text
-- n+1 blank line
-- n+2-m terse text
-- m+1 blank line
return function(rf)
  local buf = { LOG_HEADER }
  for resid=LOG_START,LOG_END do
    if rf:stat(resid) then
      local lines = rf:read(resid)

      local i = 4 -- start of verbose text
      local verbose_text = ''
      while lines[i] ~= '' do
        verbose_text = verbose_text .. lines[i]
        i = i+1
      end
      i = i+1 -- skip blank line that separates verbose and terse text

      local terse_text = ''
      while lines[i] and lines[i] ~= '' do
        terse_text = terse_text .. lines[i]
        i = i+1
      end

      table.insert(buf, LOG_TEMPLATE:format(
        lines[1], lines[3], -- title and subject
        resid, lines[1], lines[2], lines[3],
        format_lines('    %q;\n', verbose_text),
        format_lines('    %q;\n', terse_text)))
    end
  end
  return table.concat(buf, '')
end
