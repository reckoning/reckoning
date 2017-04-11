class App.GeoLocation
  laddaButton: null
  form: null
  constructor: ($target) ->
    @laddaButton = Ladda.create($target[0])
    @laddaButton.start()
    @form = $target.attr('data-form')

  start: ->
    displayInfo('Suche nach Position...')
    if !navigator
      displayError('Es ist ein Fehler aufgetreten.')
      @laddaButton.stop()
    else
      navigator.geolocation.getCurrentPosition(
        @success, @error
      )

  success: (position) ->
    { latitude, longitude } = position.coords
    $form = $(@form)
    $form.find("[name*='latitude']").val(latitude)
    $form.find("[name*='longitude']").val(longitude)
    @getLocation(latitude, longitude)

  error: (err) ->
    @laddaButton.stop()
    displayError(err)

  getLocation: (latitude, longitude) ->
    geocoder = new google.maps.Geocoder()
    latlng = new google.maps.LatLng(latitude, longitude)

    geocoder.geocode
      latLng: latlng
    , (results, status) ->
      displayInfo('Position gefunden!')
      $form = $(@form)
      $form.find("[name*='location']").val(results[0].formatted_address)
      @laddaButton.stop()
