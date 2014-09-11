// Selectize
window.selectizeCreateTemplate = function(data, escape) {
  return '<div class="create"><strong>' + escape(data.input) + '</strong>&hellip; ' + I18n.t("actions.create") + '</div>';
};

// Noty
window.displayNoty = function(text, timeout, type) {
  noty({
    text: text,
    timeout: timeout,
    type: type,
    layout: 'bottomRight'
  });
};

window.displayConfirm = function(ev, $element) {
  var okButton = {
    addClass: 'btn btn-primary',
    text: I18n.t('actions.ok'),
    onClick: function($noty) {
      $noty.close();
      if ($element.data('method') === undefined) {
        Turbolinks.visit($element.attr('href'));
      } else {
        $.ajax({
          url: $element.attr('href'),
          method: $element.data('method'),
          complete: function(result) {
            Turbolinks.visit(window.location);
          }
        });
      }
      return false;
    }
  };

  var cancelButton = {
    addClass: 'btn btn-danger',
    text: I18n.t('actions.cancel'),
    onClick: function($noty) {
      $noty.close();
      return false;
    }
  };

  noty({
    text: $element.data('notyconfirm'),
    buttons: [okButton, cancelButton],
    type: 'warning',
    layout: 'top'
  });
};

window.displaySuccess = function(text, timeout) {
  if (timeout === undefined) {
    timeout = 3000;
  }
  displayNoty(text, timeout, 'success');
};

window.displayNotice = function(text, timeout) {
  if (timeout === undefined) {
    timeout = 3000;
  }
  displayNoty(text, timeout, 'alert');
};

window.displayAlert = function(text, timeout) {
  if (timeout === undefined) {
    timeout = 3000;
  }
  displayNoty(text, timeout, 'error');
};

window.displayError = function(text, timeout) {
  if (timeout === undefined) {
    timeout = false;
  }
  displayNoty(text, timeout, 'error');
};

window.displayWarning = function(text, timeout) {
  if (timeout === undefined) {
    timeout = false;
  }
  displayNoty(text, timeout, 'warning');
};

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