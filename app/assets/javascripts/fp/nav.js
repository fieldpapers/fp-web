/*
  Javascript for nav menu
 */

(function(exports){
  "use strict";

  var FP = exports.FP || (exports.FP = {});

  FP.nav = function() {
    var navBar = document.getElementById('nav'),
        menuToggle = document.getElementById('nav-toggle');

    if (!navBar || !menuToggle) return;

    menuToggle.onclick = function(evt) {
      if (navBar) {
        navBar.className = (navBar.className === 'open') ? '' : 'open';
      }
    };
  };


})(this);