/*
Javascript for accordion menu on /compose
*/

$(document).on('page:change', function(){
    $(function(){
        $('select#atlas_provider').selectize({
            create: true,
            sortField: 'text'
        });
    });

    $('#atlas_layout').change(function(){
      if ($('#atlas_layout').prop('checked')) {
        $('.notes-textarea').addClass('notes-textarea-visible');
      } else {
        $('.notes-textarea').removeClass('notes-textarea-visible');
      }
    });
});
