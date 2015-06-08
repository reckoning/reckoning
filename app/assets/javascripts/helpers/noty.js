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

window.displayAlert = function(text, timeout) {
  if (timeout === undefined) {
    timeout = 3000;
  }
  displayNoty(text, timeout, 'warning');
};

window.displayInfo = function(text, timeout) {
  if (timeout === undefined) {
    timeout = 3000;
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
    displayAlert(info);
  }

  var error = $('body').data('error');
  if (error) {
    displayError(error);
  }
});
