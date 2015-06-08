window.App.SignIn =
  showOtpField: ($element) ->
    $parent = $element.parent()
    $parent.hide()
    $parent.next().fadeIn()

