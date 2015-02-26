// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(function() {
  $("#s3_uploader").S3Uploader(
    {
      remove_completed_progress_bar: false,
      progress_bar_target: $("#uploads_container")
    }
  );

  $("#s3_uploader").bind("s3_upload_failed", function(e, content) {
    //return alert(content.filename + " failed to upload");
    $('#uploads_container').addClass('error');
    $('#uploads_container h5').text( content.filename + " failed to upload" );
  });

  $("#s3_uploader").bind("s3_uploads_start", function(e, content) {
    $('#uploads_container').addClass('active');

    $("#upload-close-btn").off('click').on('click', function(){
      $('#uploads_container').removeClass('active');
      $('#uploads_container').removeClass('error');
    });

  });


});
