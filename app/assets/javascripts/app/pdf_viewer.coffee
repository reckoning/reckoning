class App.PDFViewer
  constructor: (@viewer) ->

  init: ->
    @loading()
    @viewer.find('canvas').fadeOut 'slow', ->
      $(@).remove()

    pdfPath = @viewer.data('pdfPath')
    if pdfPath isnt undefined
      PDFJS.getDocument(pdfPath).then (pdf) =>
        @renderPages(pdf)

  renderPage: ($promise, callback) ->
    $promise.then (page) =>
      $canvas = $('<canvas/>')
      $canvas.hide()
      @viewer.append($canvas)

      canvas = $canvas[0]
      context = canvas.getContext('2d')

      viewport = page.getViewport(2.0)
      canvas.height = viewport.height
      canvas.width = viewport.width

      renderContext =
        canvasContext: context
        viewport: viewport

      page.render(renderContext).then ->
        $canvas.fadeIn('slow')
        callback()

  renderPages: (pdf, index = 1) ->
    @renderPage pdf.getPage(index), =>
      index++
      if index <= pdf.pdfInfo.numPages
        @renderPages(pdf, index)
      else
        @finish()

  loading: ->
    $loader = $("<div/>")
    $loader.addClass('loader').hide()
    @viewer.append($loader)
    $loader.fadeIn('slow')

  finish: ->
    @viewer.find('.loader').fadeOut 'slow', ->
      $(@).remove()
