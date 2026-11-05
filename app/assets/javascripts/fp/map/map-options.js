(function(exports){
  "use strict";

  var FP = exports.FP || (exports.FP = {});
  var map = FP.map || (FP.map = {});


  map.options = {
    scrollWheelZoom: true,
    attributionControl: true
  };

  var utils = map.utils = {};

  // Break apart a provider string from
  // an atlas that may contain multiple templates
  utils.parseProvider = function(str) {
    var re = /https?:\/\/.+?\.png|https?:\/\/.+?\.jpg/ig;
    var matches = str.match(re);
    return matches;
  };

  // Whether str is an http(s) tile URL template; the same check as
  // Atlas#provider_valid on the server.
  utils.isTemplateString = function(str) {
    return /^https?:\/\/(\{[s]\})?[\/\w\.\-\?\+\*_\|~:\[\]@#!\$'\(\),=&]*\{[zxy]\}\/\{[zxy]\}\/\{[zxy]\}[\/\w\.\-\?\+\*_\|~:\[\]@#!\$'\(\),=&]*(jpg|png)([\/\w\.\-\?\+\*_\|~:\[\]@#!\$'\(\),=&]*)?$/i.test(str);
  };

  utils.conformTemplate = function(template) {
    return template.replace('{S}','{s}').replace('{X}','{x}').replace('{Y}','{y}').replace('{Z}','{z}');
  };
})(this);
