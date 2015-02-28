#= require underscore
#= require angular
#= require angular-route
#= require angular-timer
#= require angular-animate
#= require_self
#
#= require timesheet/app
#= require timesheet/routes
#= require_tree ./timesheet

$ ->
  $('.btn.date').datepicker
    todayBtn: "linked"
    clearBtn: true
    language: I18n.locale
    autoclose: true
    todayHighlight: true
