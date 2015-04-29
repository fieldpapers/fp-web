(function(exports){
  "use strict";

  var FP = exports.FP || (exports.FP = {});
  var Map = FP.map || (FP.map = {});
  var compose = Map.compose || (FP.map.compose = {});


  compose.select = function(settings) {
    var __ = {};

    var tileProviders = settings.tileProviders,
        defaultProviderLabel = settings.defaultProvider,
        tileLayer,
        map,
        pageComposer,
        zoomControls,
        lastTemplate,
        templateSelector;

    var resetIcon = [
      '<svg version="1.1"'
      ,'xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:a="http://ns.adobe.com/AdobeSVGViewerExtensions/3.0/"'
      ,'x="0px" y="0px" width="18px" height="18px" viewBox="0 0 22 22" enable-background="new 0 0 22 22" xml:space="preserve">'
      ,'<defs>'
      ,'</defs>'
      ,'<path d="M6,2h4V0H6V2z M2,18H0v4h4v-2H2V18z M6,22h4v-2H6V22z M2,12H0v4h2V12z M2,6H0v4h2V6z M0,4h2V2h2V0H0V4z M20,10h2V6h-2V10z M12,22h4v-2h-4V22z M18,0v2h2v2h2V0H18z M20,16h2v-4h-2V16z M20,20h-2v2h4v-4h-2V20z M12,2h4V0h-4V2z M6,16h10V6H6V16z"/>'
      ,'</svg>'
    ].join(" ");

    // create map
    map = L.map(settings.selector,
      L.Util.extend(FP.map.options, {
        zoomControl: false,
        center: settings.initialView[0],
        zoom: settings.initialView[1]
      })
    );

    // set tileLayer
    validateTileLayer(tileProviders[defaultProviderLabel].template);

    // scale tool
    L.control.scale().addTo(map);

    // Area selection tool
    pageComposer = L.pageComposer({width:200, height:300});
    pageComposer.addTo(map);

    // Custom zoom control
    zoomControls = new L.Control.ZoomExtras( {
      position: 'topleft',
      extras: [{
        text: resetIcon,
        title: 'Reset',
        klass: 'zoom-reset',
        onClick: function(){
          var bds = pageComposer.getPinnedBounds();
          map.fitBounds(bds, {animate: false});

        },
        onDisabled: function(btn, className) {
          L.DomUtil.removeClass(btn, className);

          /*
          if(something) { // disable
            L.DomUtil.addClass(btn, className);
          }
          */
        }
      }],
      extraMapDisabledEvents: [] // map events that will trigger an onDisabled check
    }).addTo(map);


    // cache some elements
    var atlasRows = $('#atlas_rows'),
        atlasCols = $('#atlas_cols'),
        atlasZoom = $("#atlas_zoom"),
        atlasWest = $("#atlas_west"),
        atlasSouth = $("#atlas_south"),
        atlasEast = $("#atlas_east"),
        atlasNorth = $("#atlas_north"),
        atlasProvider = $('#atlas_provider'),
        atlasPaperSize = $('#atlas_paper_size'),
        atlasOrientation = $('#atlas_orientation');

    // Form listeners
    pageComposer.on('change', function(e){
      var pages = pageComposer.getPages();
      var bds = pageComposer.getPinnedBounds();

      atlasRows.val( pages.rows );
      atlasCols.val( pages.cols );
      atlasZoom.val( map.getZoom() );
      atlasWest.val( bds.getWest() );
      atlasSouth.val( bds.getSouth() );
      atlasEast.val( bds.getEast() );
      atlasNorth.val( bds.getNorth() );
    });

    atlasOrientation.on('change', function(){
      pageComposer.setOrientation(this.value);
    });

    atlasPaperSize.on('change', function(){
      pageComposer.setPaperSize(this.value);
    });

    atlasProvider.on('change', function(){
      validateTileLayer(this.value);
    });

    templateSelector = atlasProvider.select2({
      tags: true,
      width: "style",
      multiple: false
    });

    // sync up the fields
    map.fire("move");
    atlasOrientation.change();
    atlasPaperSize.change();
    atlasProvider.change();


    function validateTileLayer(template) {
      var provider = Object.keys(tileProviders).map(function(k) {
          return [k, tileProviders[k]];
        }).filter(function(x) {
          return x[1].template === template;
        })[0];

      if (provider) {
        return setTileLayer(provider[1].template, provider[1].options);
      } else {

        if (FP.map.utils.isTemplateString(template)) {
          return setTileLayer(template, {});
        }

        console.error('Not a valid template string.');
        if (lastTemplate && templateSelector) templateSelector.val(lastTemplate);
      }
    }

    // Set the map tile layer
    function setTileLayer(template, options) {
      if (map.hasLayer(tileLayer)) map.removeLayer(tileLayer);
      lastTemplate = template;

      tileLayer = L.tileLayer(FP.map.utils.conformTemplate(template), options || {}).addTo(map);

      return true;
    }

    return __;
  };
})(this);