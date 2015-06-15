//= require jquery
//= require jquery_ujs
//= require js-routes
//= require spin.js/spin
//= require ladda/js/ladda
//= require noty
//= require sifter
//= require microplugin
//= require selectize
//= require bootstrap
//= require dynamic_fields_for
//= require i18n
//= require i18n/translations
//= require moment/moment
//= require moment-init
//= require twix/bin/twix
//= require d3
//= require nvd3
//= require accounting/accounting
//= require nprogress
//= require fastclick
//= require pdf.js/build/pdf
//= require pdf-viewer
//= require helper
//= require_tree ./helpers
//= require tabs
//= require app
//= require_tree ./helpers
//= require_tree ./app
//= require angular-init
//= require base
//= require blank
//= require timesheet

window.ApiBasePath = "//api." + window.location.host;

$(document).on('show.bs.collapse', '.navbar-collapse', function() {
  $('.navbar-collapse.in').not(this).collapse('hide');
});

$(function() {
  FastClick.attach(document.body);

  $('.btn.btn-loading').click(function() {
    $(this).button('loading');
  });
});

if (("standalone" in window.navigator) && window.navigator.standalone) {
  var noddy, remotes = false;

  document.addEventListener('click', function(event) {
    noddy = event.target;

    while(noddy.nodeName !== "A" && noddy.nodeName !== "HTML") {
      noddy = noddy.parentNode;
    }

    if('href' in noddy && noddy.href.indexOf('http') !== -1 && (noddy.href.indexOf(document.location.host) !== -1 || remotes)) {
      event.preventDefault();
      document.location.href = noddy.href;
    }

  }, false);
}
