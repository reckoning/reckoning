window.toggleCheckbox = function($element) {
  var target = $element.data('target');
  var activeClass = $element.data('activeclass');
  var $checkbox;
  if (target !== undefined) {
    $checkbox = $(target);
  } else {
    $checkbox = $element.find('input[type=checkbox]');
  }
  if (activeClass !== undefined) {
    $element.toggleClass(activeClass);
  }
  $checkbox.prop("checked", !$checkbox.prop("checked"));
};

window.pad = function(d) {
  if (d < 10) {
    return '0' + d.toString();
  } else {
    return d.toString();
  }
};

window.timeToDecimal = function(val) {
  var parts = val.split(':');
  var time = parseInt(parts[0], 10) + (parseInt(parts[1], 10) / 60);
  return parseFloat(time);
};

window.decimalToTime = function(val) {
  var hours = Math.floor(val);
  var minutes = Math.round((val % 1) * 60);

  if (hours !== 0 || minutes !== 0) {
    return hours + ':' + pad(minutes);
  } else {
    return '0:00';
  }
};

$(function() {
  $("[data-notyConfirm]").click(function(ev) {
    displayConfirm(ev, $(this));
    return false;
  });
});
