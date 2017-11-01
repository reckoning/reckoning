window.displayNoty = (text, type, timeout = 3000) ->
  noty
    text: text
    type: type
    timeout: timeout
    layout: 'topRight'
    theme: 'metroui'
    animation:
      open: 'animated bounceInRight'
      close: 'animated bounceOutRight'
      easing: 'swing'
      speed: 500
    progressBar: true

window.confirm = (message, okCallback, cancelCallback) ->
  okButton =
    addClass: 'btn btn-primary'
    text: I18n.t('actions.ok')
    onClick: ($noty) ->
      $noty.close()
      if okCallback isnt undefined && _.isFunction(okCallback)
        okCallback()
      return false

  cancelButton =
    addClass: 'btn btn-danger'
    text: I18n.t('actions.cancel')
    onClick: ($noty) ->
      $noty.close()
      if cancelCallback isnt undefined && _.isFunction(cancelCallback)
        cancelCallBack()
      return false

  noty
    text: message
    buttons: [okButton, cancelButton]
    layout: 'bottom'
    theme: 'metroui'
    animation:
      open: 'animated fadeInUp'
      close: 'animated fadeOutDown'
      easing: 'swing'
      speed: 500

window.displayConfirm = (ev, $element) ->
  okButton =
    addClass: 'btn btn-primary'
    text: I18n.t('actions.ok')
    onClick: ($noty) ->
      $noty.close()
      if $element.data('method') is undefined
        window.location = $element.attr('href')
      else
        fetch $element.attr('href'),
          method: $element.data('method')
          headers: ApiHeaders
        .then (response) ->
          if $element.data('redirect') is undefined
            window.location.reload()
          else
            window.location = $element.data('redirect')
      return false

  cancelButton =
    addClass: 'btn btn-danger'
    text: I18n.t('actions.cancel')
    onClick: ($noty) ->
      $noty.close()
      return false

  noty
    text: $element.data('notyconfirm')
    buttons: [okButton, cancelButton]
    layout: 'bottom'
    theme: 'metroui'
    animation:
      open: 'animated fadeInUp'
      close: 'animated fadeOutDown'
      easing: 'swing'
      speed: 500

window.displaySuccess = (text, timeout) ->
  displayNoty(text, 'success', timeout)

window.displayAlert = (text, timeout) ->
  displayNoty(text, 'alert', timeout)

window.displayWarning = (text, timeout) ->
  displayNoty(text, 'warning', timeout)

window.displayInfo = (text, timeout) ->
  displayNoty(text, 'information', timeout)

window.displayError = (text, timeout) ->
  timeout = false if timeout is undefined
  displayNoty(text, 'error', timeout)

document.addEventListener "turbolinks:load", () ->
  $("[data-notyConfirm]").click (ev) ->
    displayConfirm(ev, $(@))
    return false

  success = $('body').data('success');
  displaySuccess(success) if success

  info = $('body').data('info')
  displayInfo(info) if info

  alert = $('body').data('alert')
  displayAlert(alert) if alert

  warning = $('body').data('warning')
  displayWarning(warning) if warning

  error = $('body').data('error')
  displayError(error) if error
