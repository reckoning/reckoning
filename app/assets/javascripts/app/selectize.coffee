class App.Selectize
  init: ->
    $('select.js-selectize').selectize()

    $('select.js-expense-selectize').selectize
      render:
        option_create: selectizeCreateTemplate
      create: (input, callback) ->
        fetch ApiBasePath + Routes.v1_expense_types_path(),
          headers: ApiHeaders
          method: 'POST'
          body: JSON.stringify({name: input})
        .then (response) ->
          response.json()
        .then (result) ->
          $selectize = $('select.js-expense-selectize')[0].selectize
          data = {
            value: result.id,
            text: result.name
          }
          $selectize.addOption data
          $selectize.addItem result.id
          callback data

        .catch (error) ->
          callback()

    $('select.js-customer-selectize').selectize
      render:
        option_create: selectizeCreateTemplate
      create: (input, callback) ->
        fetch ApiBasePath + Routes.v1_customers_path(),
          headers: ApiHeaders
          method: 'POST'
          body: JSON.stringify({name: input})
        .then (response) ->
          response.json()
        .then (result) ->
          $selectize = $('select.js-customer-selectize')[0].selectize
          data = {
            value: result.id,
            text: result.name
          }
          $selectize.addOption data
          $selectize.addItem result.id
          callback data

        .catch (error) ->
          callback()
