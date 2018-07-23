(function(exports){
  "use strict";

  var FP = exports.FP || (exports.FP = {});
  var map = FP.map || (FP.map = {});

  // make a map showing bounding boxes of atlases as
  // squares
  map.boundingBoxes = function( selector, settings ) {
    var __ = {},
      data = [],
      markers = [];

    var map = L.map(selector, FP.map.options).setView([0,0], 5);

    // TODO: factor FP.map.atlas.getAttribution into mixin or reusable util
    L.tileLayer(FP.map.utils.conformTemplate(settings.provider), {
      attribution: settings.providerSettings[0].options.attribution,
      maxZoom: 18
    }).addTo(map);

    function resizeToMarkers() {
      var bds;
      markers.forEach(function(marker){

        if (!bds) {
          bds = marker.getBounds();
        } else {
          bds.extend(marker.getBounds());
        }

      });

      if (bds.isValid()) map.fitBounds(bds);
    }

    function clearMarkers() {
      markers.forEach(function(marker){
        map.removeLayer(marker);
      });

      markers.length = 0;
    }

    function refresh() {
      clearMarkers();

      data.forEach(function(item){
        var m = L.polygon([
            [item.north, item.west],
            [item.north, item.east],
            [item.south, item.east],
            [item.south, item.west]
          ],
          {
            className: 'atlas-boundingbox'
          }).addTo(map);

        markers.push(m);
      });

      resizeToMarkers();
    }

    __.data = function(_) {
      if (!_) return data;
      data = _;
      __.update();
      return __;
    };

    __.update = function(_) {
      refresh();
    };

    __.onresize = function(_) {
      __.update();
    };

    return __;
  };



})(this);