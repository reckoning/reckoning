Chart.defaults.global.responsive = true;

window.loadInvoicesChart = ->
  if $('#invoices-chart').length && invoicesChartData
    ctx = document.getElementById("invoices-chart").getContext("2d")
    invoicesChart = new Chart(ctx).Line invoicesChartData,
      bezierCurve: false
      pointDotRadius: 5
      scaleLabel: (data) ->
        {label: accounting.formatMoney(data.value)}
      multiTooltipTemplate: (data) ->
        formatedValue = accounting.formatMoney(data.value)
        "#{data.datasetLabel} | #{formatedValue}"

window.loadProjectChart = ->
  if $('#project-budget-chart').length && projectBudgetChartData
    ctx = document.getElementById("project-budget-chart").getContext("2d")
    invoicesChart = new Chart(ctx).Line projectBudgetChartData,
      bezierCurve: false
      pointDotRadius: 6
      scaleBeginAtZero: true
      scaleLabel: (data) ->
        {label: accounting.formatMoney(data.value)}
      tooltipTemplate: (data) ->
        formatedValue = accounting.formatMoney(data.value)
        "#{formatedValue} | #{data.label.title}"

  if $('#project-timers-chart').length && projectTimersChartData
    ctx = document.getElementById("project-timers-chart").getContext("2d")
    invoicesChart = new Chart(ctx).Bar projectTimersChartData,
      scaleBeginAtZero: true
      scaleLabel: (data) ->
        formatedValue = "#{parseFloat(data.value).toFixed(1)} h"
        {label: formatedValue}
      tooltipTemplate: (data) ->
        formatedValue = "#{parseFloat(data.value).toFixed(1)} h"
        "#{formatedValue} | #{data.label.title}"
