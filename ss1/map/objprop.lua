local vstruct = require "vstruct"
local formats = require "ss1.map.objprop.formats"

-- offset from the base chunk ID of the level object table
local OFFSET = 8

local typeloader = {}

typeloader[13] = function(objects, object)
  local contents = object.contents
  object.contents = {}
  for _,obj in ipairs(contents) do
    if objects[obj].used then
      table.insert(object.contents, objects[obj])
    end
  end
end

local function load(self)
  -- to fully realize an object, we need to read its information from five places
  -- first, we need to read the universal, category-specific, and subcategory-
  -- specific information from the gamesys
  -- then we need to read the common instance variables from the master object
  -- table in the map itself
  -- finally, the type-specific instance variables from the type specific info
  -- table in the map, indexed by info_index
  -- I'm not sure what a non-terrible API for this looks like.

  local buf = self.res:get(self.id + OFFSET).data
  local objects = {}
  local details = {}

  for class=0,14 do
    if formats[class] then
      details[class] = vstruct.array(
          formats[class],
          self.res:get(self.id + 10 + class).data, 0)
    --else
    --  print("No format definition available for class %d (%d bytes)" % {
    --    class, self.res:get(self.id + 10 + class).size})
    end
  end

  local raw_objects = vstruct.array(formats.Object, buf, 0)
  for id,object in ipairs(raw_objects) do
    if object.used then
      table.insert(objects, object)
      if details[object.class] then
        table.merge(object, details[object.class][object.detail_index], "error")
        if typeloader[object.class] then
          typeloader[object.class](raw_objects, object)
        end
      end
    end
  end

  return objects
end

return {
  load = load;
}
