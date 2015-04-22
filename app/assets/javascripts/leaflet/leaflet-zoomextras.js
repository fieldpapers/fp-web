L.Control.ZoomExtras = L.Control.Zoom.extend({
    options: {
        position: 'topleft',
        zoomInText: '+',
        zoomInTitle: 'Zoom in',
        zoomOutText: '-',
        zoomOutTitle: 'Zoom out',
        extras: [],
        extraMapDisabledEvents:[]
    },

    onAdd: function (map) {
        var zoomName = 'leaflet-control-zoom',
            container = L.DomUtil.create('div', zoomName + ' leaflet-bar'),
            that = this;

        this._map = map;

        this._zoomInButton  = this._createButton(
                this.options.zoomInText, this.options.zoomInTitle,
                zoomName + '-in',  container, this._zoomIn,  this);

        this._zoomOutButton = this._createButton(
                this.options.zoomOutText, this.options.zoomOutTitle,
                zoomName + '-out', container, this._zoomOut, this);

        this.options.extras.forEach(function(btn) {
            btn.instance = that._createButton(btn.text, btn.title, btn.klass, container, function() {return btn.onClick.call(that)},  that);
        });

        this._updateDisabled();

        map.on('zoomend zoomlevelschange', this._updateDisabled, this);

        this.options.extraMapDisabledEvents.forEach(function(evt){
            map.on(evt, that._updateDisabled, that);
        });


        return container;
    },
    onRemove: function (map) {
        map.off('zoomend zoomlevelschange', this._updateDisabled, this);

        var that = this;
        this.options.extraMapDisabledEvents.forEach(function(evt){
            map.off(evt, that._updateDisabled, that);
        });
    },

    _updateDisabled: function () {
        var map = this._map,
            className = 'leaflet-disabled',
            that = this;

        L.DomUtil.removeClass(this._zoomInButton, className);
        L.DomUtil.removeClass(this._zoomOutButton, className);

        if (map._zoom === map.getMinZoom()) {
            L.DomUtil.addClass(this._zoomOutButton, className);
        }
        if (map._zoom === map.getMaxZoom()) {
            L.DomUtil.addClass(this._zoomInButton, className);
        }

        this.options.extras.forEach(function(btn) {
            btn.onDisabled.call(that, btn.instance, className);
        });
    }
});
