function io.readfile(name)
  local fd = assert(io.open(name, "rb"))
  local buf = fd:read("*a")
  fd:close()
  return buf
end

function io.writefile(name, data)
  local fd = assert(io.open(name, "wb"))
  fd:write(data)
  fd:close()
end
