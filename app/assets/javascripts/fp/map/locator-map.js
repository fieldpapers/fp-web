(function(exports){
  "use strict";

  var FP = exports.FP || (exports.FP = {});
  var Map = FP.map || (FP.map = {});

  // TODO: write something helpful
  function deriveCenter(settings) {
    if (settings.latlng && settings.latlng instanceof Array && settings.latlng.length === 2) return settings.latlng;

    // bbox = [west, south, east, north]
    if (settings.bbox && settings.bbox instanceof Array && settings.bbox.length === 4) {
      var sw = L.latLng(settings.bbox[1], settings.bbox[0]),
          ne = L.latLng(settings.bbox[3], settings.bbox[2]),
          bds = L.latLngBounds(sw, ne);
      if (bds.isValid()) return bds.getCenter();
    }

    return [0,0];
  }
  var locatorMapOptions = {
    dragging: false,
    touchZoom: false,
    scrollWheelZoom: false,
    doubleClickZoom: false,
    boxZoom: false,
    tap: false,
    keyboard: false,
    zoomControl: false,
    attributionControl: false
  };

  Map.locator = function(selector, settings) {
    var __ = {};
    var mapOptions = L.Util.extend({}, locatorMapOptions, FP.map.options);
    var center = deriveCenter(settings);
    var zoom = settings.zoom || 8;

    var map = L.map(selector, mapOptions).setView(center, zoom);

    L.tileLayer(settings.provider.toLowerCase(), {
      attribution: '',
      maxZoom: 18
    }).addTo(map);

    // show a marker at center
    if (settings.showMarker) {
      var marker = L.circleMarker(center,{
        stroke: true,
        color: 'black',
        weight: 2,
        opacity: 1.0,
        fill: true,
        fillColor: 'yellow',
        fillOpacity: 1.0,
        clickable: false,
        className: 'fp-locatormap-marker',
        radius: 4
      }).addTo(map);
    }

    return __;
  };


})(this);