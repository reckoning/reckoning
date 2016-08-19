window.App ?= {}

$(document).on 'click', 'a.disabled', (ev) ->
  ev.preventDefault()

$(document).on 'click', 'code[data-target]', (ev) ->
  $element = $(ev.target)
  $target = $($element.data('target'))
  $target.val($target.val() + $element.text())

$(document).ajaxSend (event, jqxhr, settings) ->
  jqxhr.setRequestHeader 'Authorization', "Token token=\"#{AuthToken}\""

document.addEventListener 'keydown', (e) ->
  return true if $('form') is undefined
  if navigator.platform.match("Mac")
    superKeyPressed = e.metaKey
  else
    superKeyPressed = e.ctrlKey
  if e.keyCode == 83 && superKeyPressed
    e.preventDefault()
    $('form:first').submit()
, false

document.addEventListener "turbolinks:load", ->
  $('select.js-selectize').selectize()

  $('select.js-expense-selectize').selectize
    render:
      option_create: selectizeCreateTemplate
    create: (input, callback) ->
      xhr.abort() if xhr
      xhr = $.ajax
        url: ApiBasePath + Routes.v1_expense_types_path()
        data: {name: input}
        method: 'POST'
        dataType: 'json'
        success: (result) =>
          data = {
            value: result.uuid,
            text: result.name
          }
          @addOption data
          @addItem result.uuid
          callback data
        error: ->
          callback()

  $('select.js-customer-selectize').selectize
    render:
      option_create: selectizeCreateTemplate
    create: (input, callback) ->
      xhr.abort() if xhr
      xhr = $.ajax
        url: ApiBasePath + Routes.v1_customers_path()
        data: {name: input}
        method: 'POST'
        dataType: 'json'
        success: (result) =>
          data = {
            value: result.uuid,
            text: result.name
          }
          @addOption data
          @addItem result.uuid
          callback data
        error: ->
          callback()

  $('select.js-manufacturer-selectize').selectize
    render:
      option_create: selectizeCreateTemplate
    create: true

  $('[data-toggle=tooltip]').tooltip()

  I18nHelper.init()
  initMoment()
  initAccounting()
