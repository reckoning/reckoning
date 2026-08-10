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

# Callback-based confirm dialog. Deliberately NOT `window.confirm`:
# this returns the noty object immediately instead of blocking, so
# overriding the native one silently defeated every caller written as
# `if (!confirm(msg)) return` — the action ran while the dialog was
# still on screen. `app/frontend/lib/confirm.ts` wraps this in a
# promise for the Vue islands.
window.notyConfirm = (message, okCallback, cancelCallback) ->
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
        cancelCallback()
      return false

  noty
    text: message
    buttons: [okButton, cancelButton]
    layout: 'bottom'
    theme: 'metroui'
    # Only the buttons dismiss this dialog. noty's default
    # `closeWith: ['click']` let a click anywhere on the bar close it
    # without running either callback, which leaves a promise-wrapped
    # caller waiting forever.
    closeWith: []
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

# Delegated so the handler keeps working when Turbo Frame swaps in
# new [data-notyConfirm] elements (e.g. project archive button after
# a pagination/filter navigation). Bound once at script load — the
# document survives both Turbo Drive and Turbo Frame navigations.
#
# Capture phase (the trailing `true`) is load-bearing: jquery_ujs is
# required in application.js long before this file, so its delegated
# `a[data-method]` handler sits on `document` *ahead* of us in bubble
# order and would fire the DELETE/PUT request the instant you click —
# before the confirm dialog is answered. Capturing on document runs
# first of everything; stopImmediatePropagation then blocks both
# jquery_ujs and Turbo, and we drive the confirm ourselves (the
# request is issued from displayConfirm's OK callback).
document.addEventListener "click", (ev) ->
  el = ev.target?.closest?("[data-notyConfirm]")
  return unless el
  ev.preventDefault()
  ev.stopImmediatePropagation()
  displayConfirm(ev, $(el))
, true

document.addEventListener "turbolinks:load", () ->
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
