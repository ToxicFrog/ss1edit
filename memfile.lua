-- memfile -- a file-like object that is backed by a string rather than by disk

local memfile = {}
local memfile_mt = {
  __index = memfile;
  __type = function() return "memfile" end;
  __tostring = function(self)
    return ("memfile:%d/%d"):format(self._pos, #self._str)
  end;
}
local dead_memfile_mt = {
  __index = function() error("Attempt to index a closed memfile") end;
}

-- Renders the memfile unusable for any further operations. Also returns the
-- current contents of the memfile.
function memfile:close()
  local str = self:str()
  self._pos,self._str = nil,nil
  setmetatable(self, dead_memfile_mt)
  return str
end

-- Concatenate the contents of the intermediate buffer and update _str with them.
-- Note that when this is called, _pos points to the *start* of the buffer, and
-- the contents of the buffer are contiguous. Afterwards, the buffer is empty and
-- _pos points to the *end* of the buffer, i.e. the actual location of the IO pointer.
-- This means that _pos is "wrong" after writes but before flush, but since we
-- flush before calling seek(), this is invisible to the user.
function memfile:flush()
  if #self._buf == 0 then return end

  local buf = table.concat(self._buf)
  self._buf = {}

  if self._pos >= #self._str then
    -- If there's a gap between the end of _str and the start of the buffer, it
    -- gets filled in with nulls here
    self._str = self._str
      .. string.char(0):rep(self._pos - #self._str)
      .. buf
  else
    -- _pos is somewhere inside the string; we splice the buffer contents in at
    -- its location.
    self._str = self._str:sub(1, self._pos)
      .. buf
      .. self._str:sub(self._pos + #buf + 1)
  end

  self._pos = self._pos + #buf
  return true
end

-- As file:lines
function memfile:lines()
  return function()
    return self:read('l')
  end
end

-- As file:printf
function memfile:printf(...)
  return self:write(string.format(...))
end

-- Helper function for :read; given a pattern, matches that pattern against
-- the remaining memfile contents. If no match is found, returns nil. Otherwise
-- seeks ahead by the amount of data matched and returns the match.
local function readPattern(self, pattern)
  local buf,len = self._str:sub(self._pos+1):match(pattern)
  if not buf then return nil end
  self._pos = self._pos + (len and len-1 or #buf)
  return buf
end

-- The same formats as io.read are supported: *a *n *l *L <number>
function memfile:read(format)
  self:flush()

  if format == 'a' or format == '*a' then
    local buf = self._str:sub(self._pos+1)
    self:seek('end', 0)
    return buf
  end

  -- All formats other than *a return nil on EOF
  if self._pos >= #self._str then
    return nil,"eof"
  end

  if type(format) == 'number' then
    -- read N bytes
    local buf = self._str:sub(self._pos + 1, self._pos + format)
    self:seek('set', format)
    return buf
  elseif format == 'n' or format == '*n' then
    -- read a number; no bytes are read if no number is found
    return tonumber(readPattern(self, '^[0-9]+'))
  elseif format == 'l' or format == '*l' then
    -- read a line, discard newline
    return readPattern(self, '^([^\n]*)\n?()')
  elseif format == 'L' or format == '*L' then
    -- read a line, keep EOL
    return readPattern(self, '^[^\n]*\n?')
  else
    -- throw
    error("Bad argument #1 to 'memfile:read': expected alLn or number, got "..tostring(format))
  end
end

-- No-op; memfiles are always fully buffered.
function memfile:setvbuf() return true end

-- To match the behaviour of file:seek:
-- - seeking past the start is a soft error
-- - seeking past the end is allowed; if a write occurs the intervening space
--   will be filled with zero bytes
function memfile:seek(whence, offset)
  self:flush()
  whence = whence or "cur"
  offset = offset or 0

  if whence == "set"     then self._pos = offset
  elseif whence == "cur" then self._pos = self._pos + offset
  elseif whence == "end" then self._pos = #self._str + offset
  else error("bad argument #1 to 'memfile:seek': expected whence, got "..tostring(whence))
  end

  if self._pos < 0 then
    self._pos = 0
    return nil,"attempt to seek past start of file"
  end

  return self._pos
end

-- Return the current contents of the memfile as a string.
function memfile:str()
  self:flush()
  return self._str
end

-- Write string or number values to the memfile.
-- This just appends them to _buf for later concatenation when the memfile is flushed.
function memfile:write(data)
  if type(data) == 'number' then data = tostring(data) end
  if type(data) ~= 'string' then
    error("bad argument to 'memfile:write': string or number expected, got "..type(data))
  end

  table.insert(self._buf, data)
  return self
end

return function(str)
  str = str or ""
  assert(type(str) == "string", "bad argument #1 to 'memfile': string expected, got "..type(str))

  return setmetatable({ _str = str, _pos = 0, _buf = {} }, memfile_mt)
end

-- =flush
-- ?lines
-- ?read

