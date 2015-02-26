(function(exports){
  var FIELDPAPERS = {
    common: {
      init: function() {
        // initialize nav
        //FP.nav();
      }
    },

    atlases: {
      init: function() {
        // controller-wide code
      },

      index: function() {

      }
    }
  };

  UTIL = {
    exec: function( controller, action ) {
      var ns = FIELDPAPERS,
          action = ( action === undefined ) ? 'init' : action;

      if ( controller !== '' && ns[controller] && typeof ns[controller][action] == 'function' ) {
        ns[controller][action]();
      }
    },

    init: function() {
      console.log("BOOTSTRAP>>>>>");
      var body = document.body,
          controller = body.getAttribute( 'data-controller' ),
          action = body.getAttribute( 'data-action' );

      UTIL.exec( 'common' );
      UTIL.exec( controller );
      UTIL.exec( controller, action );
    }
  };

  $(function() {
    UTIL.init();
  });
})(this);
