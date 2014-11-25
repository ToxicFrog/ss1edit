-- new global functions, either replacing existing ones or providing new
-- ones for convenience
-- replacements: pairs, ipairs, type
-- new: printf, fprintf, eprintf, sprintf, srequire, L

-- new version of type() that supports the __type metamethod
rawtype = type
function type(obj)
	local mt = getmetatable(obj)
	if mt and rawget(mt, "__type") then
		return rawget(mt, "__type")(obj)
	end
	return rawtype(obj)
end
-- update file metatable
getmetatable(io.stdout).__type = function() return "file" end

-- printf(format, ...)
function printf(...)
	return io.stdout:printf(...)
end

-- printf to standard error
function eprintf(...)
	return io.stderr:printf(...)
end

-- bind to io tables, so that file:printf(...) becomes legal
getmetatable(io.stdout).__index.printf = function(self, ...)
  return self:write(string.format(...))
end

-- "safe require", returns nil,error if require fails rather than
-- throwing an error
function srequire(...)
	local s,r = pcall(require, ...)
	if s then
		return r
	end
	return nil,r
end

-- fast one-liner lambda creation
function f(src)
	return assert(loadstring(
		"return function(" .. src:gsub(" => ", ") return ") .. " end"
	))()
end

-- bind args into function
function partial(f, ...)
	if select('#', ...) == 0 then
		return f
	end
	local arg = (...)
	return partial(function(...) return f(arg, ...) end, select(2, ...))
end

if lfs then
	local windows = package.config:sub(1,1) == "\\"

	-- We make the simplifying assumption in these functions that path separators
	-- are always forward slashes. This is true on *nix and *should* be true on
	-- windows, but you can never tell what a user will put into a config file
	-- somewhere. This function enforces this.
	function lfs.normalize(path)
		if windows then
			return (path:gsub("\\", "/"))
		else
			return path
		end
	end

	function lfs.exists(path)
		path = lfs.normalize(path)
		if windows then
			-- Windows stat() is kind of awful. If the path has a trailing slash, it
			-- will always fail. Except on drive root directories, which *require* a
			-- trailing slash. Thankfully, appending a "." will always work.
			path = path:gsub("/$", "/.")
		end

		return lfs.attributes(path, "mode") ~= nil
	end

	function lfs.dirname(oldpath)
		local path = lfs.normalize(oldpath):gsub("[^/]+/*$", "")
		if path == "" then
			return oldpath
		end
		return path
	end

	-- Recursive directory creation a la mkdir -p. Unlike lfs.mkdir, this will
	-- create missing intermediate directories, and will not fail if the
	-- destination directory already exists.
	-- It assumes that the directory separator is '/' and that the path is valid
	-- for the OS it's running on, e.g. no trailing slashes on windows -- it's up
	-- to the caller to ensure this!
	function lfs.rmkdir(path)
		if lfs.exists(path) then
			return true
		end
		if lfs.dirname(path) == path then
			-- We're being asked to create the root directory!
			return nil,"mkdir: unable to create root directory"
		end
		local r,err = lfs.rmkdir(lfs.dirname(path))
		if not r then
			return nil,err.." (creating "..path..")"
		end
		return lfs.mkdir(path)
	end
end
