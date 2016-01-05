// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require selectize
//= require leaflet
//= require s3_direct_upload
//= requite mapbox.js
//= require_directory ./fp
//= require turbolinks
//= require_tree .

(function(exports){
  "use strict";

  var FP = exports.FP || (exports.FP = {});

  // required both by atlases and snapshots;
  // therefore, this logic is in application.js
  FP.setUpJOSMClickHandler = function (errorMsg) {

    // handle JOSM link click with all required HTTP requests
    var josmLink = document.querySelector('#josm_link');
    josmLink.addEventListener('click', function (event) {
      var dataRequestURL = event.currentTarget.dataset.dataRequest,
        tileRequestURL = event.currentTarget.dataset.tileRequest;

      if (!dataRequestURL) { return; }

      var errorHandler = function (errorEvent) {
        window.alert(errorMsg);
      };

      // fire XHRs in sequence:
      // first the data request,
      // then the tile request.
      var dataRequest = new XMLHttpRequest();
      dataRequest.addEventListener("error", errorHandler);
      dataRequest.addEventListener("load", function (loadEvent) {
        var tileRequest = new XMLHttpRequest();
        tileRequest.addEventListener("error", errorHandler);
        tileRequest.open("GET", tileRequestURL);
        tileRequest.send();
      });

      dataRequest.open("GET", dataRequestURL);
      dataRequest.send();
    });

  };

})(this);
