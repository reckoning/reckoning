window.App ?= {}

$(document).on 'click', 'a.disabled', (ev) ->
  ev.preventDefault()

$(document).on 'click', 'code[data-target]', (ev) ->
  $element = $(ev.target)
  $target = $($element.data('target'))
  $target.val($target.val() + $element.text())

$(document).ajaxSend (event, jqxhr, settings) ->
  jqxhr.setRequestHeader 'Authorization', "Token token=\"#{AuthToken}\""

$ ->
  $('select.js-selectize').selectize()

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

  $('[data-toggle=tooltip]').tooltip()

  initMoment()
  initAccounting()
