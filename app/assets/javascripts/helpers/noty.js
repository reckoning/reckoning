// Noty
window.displayNoty = function(text, timeout, type) {
  noty({
    text: text,
    timeout: timeout,
    type: type,
    layout: 'bottomRight',
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
    layout: 'bottomRight',
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

$(function() {
  $("[data-notyConfirm]").click(function(ev) {
    displayConfirm(ev, $(this));
    return false;
  });
});