(function(exports){
  "use strict";

  var FP = exports.FP || (exports.FP = {});
  var Map = FP.map || (FP.map = {});

  // TODO: write something helpful
  function deriveBbox(settings) {

    // bbox = [west, south, east, north]
    if (settings.bbox && settings.bbox instanceof Array && settings.bbox.length === 4) {
      var sw = L.latLng(settings.bbox[1], settings.bbox[0]),
          ne = L.latLng(settings.bbox[3], settings.bbox[2]),
          bds = L.latLngBounds(sw, ne);

      if (bds.isValid()) return bds;
    }

    return null;
  }

  function getMinMaxZooms(settings) {
    var rsp = [0,18];
    if (settings.providerSettings && settings.providerSettings.length){
      if (settings.providerSettings[0].minzoom) rsp[0] = +settings.providerSettings[0].minzoom;
      if (settings.providerSettings[0].maxzoom) rsp[1] = +settings.providerSettings[0].maxzoom;
    }
    return rsp;
  }

  function getAttribution(settings) {
    var rsp = '';
    if (settings.providerSettings && settings.providerSettings.length){
      if (settings.providerSettings[0].options && settings.providerSettings[0].options.attribution) rsp = settings.providerSettings[0].options.attribution;
    }
    return '';
  }

  var locatorMapOptions = {
    attributionControl: false
  };

  Map.atlas = function(selector, settings) {

    // assign pageView flag to global namespace
    FP.isAtlasPageView = settings.isPageView || false;

    var __ = {};
    var mapOptions = L.Util.extend({}, locatorMapOptions, FP.map.options);
    var bbox = deriveBbox(settings);
    var zoom = settings.zoom || 8;
    var zooms = getMinMaxZooms(settings);

    mapOptions.minZoom = zooms[0];
    mapOptions.maxZoom = zooms[1];

    var map = L.map(selector, mapOptions);//.setView(center, zoom);
    if (bbox) map.fitBounds(bbox);

    /* TODO: do we want to show overlays?
    var providers = FP.map.utils.parseProvider(settings.provider);
    providers.forEach(function(provider){
      L.tileLayer(provider.toLowerCase(), {
        attribution: '',
        maxZoom: 18
      }).addTo(map);
    });
    */

    L.tileLayer(settings.provider.toLowerCase(), {
      attribution: getAttribution(settings),
      minZoom: zooms[0],
      maxZoom: zooms[1]
    }).addTo(map);

    var layout = L.pageLayout({
      bbox: bbox,
      pages: settings.pages
    }).addTo(map);

    return __;
  };


})(this);


