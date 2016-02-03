// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

(function(exports){
  "use strict";

  var FP = exports.FP || (exports.FP = {});

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