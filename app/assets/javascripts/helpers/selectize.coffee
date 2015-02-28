window.selectizeCreateTemplate = (data, escape) ->
  '<div class="create"><strong>' + escape(data.input) + '</strong>&hellip; ' + I18n.t("actions.create") + '</div>'
