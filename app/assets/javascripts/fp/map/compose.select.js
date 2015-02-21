(function(exports){
  "use strict";

  var FP = exports.FP || (exports.FP = {});
  var Map = FP.map || (FP.map = {});
  var compose = Map.compose || (FP.map.compose = {});


  compose.select = function(opts) {
    var __ = {};

    var map = L.map(opts.selector, FP.map.options);

    map.setView(opts.initialView[0], opts.initialView[1]);

    var tileLayer = L.tileLayer("http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png").addTo(map);

    L.control.scale().addTo(map);

    var areaSelect = L.areaSelect({width:200, height:300});
    areaSelect.addTo(map);

    // cache some elements
    var atlasRows = $('#atlas_rows'),
        atlasCols = $('#atlas_cols'),
        atlasZoom = $("#atlas_zoom"),
        atlasWest = $("#atlas_west"),
        atlasSouth = $("#atlas_south"),
        atlasEast = $("#atlas_east"),
        atlasNorth = $("#atlas_north"),
        atlasProvider = $('#atlas_provider');

    areaSelect.on('change', function(e){
      var pages = areaSelect.getPages();
      var bds = areaSelect.getPinnedBounds();

      atlasRows.val( pages.rows );
      atlasCols.val( pages.cols );
      atlasZoom.val( map.getZoom() );
      atlasWest.val( bds.getWest() );
      atlasSouth.val( bds.getSouth() );
      atlasEast.val( bds.getEast() );
      atlasNorth.val( bds.getNorth() );
    });

    // set select options for tile providers
    for (var lyr in Map.options.tileProviders) {
      atlasProvider.append($('<option>', {
        value: lyr,
        text: Map.options.tileProviders[lyr].label
      }));
    }

    $('#atlas_orientation').on('change', function(){
      areaSelect.setOrientation(this.value);
    });

    $('#atlas_provider').on('change', function(){
      if (!Map.options.tileProviders[this.value]) return;
      if (map.hasLayer(tileLayer)) map.removeLayer(tileLayer);
      tileLayer = L.tileLayer(Map.options.tileProviders[this.value].template.toLowerCase()).addTo(map);
    });


    // sync up the fields
    map.fire("move");

    return __;
  };


})(this);


