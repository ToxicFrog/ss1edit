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

  for (var i=0; i < info.length; ++i) {
    var tr = buf.appendChild(document.createElement("tr"));
    var th = tr.appendChild(document.createElement("th"));
    th.appendChild(document.createTextNode(info[i][0]));
    var td = tr.appendChild(document.createElement("td"));
    if (info[i][1] instanceof Array) {
      for (var j=0; j < info[i][1].length; ++j) {
        td.appendChild(document.createTextNode(info[i][1][j]))
        td.appendChild(document.createElement("br"))
      }
    } else {
      td.appendChild(document.createTextNode(info[i][1]));
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
  if (maps[i]) {
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

  map.mapLayer = new Kinetic.Layer({ x: 0, width: map.width * SCALE }); // level geometry
  map.hitLayer = new Kinetic.Layer({ x: 0, width: map.width * SCALE, opacity: 0 });  // mouse event trap

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

  map.stage.add(map.mapLayer);
  map.stage.add(map.hitLayer);
  for (var i = 0; i < 15; ++i) {
    map.stage.add(map.objLayers[i])
  }
}

function destroyMap() {
  map.stage.destroy()
  delete map.mapLayer
  delete map.hitLayer
  delete map.objLayers
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
  if (search.length <= 1) return;
  var results = []
  for (var level=0; level < maps.length; ++level) {
    if (maps[level] && (all || level == map.index)) {
      var objs = maps[level].object_info
      for (obj in objs) {
        if (!nameMatches(objs[obj], search)) continue;
        results.push([level, objs[obj]])
      }
    }
  }
  results.sort(function(x,y) {
    var tx = objProp(x[1], 'type')
    var ty = objProp(y[1], 'type')
    if (tx < ty) return -1;
    if (tx > ty) return 1;
    return x[0] - y[0]
  })
  displaySearchResults(results)
}

function clearSearch() {
  document.getElementById("search-text").value = ''
  displaySearchResults([])
}

function displaySearchResults(results) {
  var table = document.getElementById("search-results")
  while (table.rows.length > 1) {
    table.deleteRow(1)
  }

  for (var i=0; i < results.length; ++i) {
    if (i > 0 && objProp(results[i-1][1], 'type') != objProp(results[i][1], 'type')) {
      appendSearchResult("", [["type", "<hr>"]])
    }
    appendSearchResult(results[i][0], results[i][1])
  }
}

function objProp(obj, key) {
  for (var i=0; i < obj.length; ++i) {
    if (obj[i][0] == key) return obj[i][1];
  }
  return null
}

function nameMatches(obj, name) {
  return objProp(obj, 'type').toLowerCase().search(name) != -1
}

function appendSearchResult(level, obj) {
  var results = document.getElementById("search-results")
  results.style.display = ''
  var row = results.insertRow(-1)
  row.insertCell(-1).innerHTML = level
  row.insertCell(-1).innerHTML = objProp(obj, 'type')
}

