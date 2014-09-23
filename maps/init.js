var maps = []
var map

if (window.location.hash != "") {
  var hash = window.location.hash.substr(1).split(",")
  DEFAULT = parseInt(hash[0])
  for (var i=0; i < hash.length; ++i) {
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
  initMap()
  document.getElementById("levelselect").value = map.index
  showMap(map.index)
}, false)
