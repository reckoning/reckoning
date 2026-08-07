$ ->
  $(document).off 'click', 'form .remove_fields'
  $(document).off 'click', 'form .add_fields'

  $(document).on 'click', 'form .remove_fields', (event) ->
    $deleteField = $(this).prev('input[type=hidden]')
    if $deleteField.length > 0
      $deleteField.val('1')
      $(this).closest('.fields').hide()
    else
      $(this).closest('.fields').remove()
    $(document).trigger('dynamicFieldsFor.remove', @)
    event.preventDefault()

  $(document).on 'click', 'form .add_fields', (event) ->
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $target = $($(@).data('target'))
    fields = $(this).data('fields').replace(regexp, time)
    if $target.length
      $target.append(fields)
    else
      $(this).before(fields)
    $(document).trigger('dynamicFieldsFor.add', @)
    event.preventDefault()
