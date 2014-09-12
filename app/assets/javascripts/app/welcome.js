$(function() {
  if($('#welcome').length) {
    $('.thumbnail').click(function(ev) {
      var image = $(this).attr('href');
      var headline = $(this).parent().find('h4').text();
      $modal = $('#image-modal');
      $modal.find('.modal-header h4').text(headline);
      $modal.find('.modal-body img').attr('src', image);
      $modal.modal('show');
      ev.preventDefault();
    });
  }
});