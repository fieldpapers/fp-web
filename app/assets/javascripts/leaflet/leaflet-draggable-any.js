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
    var that = this;
    L.DraggableAny.START.forEach(function(e){
      L.DomEvent.on(that._dragStartTarget, e, that._onDown, that);
    });

    this._enabled = true;
  },

  disable: function () {
    if (!this._enabled) { return; }

    var that = this;
    L.DraggableAny.START.forEach(function(e){
      L.DomEvent.off(that._dragStartTarget, e, that._onDown, that);
    });

    this._enabled = false;
    this._moved = false;
  },

  _onDown: function (e) {
    this._moved = false;

    if (e.shiftKey || ((e.which !== 1) && (e.button !== 1) && !e.touches)) { return; }

    L.DomEvent.stopPropagation(e);

    // disable map dragging while dragging tool
    try {
      this._context.map.dragging.disable();
    } catch(e) {}


    if (this._preventOutline) {
      L.DomUtil.preventOutline(this._element);
    }

    if (L.DomUtil.hasClass(this._element, 'leaflet-zoom-anim')) { return; }

    L.DomUtil.disableImageDrag();
    L.DomUtil.disableTextSelection();

    if (this._moving) { return; }

    this.fire('down');

    var first = e.touches ? e.touches[0] : e;

    this._startPoint = new L.Point(first.clientX, first.clientY);
    this._startPos = this._newPos = this.getPosition.call(this._context);

    L.DomEvent
        .on(document, L.DraggableAny.MOVE[e.type], this._onMove, this)
        .on(document, L.DraggableAny.END[e.type], this._onUp, this);

    L.DomEvent.preventDefault(e);
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
      this._startPos = this.getPosition.call(this._context).subtract(offset);

      L.DomUtil.addClass(document.body, 'leaflet-dragging');

      this._lastTarget = e.target || e.srcElement;
      L.DomUtil.addClass(this._lastTarget, 'leaflet-drag-target');
    }

    this._newPos = this._startPos.add(offset);
    this._offset = this._prevPos ? this._newPos.subtract(this._prevPos) : offset;
    this._prevPos = this._newPos.clone();

    this._moving = true;

    L.Util.cancelAnimFrame(this._animRequest);
    this._lastEvent = e;
    this._animRequest = L.Util.requestAnimFrame(this._updatePosition, this, true, this._dragStartTarget);
  },

  _updatePosition: function () {
    var e = {originalEvent: this._lastEvent};
    this.fire('predrag', e);
    this.setPosition.call(this._context, this._newPos, this._offset);
    this.fire('drag', e);
  },

  _onUp: function () {
    L.DomUtil.removeClass(document.body, 'leaflet-dragging');

    if (this._lastTarget) {
      L.DomUtil.removeClass(this._lastTarget, 'leaflet-drag-target');
      this._lastTarget = null;
    }

    for (var i in L.DraggableAny.MOVE) {
      L.DomEvent
          .off(document, L.DraggableAny.MOVE[i], this._onMove, this)
          .off(document, L.DraggableAny.END[i], this._onUp, this);
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

    // re-enable map dragging
    if(this._context.map.options.dragging) {
      try {
        this._context.map.dragging.enable();
      } catch(e){}
    }

    this._moving = false;
  }
});