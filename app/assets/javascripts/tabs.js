window.showTab = function(hash, popped) {
  if (popped === undefined) {
    popped = false;
  }

  if (hash) {
    $('.nav-tabs a[href=' + hash + '], .nav-vertical-tabs a[href=' + hash + ']').tab('show');
    if ($('form').length) {
      $('form input[name=hash]').val(hash)
    }
  } else {
    $('.nav-tabs a:first, .nav-vertical-tabs a:first').tab('show');
  }

  if (!popped) {
    history.pushState(null, null, hash);
  }
};

$(window).on('popstate', function(e) {
  showTab(document.location.hash, true);
});

$(document).on('shown.bs.tab', 'a[data-toggle="tab"]', function(e) {
  showTab(e.target.hash);
});

window.tabsLoad = function() {
  hash = window.location.hash;
  if (hash !== undefined) {
    showTab(hash);
  } else {
    showTab($('.nav-tabs a:first, .nav-vertical-tabs a:first').attr('href'));
  }
};

$(document).on('page:load', function() {
  tabsLoad()
});

$(document).on('ready', function() {
  tabsLoad()
});