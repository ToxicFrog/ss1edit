local util = require 'ss1trans.util'

local PAPER_START = 60
local PAPER_END = 70
local PAPER_HEADER = [[
-- papers.txt: strings for readable papers and notes.
-- Unlike emails and audio logs, these don't have a date, sender, portrait, etc.
-- Each line of text in this file turns into a line of text in game, but long
-- lines will be automatically wrapped to fit the display; you only need to start
-- a new line here if you want to force a linebreak to occur in game.

]]
local PAPER_TEMPLATE = [[
-- %s
paper {
  resid = %d;
%s
}

]]

-- Given a resfile, unpacks the papers from it.
return function(rf)
  local buf = { PAPER_HEADER }
  for resid=PAPER_START,PAPER_END do
    local lines = rf:read(resid)
    local text = (lines[0] .. table.concat(lines, '')):gsub('%z', '')
    local paper = util.format_lines('  %q;\n', text)
    table.insert(buf, PAPER_TEMPLATE:format(
      lines[0]:sub(1,-2):gsub('\n', ''), resid, paper))
  end
  return table.concat(buf, '')
end
