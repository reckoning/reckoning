// Noty
window.displayNoty = function(text, timeout, type) {
  noty({
    text: text,
    timeout: timeout,
    type: type,
    layout: 'bottom',
    theme: 'bootstrapTheme',
    animation: {
      open: 'animated fadeInUp',
      close: 'animated fadeOutDown',
      easing: 'swing',
      speed: 500
    }
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
            if ($element.data('redirect') === undefined) {
              Turbolinks.visit(window.location);
            } else {
              Turbolinks.visit($element.data('redirect'));
              // hack to show message
              response = result.responseJSON;
              if (response.message !== undefined) {
                setTimeout(function() {
                  displaySuccess(response.message);
                }, 500);
              }
            }
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
    layout: 'bottom',
    theme: 'bootstrapTheme',
    animation: {
      open: 'animated fadeInUp',
      close: 'animated fadeOutDown',
      easing: 'swing',
      speed: 500
    }
  });
};

window.displaySuccess = function(text, timeout) {
  if (timeout === undefined) {
    timeout = 3000;
  }
  displayNoty(text, timeout, 'success');
};

window.displayInfo = function(text, timeout) {
  if (timeout === undefined) {
    timeout = 3000;
  }
  displayNoty(text, timeout, 'info');
};

window.displayAlert = function(text, timeout) {
  if (timeout === undefined) {
    timeout = false;
  }
  displayNoty(text, timeout, 'alert');
};

window.displayError = function(text, timeout) {
  if (timeout === undefined) {
    timeout = false;
  }
  displayNoty(text, timeout, 'error');
};

$(function() {
  var success = $('body').data('success');
  if (success) {
    displaySuccess(success);
  }

  var info = $('body').data('info');
  if (info) {
    displayAlert(info);
  }

  var error = $('body').data('error');
  if (error) {
    displayError(error);
  }

  var alert = $('body').data('alert');
  if (alert) {
    displayAlert(alert);
  }
});
