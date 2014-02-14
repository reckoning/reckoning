window.App.Timesheet ?= {}

window.App.Timesheet.convertTimeField = (val) ->
  if val.match(':')
    val = timeToDecimal(val)

  return decimalToTime(val)

window.App.Timesheet.enableSubmit = ->
  $('table.timesheet button.btn-primary').prop('disabled', false)

window.App.Timesheet.addTask = ($element, week_date) ->
  task_id = $('#select-task').val()
  if task_id.length
    xhr.abort() if xhr
    xhr = $.ajax
      url: r(add_task_weeks_path)
      data: {week: {start_date: week_date}, task_id: task_id}
      method: 'POST'
      success: (result) ->
        $element.closest('.modal').modal('hide')
        window.location.reload()
      error: ->
        displayError i18n.t("messages.timesheet.add_task.failure")
  else
    setTimeout ->
      displayWarning i18n.t("messages.timesheet.add_task.warning")
      $element.button('reset')
    , 250

$(document).on 'change', '.timesheet-day input[type=text]', App.Timesheet.enableSubmit

$ ->
  $('table.timesheet .timesheet-day input[type=text]').focusout (ev) ->
    $input = $(@)
    $input.val(App.Timesheet.convertTimeField($input.val()))

    td = $input.parent('td')
    col = $(td).parent().children().index(td)

    sum = 0.0
    col_sum = 0.0
    $("table.timesheet tbody tr").each ->
      value = $(@).find("td:eq(#{col}) input[type=text]").val()
      col_sum += timeToDecimal(value) if value.length
      if $(@)[0] isnt $input.closest('tr')[0]
        value = $(@).find('td.timesheet-row-sum').text()
        sum += timeToDecimal(value) if value && parseInt(value, 10) isnt 0

    col_sum = decimalToTime(col_sum) || 0
    $("table.timesheet tfoot tr td:eq(#{col})").text(col_sum)

    row_sum = 0.0
    $input.closest('tr').find('td.timesheet-day').each ->
      value = $(@).find("input[type=text]").val()
      row_sum += timeToDecimal(value) if value.length

    row_sum = decimalToTime(row_sum) || 0
    $input.closest('tr').find("td.timesheet-row-sum").text(row_sum)

    sum += parseInt(row_sum, 10)
    $("table.timesheet tfoot tr td.timesheet-sum").text(decimalToTime(sum))


  if $('#select-project').length && $('#select-task').length
    $select_project = $('#select-project').selectize
      onChange: (value) ->
        return if !value.length
        select_task.disable()
        select_task.clearOptions()
        select_task.load (callback) ->
          xhr.abort() if xhr
          xhr = $.ajax
            url: r(project_tasks_path, value),
            success: (results) ->
              select_task.enable()
              callback(results)
            error: ->
              callback()

    $select_task = $('#select-task').selectize
      valueField: 'id'
      labelField: 'name'
      searchField: ['name']
      create: (input, callback) ->
        project_id = $('#select-project').val()
        xhr.abort() if xhr
        xhr = $.ajax
          url: r(project_tasks_path, project_id)
          data: {task: {name: input}}
          method: 'POST'
          success: (result) =>
            data = {id: result.id, name: result.name}
            callback(data)
            @addOption data
            @addItem data.id
          error: ->
            callback()

    select_task = $select_task[0].selectize
    select_project = $select_project[0].selectize

    select_task.disable()
