window.showTab = function(hash, popped) {
  if (popped === undefined) {
    popped = false;
  }

  if (hash) {
    $('.nav-tabs a[href=' + hash + ']').tab('show');
  }
  else {
    $('.nav-tabs a:first').tab('show');
  }

  if (!popped) {
    console.log('push');
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
  showTab($('.nav-tabs a:first').attr('href'));
};

$(document).on('page:load', function() {
  tabsLoad()
});

$(document).on('ready', function() {
  tabsLoad()
});