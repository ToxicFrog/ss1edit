// KineticJS map rendering functions //

function line(x1, y1, x2, y2, colour) {
  map.mapLayer.add(new Kinetic.Line({
    points: [x1*SCALE, (map.height-y1)*SCALE, x2*SCALE, (map.height-y2)*SCALE],
    stroke: colour,
  }));
}

function point(layer, x, y, colour, id) {
  var obj = new Kinetic.Circle({
    x: x*SCALE,
    y: (map.height-y)*SCALE,
    radius: SCALE/4,
    stroke: colour,
    //fill: colour,
  });
  obj.on('mouseover', function() {
    writeMessage(objectInfo(id));
  });
  obj.on('mousedown', function() { lockMessage(false); writeMessage(objectInfo(id)); lockMessage(true); })
  map.objLayers[layer].add(obj);
}

function arrow(x1, y1, x2, y2, x3, y3, colour) {
  map.mapLayer.add(new Kinetic.Line({
    points: [
      x1*SCALE, (map.height-y1)*SCALE,
      x2*SCALE, (map.height-y2)*SCALE,
      x3*SCALE, (map.height-y3)*SCALE,
    ],
    stroke: colour,
  }))
}

function arrow_n(x, y, colour) {
  arrow(x+0.25,y+0.4, x+0.5,y+0.6, x+0.75,y+0.4, colour)
}
function arrow_s(x, y, colour) {
  arrow(x+0.25,y+0.6, x+0.5,y+0.4, x+0.75,y+0.6, colour)
}
function arrow_w(x, y, colour) {
  arrow(x+0.6,y+0.25, x+0.4,y+0.5, x+0.6,y+0.75, colour)
}
function arrow_e(x, y, colour) {
  arrow(x+0.4,y+0.25, x+0.6,y+0.5, x+0.4,y+0.75, colour)
}

function arrow_nw(x, y, colour) {
  arrow(x+0.3,y+0.3, x+0.3,y+0.7, x+0.7,y+0.7, colour)
}
function arrow_ne(x, y, colour) {
  arrow(x+0.3,y+0.7, x+0.7,y+0.7, x+0.7,y+0.3, colour)
}
function arrow_se(x, y, colour) {
  arrow(x+0.7,y+0.7, x+0.7,y+0.3, x+0.3,y+0.3, colour)
}
function arrow_sw(x, y, colour) {
  arrow(x+0.7,y+0.3, x+0.3,y+0.3, x+0.3,y+0.7, colour)
}
