var search_results = []
var maps = []
var map

if (window.location.hash != "") {
  var hash = window.location.hash.substr(1).split(",")
  var first = parseInt(hash[0])
  DEFAULT = isNaN(first) ? DEFAULT : first
  for (var i=0; i < hash.length; ++i) {
    if (hash[i] == '*') {
      for (k in levels) maps[k] = true
      break
    }
    maps[hash[i]] = levels[hash[i]]
  }
} else {
  for (k in levels) {
    maps[k] = true
  }
}

/* Load the map data for the selected levels. */
for (var i=0; i < maps.length; ++i) {
  if (!maps[i]) { continue }
  var script = document.createElement("script")
  script.type = "text/javascript"
  script.src = "./" + i + ".js"
  document.getElementsByTagName("head")[0].appendChild(script)
}

// Wait for all the other scripts and DOM to load, then initialize the UI
// and load the default map.
window.addEventListener('load', function() {
  // Hide the level select entries for levels we didn't load.
  var options = document.getElementById("levelselect").getElementsByTagName("option")
  for (var i=options.length-1; i >= 0; --i) {
    if (!maps[options[i].value]) {
      options[i].parentNode.removeChild(options[i])
    }
  }

  clearChildren(document.getElementById('map'))
  map = maps[DEFAULT]
  convertInfo()
  initMap()
  updateLayers()
  document.getElementById("levelselect").value = map.index
  document.title = map.title + " - System Shock Map"
}, false)

// Turn objects in the form we get them from the map view generator, as lists
// of [key,value] pairs, into normal JS objects with a _props property that
// lists the properties in their original order for display.
function propListToObject(props) {
  var obj = { _props: [] }
  for (var p=0; p < props.length; ++p) {
    obj._props.push(props[p][0])
    obj[props[p][0]] = props[p][1]
  }
  return obj
}

function convertInfo() {
  for (var m in maps) {
    if (!maps[m]) continue;
    var objs = maps[m].object_info
    for (var o in objs) {
      objs[o] = propListToObject(objs[o])
    }
    var tiles = maps[m].tile_info
    for (var t in tiles) {
      tiles[t] = propListToObject(tiles[t])
    }
  }
}