// https://github.com/heyman/leaflet-areaselect/
L.AreaSelect = L.Class.extend({
    includes: L.Mixin.Events,

    options: {
        width: 200,
        height: 300,
        keepAspectRatio: true,
    },

    offset: new L.Point(0,0),
    dimensions: {},

    refs: {
      paper_orientations: {"landscape": 1.50, "portrait": .75},
      page_aspect_ratio:  null,
      atlas_aspect_ratio: null,
      page_dimensions: {
        width: 0,
        height: 0
      },
      rows: 1,
      cols: 1
    },

    initialize: function(options) {
        L.Util.setOptions(this, options);
        this.refs.page_aspect_ratio = this.refs.paper_orientations["landscape"];
        this.setSelectorSize();
    },

    setSelectorSize: function() {
      this.refs.atlas_aspect_ratio = this.refs.page_aspect_ratio * 1;
      this._width = (150 * this.refs.atlas_aspect_ratio) * this.refs.cols;
      this._height = 150 * this.refs.rows;
    },

    setOrientation: function(x) {
      if (this.refs.paper_orientations[x]) {
        this.refs.page_aspect_ratio = this.refs.paper_orientations[x];
        this.refs.atlas_aspect_ratio = this.refs.page_aspect_ratio * 1;

        this.dimensions.width = (150 * this.refs.atlas_aspect_ratio) * this.refs.cols;
        this.dimensions.height = 150 * this.refs.rows;

        this.bounds = this._getBoundsPinToNorthWest();
        this._render();
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
      return ctx.map.latLngToContainerPoint(ctx.nwLocation);
    },

    _setPos: function(elm, pos, delta, ctx){
      ctx._updateNWPosition(pos);
      ctx._render();
      ctx.fire("change");
    },

    _updateNWPosition: function(pos) {
      this.nwPosition = pos;
      this.nwLocation = this.map.containerPointToLatLng(pos);
      this.bounds = this._getBoundsPinToNorthWest();
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
      this.refs.atlas_aspect_ratio = this.refs.page_aspect_ratio * 1;
      this.dimensions.width = (this.dimensions.cellHeight * this.refs.atlas_aspect_ratio) * this.refs.cols;
      this.dimensions.height = this.dimensions.cellHeight * this.refs.rows;
      this.bounds = this._getBoundsPinToNorthWest();
      this._render();
      this.fire("change");
    },

    _setPageTool: function() {
      // row
      this._rowModifier = L.DomUtil.create("div", "leaflet-areaselect-handle page-tool row-modifier", this._container);
      this._addRow = L.DomUtil.create("div", "modifier-btn add-btn", this._rowModifier);
      this._addRow.innerHTML = "+";
      this._minusRow = L.DomUtil.create("div", "modifier-btn subtract-btn", this._rowModifier);
      this._minusRow.innerHTML = "&#8722;";

      // col
      this._colModifier = L.DomUtil.create("div", "leaflet-areaselect-handle page-tool col-modifier", this._container);
      this._addCol = L.DomUtil.create("div", "modifier-btn add-btn", this._colModifier);
      this._addCol.innerHTML = "+";
      this._minusCol = L.DomUtil.create("div", "modifier-btn subtract-btn", this._colModifier);
      this._minusCol.innerHTML = "&#8722;";


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

            function onMouseMove(event) {
                var width = self.dimensions.width,
                    height = self.dimensions.height;

                if (self.options.keepAspectRatio) {
                    var maxHeight = (height >= width ? size.y : size.y * (1/ratio) ) - 30;
                    height += (curY - event.originalEvent.pageY) * 2 * yMod;
                    height = Math.max(30, height);
                    height = Math.min(maxHeight, height);
                    width = height * ratio;
                } else {
                    self._width += (curX - event.originalEvent.pageX) * 2 * xMod;
                    self._height += (curY - event.originalEvent.pageY) * 2 * yMod;
                    self._width = Math.max(30, self._width);
                    self._height = Math.max(30, self._height);
                    self._width = Math.min(size.x-30, self._width);
                    self._height = Math.min(size.y-30, self._height);
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

      this._grid.innerHTML = "";
      this._grid.style.top = top + "px";
      this._grid.style.left = left + "px";
      this._grid.style.width = width + "px";
      this._grid.style.height = height + "px";

      var spacingX = 100 / cols,
          spacingY = 100 / rows;

      function makeElm(x,y,w,h) {
        var div = document.createElement('div');
        div.className = "grid-elm-col";
        div.style.left = x + "%";
        div.style.top = y + "%";
        div.style.height = h + "%";
        div.style.width = w + "%";
        gridElm.appendChild(div);
      }

      // cols
      for (var i = 0;i< cols;i++) {
        for (var r = 0;r< rows;r++) {
          makeElm(spacingX * i, spacingY * r, spacingX, spacingY );
        }
      }
    },

    _calculateInitialPositions: function() {
      var size = this.map.getSize();

      var topBottomHeight = Math.round((size.y-this._height)/2);
      var leftRightWidth = Math.round((size.x-this._width)/2);
      this.nwPosition = new L.Point(leftRightWidth + this.offset.x, topBottomHeight + this.offset.y);
      this.nwLocation = this.map.containerPointToLatLng(this.nwPosition);
      this.bounds = this.getBounds();
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


      function setDimensions(element, dimension) {
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
      setDimensions(this._topShade, {
        width:size.x,
        height:nw.y > 0 ? nw.y : 0,
        top:0,
        left:0
      });

      setDimensions(this._bottomShade, {
        width:size.x,
        height: bottomHeight > 0 ? bottomHeight : 0,
        bottom:0,
        left:0
      });

      setDimensions(this._leftShade, {
          width: nw.x > 0 ? nw.x : 0,
          height: height,
          top: nw.y,
          left: 0
      });

      setDimensions(this._rightShade, {
          width: rightWidth > 0 ? rightWidth : 0,
          height: height,
          top: nw.y,
          right: 0
      });

      // position handles
      setDimensions(this._dragHandle, {left:nw.x, top:nw.y });
      setDimensions(this._scaleHandle, {left:nw.x + width, top:nw.y + height});

      setDimensions(this._rowModifier, {left:nw.x + (width / 2), top:nw.y + height});
      setDimensions(this._colModifier, {left:nw.x + width, top:nw.y + (height/2)});


    }
});

L.areaSelect = function(options) {
    return new L.AreaSelect(options);
};



/*
 * L.Draggable allows you to add dragging capabilities to any element. Supports mobile devices too.
 */

L.DraggableAny = L.Class.extend({
  includes: L.Mixin.Events,
  statics: {
    START: L.Browser.touch ? ['touchstart', 'mousedown'] : ['mousedown'],
    END: {
      mousedown: 'mouseup',
      touchstart: 'touchend',
      pointerdown: 'touchend',
      MSPointerDown: 'touchend'
    },
    MOVE: {
      mousedown: 'mousemove',
      touchstart: 'touchmove',
      pointerdown: 'touchmove',
      MSPointerDown: 'touchmove'
    }
  },

  initialize: function (element, dragStartTarget, getPositionFn, setPositionFn, context) {
    this._element = element;
    this._dragStartTarget = dragStartTarget || element;

    this.getPosition = getPositionFn;
    this.setPosition = setPositionFn;
    this._context = context;
  },

  enable: function () {
    if (this._enabled) { return; }

    L.DomEvent.on(this._dragStartTarget, L.Draggable.START.join(' '), this._onDown, this);

    this._enabled = true;
  },

  disable: function () {
    if (!this._enabled) { return; }

    L.DomEvent.off(this._dragStartTarget, L.Draggable.START.join(' '), this._onDown, this);

    this._enabled = false;
    this._moved = false;
  },

  _onDown: function (e) {
    this._moved = false;

    if (e.shiftKey || ((e.which !== 1) && (e.button !== 1) && !e.touches)) { return; }

    L.DomEvent.stopPropagation(e);

    if (L.DomUtil.hasClass(this._element, 'leaflet-zoom-anim')) { return; }

    L.DomUtil.disableImageDrag();
    L.DomUtil.disableTextSelection();

    if (this._moving) { return; }

    this.fire('down');

    var first = e.touches ? e.touches[0] : e;

    this._startPoint = new L.Point(first.clientX, first.clientY);
    this._startPos = this._newPos = this.getPosition(this._context);

    L.DomEvent
        .on(document, L.Draggable.MOVE[e.type], this._onMove, this)
        .on(document, L.Draggable.END[e.type], this._onUp, this);
  },

  _onMove: function (e) {
    if (e.touches && e.touches.length > 1) {
      this._moved = true;
      return;
    }

    var first = (e.touches && e.touches.length === 1 ? e.touches[0] : e),
        newPoint = new L.Point(first.clientX, first.clientY),
        offset = newPoint.subtract(this._startPoint);

    if (!offset.x && !offset.y) { return; }
    if (L.Browser.touch && Math.abs(offset.x) + Math.abs(offset.y) < 3) { return; }

    L.DomEvent.preventDefault(e);

    if (!this._moved) {
      this.fire('dragstart');

      this._moved = true;
      this._startPos = this.getPosition(this._context).subtract(offset);

      L.DomUtil.addClass(document.body, 'leaflet-dragging');

      this._lastTarget = e.target || e.srcElement;
      L.DomUtil.addClass(this._lastTarget, 'leaflet-drag-target');
    }

    this._newPos = this._startPos.add(offset);
    this._offset = this._prevPos ? this._newPos.subtract(this._prevPos) : offset;
    this._prevPos = this._newPos.clone();

    this._moving = true;

    L.Util.cancelAnimFrame(this._animRequest);
    this._animRequest = L.Util.requestAnimFrame(this._updatePosition, this, true, this._dragStartTarget);
  },

  _updatePosition: function () {
    this.fire('predrag');
    this.setPosition(this._element, this._newPos, this._offset, this._context);
    //L.DomUtil.setPosition(this._element, this._newPos);
    this.fire('drag');
  },

  _onUp: function () {
    L.DomUtil.removeClass(document.body, 'leaflet-dragging');

    if (this._lastTarget) {
      L.DomUtil.removeClass(this._lastTarget, 'leaflet-drag-target');
      this._lastTarget = null;
    }

    for (var i in L.Draggable.MOVE) {
      L.DomEvent
          .off(document, L.Draggable.MOVE[i], this._onMove, this)
          .off(document, L.Draggable.END[i], this._onUp, this);
    }

    L.DomUtil.enableImageDrag();
    L.DomUtil.enableTextSelection();

    if (this._moved && this._moving) {
      // ensure drag is not fired after dragend
      L.Util.cancelAnimFrame(this._animRequest);

      this.fire('dragend', {
        distance: this._newPos.distanceTo(this._startPos)
      });
    }

    this._moving = false;
  }
});