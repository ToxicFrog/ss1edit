maps[${INDEX}] = {
  title: "${LEVEL_TITLE}",
  index: ${INDEX},
  width: ${WIDTH},
  height: ${HEIGHT},
  tile_info: {
    ${TILE_INFO}
  },
  object_info: {
    ${OBJECT_INFO}
  },
  drawTerrain: function() {
    ${WALLS}
  }
}

console.log("Level ${INDEX} loaded successfully.")
