(function(exports){
  "use strict";

  var FP = exports.FP || (exports.FP = {});
  var map = FP.map || (FP.map = {});


  map.options = {
    scrollWheelZoom: false,
    attributionControl: false,

    tileProviders:{
      'openstreetmap': {
        label: 'OpenStreetMap',
        template: 'http://tile.openstreetmap.org/{z}/{x}/{y}.png',
        subdomains: '',
        attribution: ''
      },
      'toner': {
        label: 'Black & White',
        template: 'http://{s}.tile.stamen.com/toner-lite/{Z}/{X}/{Y}.png',
        subdomains: '',
        attribution: ''
      },
      'satellite-labels': {
        label: 'Satellite + Labels',
        template: 'http://tile.stamen.com/boner/{Z}/{X}/{Y}.jpg',
        subdomains: '',
        attribution: ''
      },
      'satellite-only': {
        label: 'Satellite Only',
        template: 'http://tile.stamen.com/bing-lite/{Z}/{X}/{Y}.jpg',
        subdomains: '',
        attribution: ''
      },
      'humanitarian': {
        label: 'Humanitarian',
        template: 'http://a.tile.openstreetmap.fr/hot/{Z}/{X}/{Y}.png',
        subdomains: '',
        attribution: ''
      },
      'mapbox-satellite': {
        label: 'Mapbox Satellite',
        template: 'http://api.tiles.mapbox.com/v3/stamen.i808gmk6/{Z}/{X}/{Y}.png',
        subdomains: '',
        attribution: ''
      },
      'opencyclemap': {
        label: 'OpenCycleMap',
        template: 'http://tile.opencyclemap.org/cycle/{Z}/{X}/{Y}.png',
        subdomains: '',
        attribution: ''
      }
    }
  };

})(this);