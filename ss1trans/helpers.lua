local helpers = {}

function helpers.format_lines(format, text)
  local t = {}
  for line in text:gmatch('[^\n]+') do
    table.insert(t, format % line)
  end
  return table.concat(t, '')
end

return helpers
