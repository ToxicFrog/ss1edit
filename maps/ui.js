// General HTML manipulating/UI related functions //

function clearChildren(node) {
  while (node.firstChild) {
    node.removeChild(node.firstChild);
  }
}

var messageLocked = false
function writeMessage(node) {
  if (!messageLocked) {
    info = document.getElementById("info")
    clearChildren(info)
    info.appendChild(node)
  }
}
function lockMessage(lock) {
  messageLocked = lock
}

function infoToTable(info) {
  var buf = document.createElement("table");
  var props = info._props

  for (var p in props) {
    var tr = buf.appendChild(document.createElement("tr"));
    var th = tr.appendChild(document.createElement("th"));
    th.appendChild(document.createTextNode(props[p]));
    var td = tr.appendChild(document.createElement("td"));
    var value = info[props[p]]
    if (value instanceof Array) {
      for (var i in value) {
        td.appendChild(document.createTextNode(value[i]))
        td.appendChild(document.createElement("br"))
      }
    } else {
      td.appendChild(document.createTextNode(value));
    }
  }
  return buf;
}

function tileInfo(x, y) {
  return infoToTable(map.tile_info[x + "," + y])
}

function objectInfo(id) {
  return infoToTable(map.object_info[id]);
}

function changeLevel() {
  showMap(document.getElementById("levelselect").value)
}

function showMap(i) {
  if (maps[i] && i != map.index) {
    clearChildren(document.getElementById('map'))
    destroyMap()
    map = maps[i]
    initMap()
    document.getElementById('map').appendChild(map.stage.content)
    updateLayers()
    document.title = map.title + " - System Shock Map"
  }
}

function initMap() {
  if (map.stage)
    return;

  map.stage = new Kinetic.Stage({
    container: 'map',
    width: map.width * SCALE,
    height: map.height * SCALE
  })

  map.mapLayer = new Kinetic.FastLayer({ x: 0, y: 0, width: map.width * SCALE }); // level geometry
  map.hitLayer = new Kinetic.Layer({ x: 0, y: 0, width: map.width * SCALE, opacity: 0 });  // mouse event trap
  map.searchLayer = new Kinetic.FastLayer({ x: 0, y: 0, width: map.width * SCALE }) // search result hilighting

  map.objLayers = [] // objects, by object class
  for (var i = 0; i < 15 ; ++i) {
    map.objLayers[i] = new Kinetic.Layer({ x: 0, width: map.width * SCALE });
  }

  map.hitLayer.add(new Kinetic.Rect({x:0, y:0, width: map.width * SCALE, height: map.height * SCALE}));
  map.hitLayer.on('mousemove', function(evt) {
    var xy = map.stage.getPointerPosition();
    var x = Math.floor(xy.x/SCALE);
    var y = Math.floor(map.height - xy.y/SCALE);
    writeMessage(tileInfo(x, y))
  });
  map.hitLayer.on('mousedown', function() { lockMessage(false); })

  map.mapLayer.add(new Kinetic.Rect({
    x: 0, y: 0,
    width: map.width*SCALE, height: map.height*SCALE,
    fill: '#000000',
  }))

  map.drawTerrain()
  drawSearchResults()

  map.stage.add(map.mapLayer);
  map.stage.add(map.hitLayer);
  for (var i = 0; i < 15; ++i) {
    map.stage.add(map.objLayers[i])
  }
  map.stage.add(map.searchLayer)
}

function drawSearchResults() {
  map.searchLayer.destroyChildren()
  for (var r in search_results) {
    if (search_results[r].level != map.index) continue;
    var coords = search_results[r].obj.position.split(/[(), ]+/)
    target(map.searchLayer, coords[1], coords[2])
  }
  map.searchLayer.draw()
}

function destroyMap() {
  map.stage.destroy()
  delete map.mapLayer
  delete map.hitLayer
  delete map.objLayers
  delete map.searchLayer
  delete map.stage
}

function updateLayers() {
  var controls = document.getElementById("layercontrols").getElementsByTagName("input");
  for (var i=0; i < controls.length; ++i) {
    map.objLayers[i].setVisible(controls[i].checked);
  }
}

function showAllLayers(visible) {
  var controls = document.getElementById("layercontrols").getElementsByTagName("input");
  for (var i=0; i < controls.length; ++i) {
    controls[i].checked = visible;
  }
  updateLayers();
}

function performSearch(all) {
  var search = document.getElementById("search-text").value.toLowerCase()
  search_results = []
  if (search.length <= 1) return;
  for (var level=0; level < maps.length; ++level) {
    if (maps[level] && (all || level == map.index)) {
      var objs = maps[level].object_info
      for (obj in objs) {
        if (!objectMatches(objs[obj], search)) continue;
        search_results.push({level: level, obj: objs[obj]})
      }
    }
  }
  search_results.sort(function(x,y) {
    if (x.obj.type < y.obj.type) return -1;
    if (x.obj.type > y.obj.type) return 1;
    return x.level - y.level
  })
  displaySearchResults()
}

function clearSearch() {
  document.getElementById("search-text").value = ''
  search_results = []
  displaySearchResults(search_results)
}

function displaySearchResults() {
  var table = document.getElementById("search-results")
  while (table.rows.length > 1) {
    table.deleteRow(1)
  }

  for (var i in search_results) {
    var result = search_results[i]
    if (i > 0 && search_results[i-1].obj.type != result.obj.type) {
      appendSearchResult(16, {type: "<hr>"})
    }
    appendSearchResult(result.level, result.obj)
  }

  drawSearchResults()
}

function nameMatches(obj, name) {
  return obj.type.toLowerCase().search(name) != -1
}

function contentsMatch(obj, name) {
  if (!obj.contents) return false
  for (o in obj.contents) {
    if (obj.contents[o].toLowerCase().search(name) != -1) return true
  }
  return false
}

function objectMatches(obj, name) {
  return nameMatches(obj, name) || contentsMatch(obj, name)
}

var short_levels = [
  "R", 1, 2, 3, 4, 5, 6, 7, 8, 9,
  "CS", "&delta;", "&alpha;", "&beta;", "C1", "C2",
  ""
]
function appendSearchResult(level, obj) {
  var results = document.getElementById("search-results")
  results.style.display = ''
  var row = results.insertRow(-1)
  row.className = "search-result"
  row.onmouseenter = hilightSearchResult.bind(undefined, level, obj)
  row.onmouseleave = unhilightSearchResult.bind(undefined, obj)
  row.onclick = displayAndHilight.bind(undefined, level, obj)
  row.insertCell(-1).innerHTML = short_levels[level]
  row.insertCell(-1).innerHTML = obj.type
}

function displayAndHilight(level, obj) {
  showMap(level)
  hilightSearchResult(level, obj)
}

function hilightSearchResult(level, obj) {
  writeMessage(infoToTable(obj))
  if (level != map.index) return
  var coords = obj.position.split(/[(), ]+/)
  obj._hilight = hilight(map.searchLayer, coords[1], coords[2])
  map.searchLayer.draw()
}

function unhilightSearchResult(obj) {
  console.log("unhilight", map.index, obj)
  if (obj._hilight) {
    console.log("actually removing hilight")
    obj._hilight.destroy()
    delete obj._hilight
    map.searchLayer.draw()
  }
}
