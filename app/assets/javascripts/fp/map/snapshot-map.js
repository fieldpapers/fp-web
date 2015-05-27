(function(exports){
  "use strict";

  var FP = exports.FP || (exports.FP = {});
  var Map = FP.map || (FP.map = {});

  Map.snapshot = function(selector, url) {
    var map = L.map(selector, FP.map.options);

    $.getJSON(url, function(data) {
      // provide a default location in the hash, not the L.map (since that will
      // load before L.Hash takes control)
      if (!window.location.hash) {
        if (data.center) {
          window.location.hash = "#" + data.center.reverse().join("/");
        } else {
          window.location.hash = "#13/37.8/-122.4";
        }
      }

      new L.Hash(map);

      var options = {
        minZoom: data.minzoom || 0,
        maxZoom: data.maxzoom || 20
      };

      var provider = data.tiles.pop();

      var mediaQuery = "(-webkit-min-device-pixel-ratio: 1.5),\
                        (min--moz-device-pixel-ratio: 1.5),\
                        (-o-min-device-pixel-ratio: 3/2),\
                        (min-resolution: 1.5dppx)";

      if (window.devicePixelRatio > 1 ||
          (window.matchMedia && window.matchMedia(mediaQuery).matches)) {
        // replace the last "." with "@2x."
        provider = provider.replace(/\.(?!.*\.)/, "@2x.")
      }

      L.tileLayer(provider, options).addTo(map);
    });
  };


})(this);
