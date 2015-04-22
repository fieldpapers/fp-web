// Based on -- https://github.com/heyman/leaflet-areaselect/
//
L.PageComposer = L.Class.extend({
    includes: L.Mixin.Events,

    options: {
        pageHeight: 150,
        minHeight: 80,
        paddingToEdge: 30,
        keepAspectRatio: true,
    },

    offset: new L.Point(0,0),
    dimensions: {},

    refs: {
      paper_aspect_ratios: {
        letter : {landscape: 1.294, portrait: 0.773, scale: 1},
        a3: {landscape: 1.414, portrait: 0.707, scale: 1.414},
        a4: {landscape: 1.414, portrait: 0.707, scale: 1}
      },
      toolScale: 1,
      paperSize: 'letter',
      pageOrientation: 'landscape',
      page_aspect_ratio:  null,
      page_dimensions: {
        width: 0,
        height: 0
      },
      rows: 1,
      cols: 2
    },

    initialize: function(options) {
      L.Util.setOptions(this, options);
      this.refs.page_aspect_ratio = this.refs.paper_aspect_ratios[this.refs.paperSize][this.refs.pageOrientation];
      this._width = (this.options.pageHeight * this.refs.page_aspect_ratio) * this.refs.cols;
      this._height = this.options.pageHeight * this.refs.rows;
      this._limitChangeFire = L.Util.limitExecByInterval( function(){this.fire("change");}, 500, this);
    },

    setPaperSize: function(x) {
      if (x === this.refs.paperSize || !this.refs.paper_aspect_ratios[x]) return this;
      this.refs.paperSize = x;
      this.refs.page_aspect_ratio = this.refs.paper_aspect_ratios[this.refs.paperSize][this.refs.pageOrientation];

      this._updateToolDimensions();

      // if the new size is outside the map bounds, contain it.
      var mapBds = this.map.getBounds();
      if(!mapBds.contains(this.bounds)) {
        this.map.fitBounds(this.bounds, {animate: false});
      }

      this.fire("change");
      return this;
    },

    setOrientation: function(x) {
      if (this.refs.paper_aspect_ratios[this.refs.paperSize][x] &&
          this.refs.page_aspect_ratio !== this.refs.paper_aspect_ratios[this.refs.paperSize][x]) {

        this.refs.pageOrientation = x;
        this.refs.page_aspect_ratio = this.refs.paper_aspect_ratios[this.refs.paperSize][x];

        this._updateToolDimensions();

        // if the flop is outside the map bounds, contain it.
        var mapBds = this.map.getBounds();
        if(!mapBds.contains(this.bounds)) {
          this.map.fitBounds(this.bounds, {animate: false});
        }

        this.fire("change");
      }

      return this;
    },

    addTo: function(map) {
        this.map = map;
        this._createElements();
        this._render();
        return this;
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

    getPages: function() {
      return {cols: this.refs.cols, rows: this.refs.rows};
    },

    getPinnedBounds: function() {
      return this.bounds || null;
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

        this._container =   L.DomUtil.create("div", "leaflet-areaselect-container", this.map._controlContainer);
        this._grid =        L.DomUtil.create("div", "leaflet-areaselect-grid", this._container);

        // shade layers
        this._topShade =    L.DomUtil.create("div", "leaflet-areaselect-shade", this._container);
        this._bottomShade = L.DomUtil.create("div", "leaflet-areaselect-shade", this._container);
        this._leftShade =   L.DomUtil.create("div", "leaflet-areaselect-shade", this._container);
        this._rightShade =  L.DomUtil.create("div", "leaflet-areaselect-shade", this._container);

        // add/remove cols & rows
        this._setPageTool();

        // scale tool
        this._scaleHandle = L.DomUtil.create("div", "leaflet-areaselect-handle scale-handle", this._container);
        this._setScaleHandler(this._scaleHandle, -1, -1);

        // drag tool
        this._dragHandle = L.DomUtil.create("div", "leaflet-areaselect-handle drag-handle", this._container);
        var draggable = new L.DraggableAny(this._dragHandle, null, this._getPos, this._setPos, this);
        draggable.enable();

        this.map.on("move",     this._onMapChange, this);
        this.map.on("moveend",  this._onMapChange, this);
        this.map.on("zoomend",  this._onMapChange, this);
        this.map.on("resize",   this._onMapResize, this);

        this.fire("change");
    },

    _getPos: function(ctx) {
      return this.map.latLngToContainerPoint(this.nwLocation);
    },

    _setPos: function(pos, delta){
      this._updateNWPosition(pos);
      this._render();
      this._limitChangeFire();
    },

    _limitChangeFire: function(){},

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
      this._updateToolDimensions();
      this.fire("change");
    },

    _calculateInitialPositions: function() {
      var size = this.map.getSize();

      var topBottomHeight = Math.round((size.y-this._height)/2);
      var leftRightWidth = Math.round((size.x-this._width)/2);
      this.nwPosition = new L.Point(leftRightWidth + this.offset.x, topBottomHeight + this.offset.y);
      this.nwLocation = this.map.containerPointToLatLng(this.nwPosition);
      this.bounds = this.getBounds();
    },

    _updateToolDimensions: function() {
      var scale = this.refs.paper_aspect_ratios[this.refs.paperSize].scale;
      if (this.refs.pageOrientation === 'portrait') {
        this.dimensions.width = (this.options.pageHeight * this.refs.toolScale * scale) * this.refs.cols;
        this.dimensions.height = ((this.options.pageHeight / this.refs.page_aspect_ratio) * this.refs.toolScale * scale) * this.refs.rows;
      } else {
        this.dimensions.width = ((this.options.pageHeight * this.refs.page_aspect_ratio) * this.refs.toolScale * scale) * this.refs.cols;
        this.dimensions.height = (this.options.pageHeight * this.refs.toolScale * scale) * this.refs.rows;
      }

      // re-calc bounds
      this.bounds = this._getBoundsPinToNorthWest();
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

    _updateNWPosition: function(pos) {
      this.nwPosition = pos;
      this.nwLocation = this.map.containerPointToLatLng(pos);
      this.bounds = this._getBoundsPinToNorthWest();
    },

    _setPageTool: function() {

      function createInnerText(container, text) {
        var c = L.DomUtil.create("div", "", container);
        c.innerHTML = text;
      }
      // row
      this._rowModifier = L.DomUtil.create("div", "leaflet-areaselect-handle page-tool row-modifier", this._container);
      this._addRow = L.DomUtil.create("div", "modifier-btn add-btn", this._rowModifier);
      //this._addRow.innerHTML = "+";
      createInnerText(this._addRow, "+");
      this._minusRow = L.DomUtil.create("div", "modifier-btn subtract-btn", this._rowModifier);
      //this._minusRow.innerHTML = "&#8722;";
      createInnerText(this._minusRow, "&#8722;");

      // col
      this._colModifier = L.DomUtil.create("div", "leaflet-areaselect-handle page-tool col-modifier", this._container);
      this._addCol = L.DomUtil.create("div", "modifier-btn add-btn", this._colModifier);
      //this._addCol.innerHTML = "+";
      createInnerText(this._addCol, "+");
      this._minusCol = L.DomUtil.create("div", "modifier-btn subtract-btn", this._colModifier);
      //this._minusCol.innerHTML = "&#8722;";
      createInnerText(this._minusCol, "&#8722;");


      L.DomEvent.addListener(this._addRow, "click", this._onAddRow, this);
      L.DomEvent.addListener(this._minusRow, "click", this._onSubtractRow, this);
      L.DomEvent.addListener(this._addCol, "click", this._onAddCol, this);
      L.DomEvent.addListener(this._minusCol, "click", this._onSubtractCol, this);
    },

    _setScaleHandler: function(handle, xMod, yMod) {
        xMod = xMod || 1;
        yMod = yMod || 1;

        var self = this;
        function onMouseDown(event) {
            event.stopPropagation();
            L.DomEvent.removeListener(this, "mousedown", onMouseDown);
            var curX = event.pageX;
            var curY = event.pageY;
            var ratio = self.dimensions.width / self.dimensions.height;
            var size = self.map.getSize();
            L.DomUtil.disableTextSelection();
            L.DomUtil.addClass(self._container, 'scaling');

            var nwPt = self.map.latLngToContainerPoint(self.bounds.getNorthWest());
            var maxHeightY = size.y - self.map.latLngToContainerPoint(self.bounds.getNorthWest()).y - self.options.paddingToEdge;
            var maxHeightX = (size.x - self.map.latLngToContainerPoint(self.bounds.getNorthWest()).x - self.options.paddingToEdge) * 1/ratio;
            var maxHeight = Math.min(maxHeightY, maxHeightX);

            function onMouseMove(event) {
                var width = self.dimensions.width,
                    height = self.dimensions.height;

                if (self.options.keepAspectRatio) {
                    //var maxHeight = (height >= width ? size.y : size.y * (1/ratio) ) - 30;
                    height += (curY - event.originalEvent.pageY) * 2 * yMod;
                    height = Math.max(self.options.minHeight, height);
                    height = Math.min(maxHeight, height);
                    width = height * ratio;
                    self.refs.toolScale = height/self.options.pageHeight;

                } else {
                    self._width += (curX - event.originalEvent.pageX) * 2 * xMod;
                    self._height += (curY - event.originalEvent.pageY) * 2 * yMod;
                    self._width = Math.max(self.options.paddingToEdge, self._width);
                    self._height = Math.max(self.options.paddingToEdge, self._height);
                    self._width = Math.min(size.x-self.options.paddingToEdge, self._width);
                    self._height = Math.min(size.y-self.options.paddingToEdge, self._height);
                }

                self.dimensions.width = width;
                self.dimensions.height = height;

                curX = event.originalEvent.pageX;
                curY = event.originalEvent.pageY;

                self.bounds = self._getBoundsPinToNorthWest();
                self._setDimensions();
                self._render();
            }
            function onMouseUp(event) {
                L.DomEvent.removeListener(self.map, "mouseup", onMouseUp);
                L.DomEvent.removeListener(self.map, "mousemove", onMouseMove);
                L.DomEvent.addListener(handle, "mousedown", onMouseDown);
                L.DomUtil.enableTextSelection();
                L.DomUtil.removeClass(self._container, 'scaling');
                self.fire("change");
            }

            L.DomEvent.addListener(self.map, "mousemove", onMouseMove);
            L.DomEvent.addListener(self.map, "mouseup", onMouseUp);
        }
        L.DomEvent.addListener(handle, "mousedown", onMouseDown);
    },

    _onMapResize: function() {
        this._render();
    },

    _onMapChange: function() {
        this._render();
        this.fire("change");
    },

    _updateTool: function(left, top, width, height) {
      var cols = this.refs.cols,
          rows = this.refs.rows,
          gridElm = this._grid;

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

      function makeElm(x,y,w,h) {
        var div = document.createElement('div');
        div.className = "page";
        div.style.left = x + "%";
        div.style.top = y + "%";
        div.style.height = h + "%";
        div.style.width = w + "%";
        gridElm.appendChild(div);
        return div;
      }

      // cols
      for (var i = 0;i< cols;i++) {
        for (var r = 0;r< rows;r++) {
          var elm = makeElm(spacingX * i, spacingY * r, spacingX, spacingY );

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
          height = this.dimensions.height;


      function setElement(element, dimension) {
          element.style.width = dimension.width + "px";
          element.style.height = dimension.height + "px";
          element.style.top = dimension.top + "px";
          element.style.left = dimension.left + "px";
          element.style.bottom = dimension.bottom + "px";
          element.style.right = dimension.right + "px";
      }

      this._updateTool(nw.x, nw.y, width, height);

      var rightWidth = size.x - width - nw.x,
          bottomHeight = size.y - height - nw.y;

      // position shades
      setElement(this._topShade, {
        width:size.x,
        height:nw.y > 0 ? nw.y : 0,
        top:0,
        left:0
      });

      setElement(this._bottomShade, {
        width:size.x,
        height: bottomHeight > 0 ? bottomHeight : 0,
        bottom:0,
        left:0
      });

      setElement(this._leftShade, {
          width: nw.x > 0 ? nw.x : 0,
          height: height,
          top: nw.y,
          left: 0
      });

      setElement(this._rightShade, {
          width: rightWidth > 0 ? rightWidth : 0,
          height: height,
          top: nw.y,
          right: 0
      });

      // position handles
      setElement(this._dragHandle, {left:nw.x, top:nw.y });
      setElement(this._scaleHandle, {left:nw.x + width, top:nw.y + height});

      setElement(this._rowModifier, {left:nw.x + (width / 2), top:nw.y + height});
      setElement(this._colModifier, {left:nw.x + width, top:nw.y + (height/2)});


    }
});

L.pageComposer = function(options) {
    return new L.PageComposer(options);
};
