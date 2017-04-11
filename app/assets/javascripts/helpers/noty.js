// Noty
window.displayNoty = function(text, type, timeout = 3000) {
  noty({
    text: text,
    type: type,
    timeout: timeout,
    layout: 'topRight',
    theme: 'metroui',
    animation: {
      open: 'animated bounceInRight',
      close: 'animated bounceOutRight',
      easing: 'swing',
      speed: 500
    },
    progressBar: true
  });
};

window.confirm = function(message, okCallback, cancelCallback) {
  var okButton = {
    addClass: 'btn btn-primary',
    text: I18n.t('actions.ok'),
    onClick: function($noty) {
      $noty.close();
      if (okCallback !== undefined && _.isFunction(okCallback)) {
        okCallback();
      }
      return false;
    }
  };

  var cancelButton = {
    addClass: 'btn btn-danger',
    text: I18n.t('actions.cancel'),
    onClick: function($noty) {
      $noty.close();
      if (cancelCallback !== undefined && _.isFunction(cancelCallback)) {
        cancelCallBack();
      }
      return false;
    }
  };

  noty({
    text: message,
    buttons: [okButton, cancelButton],
    layout: 'bottom',
    theme: 'metroui',
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
        window.location = $element.attr('href');
      } else {
        console.log($element.data('method'));
        $.ajax({
          url: $element.attr('href'),
          method: $element.data('method'),
          complete: function(result) {
            if ($element.data('redirect') === undefined) {
              window.location.reload();
            } else {
              window.location = $element.data('redirect');
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
    layout: 'bottom',
    theme: 'metroui',
    animation: {
      open: 'animated fadeInUp',
      close: 'animated fadeOutDown',
      easing: 'swing',
      speed: 500
    }
  });
};

window.displaySuccess = function(text, timeout) {
  displayNoty(text, 'success', timeout);
};

window.displayAlert = function(text, timeout) {
  displayNoty(text, 'alert', timeout);
};

window.displayWarning = function(text, timeout) {
  displayNoty(text, 'warning', timeout);
};

window.displayInfo = function(text, timeout) {
  displayNoty(text, 'information', timeout);
};

window.displayError = function(text, timeout) {
  if (timeout === undefined) {
    timeout = false;
  }
  displayNoty(text, 'error', timeout);
};

document.addEventListener("turbolinks:load", function() {
  $("[data-notyConfirm]").click(function(ev) {
    displayConfirm(ev, $(this));
    return false;
  });

  var success = $('body').data('success');
  if (success) {
    displaySuccess(success);
  }

  var info = $('body').data('info');
  if (info) {
    displayInfo(info);
  }

  var alert = $('body').data('alert');
  if (alert) {
    displayAlert(alert);
  }

  var warning = $('body').data('warning');
  if (warning) {
    displayWarning(warning);
  }

  var error = $('body').data('error');
  if (error) {
    displayError(error);
  }
});