L.PageLayout = L.Class.extend({
    includes: L.Mixin.Events,

    options: {
        width: 200,
        height: 300,
        minHeight: 80,
        paddingToEdge: 30,
        keepAspectRatio: true,
    },

    offset: new L.Point(0,0),
    dimensions: {},
    rowNames: "abcdefghijklmnopqrstuvwxyz".toUpperCase().split(''),
    pageElements: [],

    refs: {
      paper_orientations: {"landscape": 1.50, "portrait": .75},
      page_aspect_ratio:  null,
      page_dimensions: {
        width: 0,
        height: 0
      },
      grid: [],
      rows: 1,
      cols: 1
    },

    initialize: function(options) {
      L.Util.setOptions(this, options);
      this._deriveColRows();
      this._limitChangeFire = L.Util.limitExecByInterval( function(){this.fire("change");}, 500, this);
    },

    addTo: function(map) {
        this.map = map;
        this._createElements();
        this._render();
        return this;
    },

    remove: function() {
        this.map.off("move", this._onMapChange);
        this.map.off("moveend", this._onMapChange);
        this.map.off("zoomend", this._onMapChange);
        this.map.off("resize", this._onMapResize);

        this._container.parentNode.removeChild(this._container);
    },

    _createElements: function() {
        if (!!this._container)
            return;

        this._setDimensions();
        this._container =   L.DomUtil.create("div", "leaflet-pagelayout-container", this.map._controlContainer);

        this._container.style.top = this.dimensions.nw.y + 'px';
        this._container.style.left = this.dimensions.nw.x + 'px';
        this._container.style.width = this.dimensions.width + 'px';
        this._container.style.height = this.dimensions.height + 'px';

        this._makePages();

        this.map.on("move",     this._onMapChange, this);
        this.map.on("moveend",  this._onMapChange, this);
        this.map.on("zoomend",  this._onMapChange, this);
        this.map.on("resize",   this._onMapResize, this);

        this.fire("change");
    },

    _limitChangeFire: function(){},

    _onMapResize: function() {
        this._render();
    },

    _onMapChange: function() {
        this._render();
        this.fire("change");
    },

    _render: function() {
      this._setDimensions();
      this._updatePages();
    },

    _updatePages: function() {
      var xy = this._getPos();
      this._container.style.top = xy.y + 'px';
      this._container.style.left = xy.x + 'px';
      this._container.style.width = this.dimensions.width + 'px';
      this._container.style.height = this.dimensions.height + 'px';
    },

    _getPos: function() {
      return this.map.latLngToContainerPoint(this.options.bbox.getNorthWest());
    },

    _setDimensions: function() {
      var bounds = this.options.bbox;
      this.dimensions.nw = this.map.latLngToContainerPoint(bounds.getNorthWest());
      this.dimensions.ne = this.map.latLngToContainerPoint(bounds.getNorthEast());
      this.dimensions.sw = this.map.latLngToContainerPoint(bounds.getSouthWest());
      this.dimensions.se = this.map.latLngToContainerPoint(bounds.getSouthEast());

      this.dimensions.width = this.dimensions.ne.x - this.dimensions.nw.x;
      this.dimensions.height = this.dimensions.se.y - this.dimensions.ne.y;

      this.dimensions.cellWidth = this.dimensions.width / this.refs.cols;
      this.dimensions.cellHeight = this.dimensions.height / this.refs.rows;
    },

    _deriveColRows: function () {
      var cols = [],
          rows = [],
          self = this;

      this.refs.grid = [];

      // sort pages by page number
      // filter out the "i" page
      this.options.pages = this.options.pages.sort(function(a,b){
        if(a.page_number < b.page_number) return -1;
        if(a.page_number > b.page_number) return 1;
        return 0;
      }).filter(function(page){
        return page.page_number !== 'i';
      });


      var rowIdx = -1;
      var colIdx = 0;

      this.options.pages.forEach(function(page){
        var pageNum = page.page_number;
        var parts = page.page_number.split('');

        if (rows.indexOf(parts[0]) < 0) {
          rowIdx++;
          rows.push(parts[0]);
          self.refs.grid[rowIdx] = [];
          colIdx = 0;
        }

        if (cols.indexOf(parts[1]) < 0) cols.push(parts[1]);

        self.refs.grid[rowIdx][colIdx] = page;

        colIdx++;
      });

      this.refs.cols = cols.length;
      this.refs.rows = rows.length;
    },

    _makePages: function() {
      var cols = this.refs.cols,
          rows = this.refs.rows;

      var w = 100 / cols,
          h = 100 / rows;

      for (var i = 0;i < cols;i++) {
        for (var r = 0;r < rows;r++) {
          var elm = L.DomUtil.create("div", "page", this._container);

          elm.style.width = w + "%";
          elm.style.height = h + "%";
          elm.style.left = (w * i) + "%";
          elm.style.top = (h * r) + "%";

          // adjust borders
          if (r === 0) {
            L.DomUtil.addClass(elm, 'outer-top');
          } else {
            L.DomUtil.addClass(elm, 'no-top');
          }

          if(r == rows-1) {
            L.DomUtil.addClass(elm, 'outer-bottom');
          }

          if (i === 0) {
            L.DomUtil.addClass(elm, 'outer-left');
          } else {
            L.DomUtil.addClass(elm, 'no-left');
          }
          if (i == cols-1) {
            L.DomUtil.addClass(elm, 'outer-right');
          }

          var label;
          var labelText = this.refs.grid[r][i].page_number || this.rowNames[r] + (i+1);
          var path = (document.location.pathname.slice(-1) === '/') ?
                      document.location.pathname.slice(0,-1) :
                      document.location.pathname;

          if (!FP.isAtlasPageView) {
            var link = L.DomUtil.create("a", "page-link", elm);
            label = L.DomUtil.create("div", "page-label", link);
            link.href = path + '/' + labelText;
          } else {
            label = L.DomUtil.create("div", "page-label", elm);
          }

          $(label).text(labelText);

          this.pageElements.push(elm);
        }
      }
    }
});

L.pageLayout = function(options) {
    return new L.PageLayout(options);
};