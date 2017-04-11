class App.Selectize
  init: ->
    $('select.js-selectize').selectize()

    $('select.js-expense-selectize').selectize
      render:
        option_create: selectizeCreateTemplate
      create: (input, callback) ->
        fetch: ->
          fetch ApiBasePath + Routes.v1_expense_types_path(),
            headers: ApiHeaders
            method: 'POST'
            body: {name: input}
          .then (response) ->
            response.json()
          .then (result) ->
            data = {
              value: result.id,
              text: result.name
            }
            @addOption data
            @addItem result.id
            callback data

          .catch (error) ->
            callback()

    $('select.js-customer-selectize').selectize
      render:
        option_create: selectizeCreateTemplate
      create: (input, callback) ->
        fetch: ->
          fetch ApiBasePath + Routes.v1_customers_path(),
            headers: ApiHeaders
            method: 'POST'
            body: {name: input}
          .then (response) ->
            response.json()
          .then (result) ->
            data = {
              value: result.id,
              text: result.name
            }
            @addOption data
            @addItem result.id
            callback data

          .catch (error) ->
            callback()
