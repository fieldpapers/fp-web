// Based on -- https://github.com/heyman/leaflet-areaselect/
//
L.PageComposer = L.Class.extend({
    includes: L.Mixin.Events,

    options: {
        pageHeight: 400,
        minHeight: 80,
        paddingToEdge: 30,
        keepAspectRatio: true,
    },

    offset: new L.Point(0,0),
    dimensions: {
        pageHeight: 100,
    },

    refs: {
      paper_aspect_ratios: {
        letter : {landscape: 1.294, portrait: 0.773, scale: 1},
        a3: {landscape: 1.414, portrait: 0.707, scale: 1.414},
        a4: {landscape: 1.414, portrait: 0.707, scale: 1}
      },
      toolScale: 1,
      zoomScale: 1,
      startZoom: null,
      paperSize: 'letter',
      pageOrientation: 'landscape',
      page_aspect_ratio:  null,
      page_dimensions: {
        width: 0,
        height: 0
      },
      rows: 1,
      cols: 2,
      prevRows: 1,
      prevCols: 2,
      locked: false,
      was_locked: false,
      lock_change: false
    },

    initialize: function(options) {
        L.Util.setOptions(this, options);
        this.refs.page_aspect_ratio = this.refs.paper_aspect_ratios[this.refs.paperSize][this.refs.pageOrientation];
        this._width = (this.options.pageHeight * this.refs.page_aspect_ratio) * this.refs.cols;
        this._height = this.options.pageHeight * this.refs.rows;
    },

    addTo: function(map) {
        this.map = map;
        this.refs.startZoom = map.getZoom();
        this._createElements();
        this._render();
        return this;
    },

    remove: function() {
      this.map.off("moveend", this._onMapChange);

      if (this._scaleHandle) L.DomEvent.removeListener(this._scaleHandle, "mousedown", this._onScaleMouseDown);

      this._container.parentNode.removeChild(this._container);
    },

    getBounds: function() {
        var size = this.map.getSize();
        var topRight = new L.Point();
        var bottomLeft = new L.Point();

        bottomLeft.x = Math.round((size.x - this._width) / 2);
        topRight.y = Math.round((size.y - this._height) / 2);
        topRight.x = size.x - bottomLeft.x;
        bottomLeft.y = size.y - topRight.y;

        var sw = this.map.containerPointToLatLng(bottomLeft);
        var ne = this.map.containerPointToLatLng(topRight);

        return new L.LatLngBounds(sw, ne);
    },

    _getBoundsPinToCenter: function() {
      var size = this.map.getSize();
      var topRight = new L.Point();
      var bottomLeft = new L.Point();

      bottomLeft.x = Math.round((size.x - this.dimensions.width) / 2);
      topRight.y = Math.round((size.y - this.dimensions.height) / 2);
      topRight.x = size.x - bottomLeft.x;
      bottomLeft.y = size.y - topRight.y;

      var sw = this.map.containerPointToLatLng(bottomLeft);
      var ne = this.map.containerPointToLatLng(topRight);

      this._updateNWPosition();
      return new L.LatLngBounds(sw, ne);
    },

    _getBoundsPinToNorthWest: function() {
      var size = this.map.getSize();
      var topRight = new L.Point();
      var bottomLeft = new L.Point();

      var nwPoint = this.map.latLngToContainerPoint(this.nwLocation);

      topRight.y = nwPoint.y;
      bottomLeft.y = nwPoint.y + this.dimensions.height;
      bottomLeft.x = nwPoint.x;
      topRight.x = nwPoint.x + this.dimensions.width;

      var sw = this.map.containerPointToLatLng(bottomLeft);
      var ne = this.map.containerPointToLatLng(topRight);

      return new L.LatLngBounds(sw, ne);
    },

    _updateNWPosition: function() {
      var size = this.map.getSize();

      var topBottomHeight = Math.round((size.y-this.dimensions.height)/2);
      var leftRightWidth = Math.round((size.x-this.dimensions.width)/2);
      this.nwPosition = new L.Point(leftRightWidth, topBottomHeight);
      this.nwLocation = this.map.containerPointToLatLng(this.nwPosition);
    },

    _updateLocation: function(location){
    //   var self = this;
    //   var xhr = new XMLHttpRequest();
    //   xhr.onreadystatechange = function(){
    //     if (xhr.readyState === 4 && xhr.status === 200){
    //       var latlngPoints = JSON.parse(xhr.responseText)[0].boundingbox;

    //       self.map.fitBounds([
    //         [latlngPoints[0],latlngPoints[2]],
    //         [latlngPoints[1],latlngPoints[3]]
    //       ]);

      //     if (this.refs.locked){
      //       //uncheck the "pin to nw corner" box
      //       document.getElementById('map-lock-box').childNodes[1].checked = false;

      //       this.refs.locked = false;
      //       this._render();
      //     }

      //     this.refs.was_locked = false;
      //     this.refs.lock_change = false;

      //     this._updateToolDimensions();
      //     this.fire("change");
      //   }
      // }

    //   xhr.open("GET", "http://nominatim.openstreetmap.org/search/?format=json&limit=1&q="+location, true);
    //   xhr.send(null);
    },

    _calculateInitialPositions: function() {
      var size = this.map.getSize();

      var topBottomHeight = Math.round((size.y-this._height)/2);
      var leftRightWidth = Math.round((size.x-this._width)/2);
      this.centerPosition = new L.Point(this.map.getCenter());
      this.nwPosition = new L.Point(leftRightWidth + this.offset.x, topBottomHeight + this.offset.y);
      this.nwLocation = this.map.containerPointToLatLng(this.nwPosition);
      this.bounds = this.getBounds();
    },

    setOrientation: function(x) {

      if (this.refs.paper_aspect_ratios[this.refs.paperSize][x] &&
          this.refs.page_aspect_ratio !== this.refs.paper_aspect_ratios[this.refs.paperSize][x]) {

        this.refs.pageOrientation = x;
        this.refs.page_aspect_ratio = this.refs.paper_aspect_ratios[this.refs.paperSize][x];

        this._updateOrientation();

        // if the flop is outside the map bounds, contain it.
        var mapBds = this.map.getBounds();
        if(!mapBds.contains(this.bounds)) {
          this.map.fitBounds(this.bounds, {animate: false});
        }

        this.fire("change");
      }

      return this;
    },

    getPages: function() {
      return {cols: this.refs.cols, rows: this.refs.rows};
    },

    getPinnedBounds: function() {
      return this.bounds || null;
    },

    _updateOrientation: function(){
      //switch from landscape to portrait
      this.dimensions.height = this.dimensions.cellWidth * this.refs.rows;
      this.dimensions.width = this.dimensions.cellHeight * this.refs.cols;
      // make sure it fits on the screen.
      this._updateToolDimensions();
      // re-calc bounds
      this.bounds = this._getBoundsPinToCenter();
      this._render();
    },

    setPaperSize: function(x) {
      if (this.refs.paper_aspect_ratios[x] || x !== this.refs.paperSize) {
        this.refs.paperSize = x;
        this.refs.page_aspect_ratio = this.refs.paper_aspect_ratios[this.refs.paperSize][this.refs.pageOrientation];

        this._updatePaperSize();
        // if the new size is outside the map bounds, contain it.
        var mapBds = this.map.getBounds();
        if(!mapBds.contains(this.bounds)) {
          this.map.fitBounds(this.bounds, {animate: false});
        }

        this.fire("change");
      }
      return this;
    },

    _updatePaperSize: function(){
      //switch between letter/a3/a4
      this.dimensions.height = ((this.dimensions.width / this.refs.cols) / this.refs.page_aspect_ratio) * this.refs.rows;
      // make sure it fits on the screen.
      this._updateToolDimensions();
      // re-calc bounds
      if (this.refs.locked){
        this.bounds = this._getBoundsPinToNorthWest();
      } else {
        this.bounds = this._getBoundsPinToCenter();
      }
      this._render();
    },

    _setDimensions: function() {
      this.dimensions.nw = this.map.latLngToContainerPoint(this.bounds.getNorthWest());
      this.dimensions.ne = this.map.latLngToContainerPoint(this.bounds.getNorthEast());
      this.dimensions.sw = this.map.latLngToContainerPoint(this.bounds.getSouthWest());
      this.dimensions.se = this.map.latLngToContainerPoint(this.bounds.getSouthEast());
      this.dimensions.width = this.dimensions.ne.x - this.dimensions.nw.x;
      this.dimensions.height = this.dimensions.se.y - this.dimensions.ne.y;

      this.dimensions.cellWidth = this.dimensions.width / this.refs.cols;
      this.dimensions.cellHeight = this.dimensions.height / this.refs.rows;
    },

    _updateToolDimensions: function() {
      var size = this.map.getSize();
      //to update the numbers displayed in the side menu
      var count = document.getElementsByClassName("number");

      var width = this.dimensions.width / this.refs.prevCols;
      var height = this.dimensions.height / this.refs.prevRows;

      this.dimensions.width = width * this.refs.cols;
      this.dimensions.height = height * this.refs.rows;

      if (!this.refs.locked){
        if (this.dimensions.height > size.y - 80 || this.dimensions.height < size.y - 90 ) {
          this.dimensions.height = size.y - 90;
          this.dimensions.width = ((this.dimensions.height / this.refs.rows) * this.refs.page_aspect_ratio) * this.refs.cols;
        }
        if (this.dimensions.width > size.x - 70) {
          this.dimensions.width = size.x - 70;
          this.dimensions.height = ((this.dimensions.width / this.refs.cols) / this.refs.page_aspect_ratio) * this.refs.rows;
        }
      }

      this.refs.prevCols = this.refs.cols;
      this.refs.prevRows = this.refs.rows;

      count[0].textContent = this.refs.cols;
      count[1].textContent = this.refs.rows;

      this.bounds = this.refs.locked ? this._getBoundsPinToNorthWest() : this._getBoundsPinToCenter();

      this._render();
    },

    _makePageElement: function(x,y,w,h) {
      var div = document.createElement('div');
      div.className = "page";
      div.style.left = x + "%";
      div.style.top = y + "%";
      div.style.height = h + "%";
      div.style.width = w + "%";
      return div;
    },

    _createPages: function() {
      var cols = this.refs.cols,
          rows = this.refs.rows,
          gridElm = this._grid,
          top = this.dimensions.nw.y,
          left = this.dimensions.nw.x,
          width = this.dimensions.width,
          height = this.dimensions.height;

      L.DomUtil.removeClass(this._container, "one-row");
      L.DomUtil.removeClass(this._container, "one-col");

      if (cols === 1) L.DomUtil.addClass(this._container, "one-col");
      if (rows === 1) L.DomUtil.addClass(this._container, "one-row");

      this._grid.innerHTML = "";
      this._grid.style.top = top + "px";
      this._grid.style.left = left + "px";
      this._grid.style.width = width + "px";
      this._grid.style.height = height + "px";

      var spacingX = 100 / cols,
          spacingY = 100 / rows;

      // cols
      for (var i = 0;i< cols;i++) {
        for (var r = 0;r< rows;r++) {
          var elm = gridElm.appendChild( this._makePageElement(spacingX * i, spacingY * r, spacingX, spacingY ) );

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
        }
      }
    },

        //adds +/-
    _createPageModifiers: function() {
      var gridModifiers = document.getElementsByClassName("grid-modifier");
      this._addRow = gridModifiers[5];
      this._minusRow = gridModifiers[3];
      this._addCol = gridModifiers[2];
      this._subCol = gridModifiers[0];

      L.DomEvent.addListener(this._addRow, "click", this._onAddRow, this);
      L.DomEvent.disableClickPropagation(this._addRow);

      L.DomEvent.addListener(this._minusRow, "click", this._onSubtractRow, this);
      L.DomEvent.disableClickPropagation(this._minusRow);

      L.DomEvent.addListener(this._addCol, "click", this._onAddCol, this);
      L.DomEvent.disableClickPropagation(this._addCol);

      L.DomEvent.addListener(this._subCol, "click", this._onSubtractCol, this);
      L.DomEvent.disableClickPropagation(this._subCol);

    },

    _createElements: function() {
        if (!!this._container)
          return;

        // base elements
        this._container =   L.DomUtil.create("div", "leaflet-areaselect-container", this.map._controlContainer);
        this._grid =        L.DomUtil.create("div", "leaflet-areaselect-grid", this._container);

        // add/remove page btns
        this._createPageModifiers();

        // add event listeners to menu
        this._calculateInitialPositions();
        this._setDimensions();
        this._createPages();
        this._onMapLock();
        this._onSearch();

        this.map.on("move",     this._onMapMovement, this);
        this.map.on("moveend",  this._onMapMovement, this);
        this.map.on("viewreset",  this._onMapReset, this);
        // this.map.on("resize",   this._onMapReset, this);

        this._onMapReset();
        this._updateToolDimensions();
    },

    _onAddRow: function(evt) {
      evt.stopPropagation();
      this.refs.rows++;
      this._updatePages();
    },

    _onSubtractRow: function(evt) {
      evt.stopPropagation();
      if (this.refs.rows === 1) return;
      this.refs.rows--;
      this._updatePages();
    },

    _onAddCol: function(evt) {
      evt.stopPropagation();
      this.refs.cols++;
      this._updatePages();
    },

    _onSubtractCol: function(evt) {
      evt.stopPropagation();
      if (this.refs.cols === 1) return;
      this.refs.cols--;
      this._updatePages();
    },

    _updatePages: function() {
      this._setDimensions();
      this._updateToolDimensions();
      this._createPages();
      this.fire("change");
    },

    _updatePageGridPosition: function(left, top, width, height) {
      this._grid.style.top = top + "px";
      this._grid.style.left = left + "px";
      this._grid.style.width = width + "px";
      this._grid.style.height = height + "px";
    },

    _updateGridElement: function(element, dimension) {
        element.style.width = dimension.width + "px";
        element.style.height = dimension.height + "px";
        element.style.top = dimension.top + "px";
        element.style.left = dimension.left + "px";
        element.style.bottom = dimension.bottom + "px";
        element.style.right = dimension.right + "px";
    },

    _onMapMovement: function(){
        if (this.refs.locked){
          this._render();
        } else {
          this.bounds = this._getBoundsPinToCenter();
        }
        this.fire("change");
    },

    _onMapReset: function() {
      if (this.refs.locked && !this.refs.lock_change){
        this.refs.zoomScale = 1 / this.map.getZoomScale(this.refs.startZoom);
        this._render();
        this.refs.lock_change = true;
      } else if (this.refs.locked || (this.refs.was_locked && this.refs.lock_change)) {
        this.refs.zoomScale = 1 / this.map.getZoomScale(this.refs.startZoom);
        this._render();
        this.refs.was_locked = false;
        this.refs.lock_change = this.refs.locked;
      }
      this.fire("change");
    },

    _onMapResize: function() {
      if (this.refs.locked){
        this._render();
      }
    },

    _onMapChange: function() {
        this.fire("change");
    },

    _onSearch: function(){
      try {
        var geocoder = L.control.geocoder('search-w9J1EjM', {
            markers: false
          }).addTo(this.map);

        var self = this;

        function unlockGrid(self){
          if (self.refs.locked){
          //uncheck the "pin to nw corner" box
            document.getElementById('map-lock-box').childNodes[1].checked = false;

            self.refs.locked = false;
            self._render();
          }

          self.refs.was_locked = false;
          self.refs.lock_change = false;

          self._updateToolDimensions();
          self.fire("change");
        }

        L.DomEvent.addListener(geocoder, 'select', function(){
          unlockGrid(self);
        }, self);

        L.DomEvent.addListener(geocoder, 'highlight', function(){
          unlockGrid(self);
        }, self);
      } catch (err) {
        console.warn(err.stack);
      }
    },

    _onMapLock: function(){
      var mapLockStatus = document.getElementById('map-lock-box').childNodes[1];
      var self = this;

      L.DomEvent.addListener(mapLockStatus, "change", function(){
        self.refs.was_locked = self.refs.locked ? self.refs.lock_change : false;
        self.refs.locked = mapLockStatus.checked;

        if (!self.refs.locked){
          self.map.fitBounds(self.bounds, {animation: false});

          self._render();
          self.fire("change");
        }
      });
    },

    _onPaperSizeChange: function(){
      var form = document.getElementById("atlas_paper_size");
      var self = this;

      L.DomEvent.addListener(form, "change", function(){
        self._setPaperSize(this[this.selectedIndex].value);
      });
    },

    _render: function() {
      var size = this.map.getSize();

      if (!this.nwPosition) {
          this._calculateInitialPositions();
      }

      this._setDimensions();

      var nw = this.dimensions.nw,
        ne = this.dimensions.ne,
        sw = this.dimensions.sw,
        se = this.dimensions.se,
        width = this.dimensions.width,
        height = this.dimensions.height,
        rightWidth = size.x - width - nw.x,
        bottomHeight = size.y - height - nw.y;

      this._updatePageGridPosition(nw.x, nw.y, width, height);
    },
});

L.pageComposer = function(options) {
    return new L.PageComposer(options);
};
