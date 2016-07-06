window.App.Project =
  rate: 0
  budget: 0
  updateRate: (ev, $element) ->
    App.Project.rate = $("#project_rate").val()
    $("#project_budget_hours").val ($("#project_budget").val() / App.Project.rate).toFixed(2)

  updateBudget: (ev, $element) ->
    return if parseInt(App.Project.rate, 10) is 0

    $element ||= $(ev.target)
    if $element.attr('id') is "project_budget"
      $("#project_budget_hours").val ($element.val() / App.Project.rate).toFixed(2)
    else if $element.attr('id') is "project_budget_hours"
      $("#project_budget").val ($element.val() * App.Project.rate).toFixed(2)

$(document).on 'change', "#project_budget", App.Project.updateBudget
$(document).on 'change', "#project_budget_hours", App.Project.updateBudget
$(document).on 'change', "#project_rate", App.Project.updateRate

document.addEventListener "turbolinks:load", ->
  App.Project.rate = $('#project_rate').val()
