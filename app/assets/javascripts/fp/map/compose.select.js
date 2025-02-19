(function(exports){
  "use strict";

  var FP = exports.FP || (exports.FP = {});
  var Map = FP.map || (FP.map = {});
  var compose = Map.compose || (FP.map.compose = {});


  compose.select = function(settings) {
    // copy min/max zoom into Leaflet options
    Object.keys(settings.tileProviders).forEach(function(k) {
      var p = settings.tileProviders[k];
      p.options = p.options || {};
      p.options.minZoom = p.minzoom;
      p.options.maxZoom = p.maxzoom;
    });

    var __ = {};

    var intitle = paramByName('title'), intext = paramByName('text');
    var inlat = paramByName('lat'), inlon = paramByName('lon');
    var inzoom = paramByName('zoom'), inprovider = paramByName('provider');
    var has_center = false, center;
    var cook = document.cookie.split('; ');
    if (!inlat && !inlon) {
      for (var i in cook) {
        var cs = cook[i].split('=');
        if (cs[0] == 'center') {
          var vs = cs[1].split(':');
          settings.initialView[0][0] = vs[0];
          settings.initialView[0][1] = vs[1];
          settings.initialView[1] = vs[2];
          has_center = true;
          break;
        }
      }
    }
    if (!has_center) {
      if (inlat) settings.initialView[0][0] = inlat;
      if (inlon) settings.initialView[0][1] = inlon;
      if (inzoom) settings.initialView[1] = inzoom;
    }
    if (inprovider) {
      if (!FP.map.utils.isTemplateString(inprovider))
        console.log('Invalid tile provider passed in URL!');
      else {
        var found = false;
        for (var p in settings.tileProviders)
          if (inprovider == settings.tileProviders[p].template) {
            settings.defaultProvider = p;
            found = true;
            break;
          }
        if (!found) {
          var new_provider = {
            label: 'User-provided',
            template: inprovider,
          };
          settings.tileProviders['userdefined'] = new_provider;
          settings.defaultProvider = 'userdefined';
        }
      }
    }

    var tileProviders = settings.tileProviders,
        defaultProviderLabel = settings.defaultProvider,
        tileLayer,
        utmGridLayer,
        map,
        pageComposer,
        zoomControls,
        lastTemplate,
        templateSelector;

    // create map
    map = L.map(settings.selector,
      L.Util.extend(FP.map.options, {
        center: settings.initialView[0],
        zoom: settings.initialView[1]
      })
    );

    // turn on leaflet-hash
    new L.Hash(map);

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
        atlasOrientation = $('#atlas_orientation'),
        atlasTitle = $('#atlas_title'),
        atlasText = $('#atlas_text'),
        // atlasUTMGrid = $('#atlas_utm_grid'),
        atlasTitlePlaceHolder = $("#atlas-title-placeholder-text");

    if (intitle) atlasTitle.val(intitle);
    if (atlasTitle.val() === "Untitled") atlasTitle.val("");
    $('#atlas_title').attr("placeholder",atlasTitlePlaceHolder.text().trim());

    if (intext) atlasText.val(intext);

    // set tileLayer
    if (defaultProviderLabel == 'userdefined')
      atlasProvider.append('<option value="' +
                           tileProviders[defaultProviderLabel].template +
                           '">User-provided</option>');
    validateTileLayer(tileProviders[defaultProviderLabel].template);
    atlasProvider.val(tileProviders[defaultProviderLabel].template);

    // scale tool
    L.control.scale().addTo(map);

    // Area selection tool
    pageComposer = L.pageComposer({width:200, height:300});
    pageComposer.addTo(map);

    // Form listeners
    pageComposer.on('change', function(e){
      var pages = pageComposer.getPages();
      var bds = pageComposer.getPinnedBounds();

      var center = map.getCenter();
      document.cookie = 'center=' + center.lat + ':' + center.lng + ':' +
                        map.getZoom() + ' ; max-age=2592000';

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
    /*
    atlasUTMGrid.on('change', function() {
      var utmGridTemplate = 'https://tile.stamen.com/utm/{z}/{x}/{y}.png';
      if (atlasUTMGrid.prop('checked')) {
        if (!utmGridLayer) {
          utmGridLayer = L.tileLayer(FP.map.utils.conformTemplate(utmGridTemplate), {})
        }
        map.addLayer(utmGridLayer);
      } else {
        map.removeLayer(utmGridLayer);
      }
    });
    */

    // sync up the fields
    map.fire("move");
    atlasOrientation.change();
    atlasPaperSize.change();
    atlasProvider.change();

    function paramByName(name) {
      var match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search);
      return match && decodeURIComponent(match[1].replace(/\+/g, ' '));
    }

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
        return false;
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
