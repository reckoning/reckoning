//= require jquery
//= require jquery_ujs
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
//= require moment_init
//= require twix/bin/twix
//= require d3
//= require nvd3
//= require accounting/accounting
//= require nprogress
//= require fastclick
//= require bootstrap-datepicker
//= require pdf.js/build/pdf
//= require pdf_viewer
//= require helper
//= require_tree ./helpers
//= require tabs
//= require app
//= require_tree ./helpers
//= require_tree ./app
//= require timesheet

$(document).on('page:fetch',   function() { NProgress.start(); });
$(document).on('page:change',  function() { NProgress.done(); });
$(document).on('page:restore', function() { NProgress.remove(); });

$(document).on('show.bs.collapse', '.navbar-collapse', function() {
  $('.navbar-collapse.in').not(this).collapse('hide');
});

$(function() {
  FastClick.attach(document.body);

  $('input[type=date], .input-group.date').datepicker({
    todayBtn: "linked",
    clearBtn: true,
    language: I18n.locale,
    autoclose: true,
    todayHighlight: true
  });

  $('.btn.btn-loading').click(function() {
    $(this).button('loading');
  });
});
