$ ->
  if $('#welcome').length
    $('.thumbnail').click (ev) ->
      image = $(@).attr 'href'
      headline = $(@).parent().find('h4').text()
      $modal = $('#image-modal')
      $modal.find('.modal-header h4').text headline
      $modal.find('.modal-body img').attr 'src', image
      $modal.modal('show')
      ev.preventDefault()
