(function(exports){
  var FP = exports.FP || (exports.FP = {});
  var map = FP.map || (FP.map = {});

  // make a map showing bounding boxes of atlases as
  // squares
  map.boundingBoxes = function( selector ) {
    var __ = {},
      data = [],
      markers = [];

    var map = L.map(selector).setView([51.505, -0.09], 13);

    L.tileLayer("http://{s}.tile.stamen.com/toner/{z}/{x}/{y}.png", {
      attribution: 'Map tiles by <a href="http://stamen.com/">Stamen Design</a>, under <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a>. Data by <a href="http://openstreetmap.org/">OpenStreetMap</a>, under <a href="http://creativecommons.org/licenses/by-sa/3.0">CC BY SA</a>.',
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