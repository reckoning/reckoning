# Selectize
window.selectizeCreateTemplate = (data, escape) ->
  return "<div class='create'><strong>#{escape(data.input)}</strong>&hellip; #{I18n.t("actions.create")}</div>"

# Noty
window.displayNoty = (text, timeout, type) ->
  noty
    text: text,
    timeout: timeout,
    type: type,
    layout: 'bottomRight'

window.displayConfirm = (ev, $element) ->
  okButton =
    addClass: 'btn btn-primary'
    text: I18n.t('actions.ok')
    onClick: ($noty) ->
      $noty.close()
      if $element.data('method') is undefined
        Turbolinks.visit($element.attr('href'))
      else
        $.ajax
          url: $element.attr('href')
          method: $element.data('method')
          complete: (result) ->
            Turbolinks.visit(window.location)
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
    type: 'warning'
    layout: 'top'

window.displaySuccess = (text, timeout = 3000) ->
  displayNoty text, timeout, 'success'

window.displayAlert = (text, timeout = 3000) ->
  displayNoty text, timeout, 'alert'

window.displayError = (text, timeout = false) ->
  displayNoty text, timeout, 'error'

window.displayWarning = (text, timeout = false) ->
  displayNoty text, timeout, 'warning'

window.toggleCheckbox = ($element) ->
  target = $element.data('target')
  activeClass = $element.data('activeclass')
  $checkbox = $(target) unless target is undefined
  $checkbox ||= $element.find('input[type=checkbox]')
  $element.toggleClass(activeClass) unless activeClass is undefined
  $checkbox.prop("checked", !$checkbox.prop("checked"))

window.pad = (d) ->
  return if (d < 10) then '0' + d.toString() else d.toString()

window.timeToDecimal = (val) ->
  parts = val.split(':')
  time = parseInt(parts[0], 10) + (parseInt(parts[1], 10) / 60)
  parseFloat(time)

window.decimalToTime = (val) ->
  hours = Math.floor(val)
  minutes = Math.round((val % 1) * 60)

  if hours isnt 0 || minutes isnt 0
    return "#{hours}:#{pad(minutes)}"

$ ->
  $("[data-notyConfirm]").click (ev) ->
    displayConfirm ev, $(@)
    return false
