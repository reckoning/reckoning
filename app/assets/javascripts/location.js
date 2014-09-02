$(document).on('page:load', function() {
  Location.init();
});

$(document).on('ready', function() {
  Location.init();
});

window.Location.init = function() {
  if ($('#location') !== undefined) {
    Location.get();
    interval = setInterval(Location.get, 5000);
  }
};

window.Location.get = function() {
  navigator.geolocation.getCurrentPosition(Location.add);
};

window.Location.add = function(location) {
  $('#location').prepend('<div>' + moment().format('h:mm:ss') + ' - ' + location.coords.latitude + ', ' + location.coords.longitude + ', ' + location.coords.accuracy + '</div>')
};