window.GeoLocation =
  laddaButton: null
  form: null
  success: (position) ->
    { latitude, longitude } = position.coords
    $form = $(GeoLocation.form)
    console.log(GeoLocation.form)
    console.log($form.find("[name*='latitude']"))
    $form.find("[name*='latitude']").val(latitude)
    $form.find("[name*='longitude']").val(longitude)
    GeoLocation.getLocation(latitude, longitude)

  error: (err) ->
    GeoLocation.laddaButton.stop()
    displayError(err)

  getLocation: (latitude, longitude) ->
    geocoder = new google.maps.Geocoder()
    latlng = new google.maps.LatLng(latitude, longitude)

    geocoder.geocode
      latLng: latlng
    , (results, status) ->
      displayInfo("Position gefunden!")
      $form = $(GeoLocation.form)
      $form.find("[name*='location']").val(results[0].formatted_address)
      GeoLocation.laddaButton.stop()

$(document).on 'click', '[data-geolocation]', (ev) ->
  ev.preventDefault()
  GeoLocation.laddaButton = Ladda.create($(ev.target)[0])
  GeoLocation.laddaButton.start()
  GeoLocation.form = $(ev.target).attr('data-form')

  displayInfo("Suche nach Position...")
  if !navigator
    displayError('foo')
    GeoLocation.laddaButton.stop()
  else
    navigator.geolocation.getCurrentPosition(
      GeoLocation.success, GeoLocation.error
    )
