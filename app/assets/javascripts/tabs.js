$(document).on('shown.bs.tab', 'a[data-toggle="tab"]', function(e) {
  if ($('form').length) {
    $('form input[name=hash]').val(e.target.hash);
  }
});

$(function() {
  if ($('.nav-tabs a:first, .nav-vertical-tabs a:first').length === 0) {
    return;
  }

  hash = window.location.hash;
  if (hash !== undefined && hash.length > 0 && !(/^#\//).test(hash)) {
    $('.nav-tabs a[href=' + hash + '], .nav-vertical-tabs a[href=' + hash + ']').tab('show');
  }
});
