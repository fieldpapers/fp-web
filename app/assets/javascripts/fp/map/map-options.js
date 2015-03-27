(function(exports){
  "use strict";

  var FP = exports.FP || (exports.FP = {});
  var map = FP.map || (FP.map = {});


  map.options = {
    scrollWheelZoom: false,
    attributionControl: false
  };

  var utils = map.utils = {};

  // Break apart a provider string from
  // an atlas that may contain multiple templates
  utils.parseProvider = function(str) {
    var re = /https?:\/\/.+?\.png|https?:\/\/.+?\.jpg/ig;
    var matches = str.match(re);
    return matches;
  };


})(this);