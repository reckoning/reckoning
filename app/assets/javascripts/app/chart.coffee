Chart.defaults.global.responsive = true;

window.loadInvoicesChart = ->
  if $('#invoices-chart').length && invoicesChartData
    ctx = document.getElementById("invoices-chart").getContext("2d")
    invoicesChart = new Chart(ctx).Line invoicesChartData,
      bezierCurve: false
      scaleLabel: (data) ->
        {label: accounting.formatMoney(data.value)}
      tooltipTemplate: (data) ->
        formatedValue = accounting.formatMoney(data.value)
        "#{formatedValue} | #{data.label.title} | #{data.datasetLabel}"
      multiTooltipTemplate: (data) ->
        formatedValue = accounting.formatMoney(data.value)
        "#{data.datasetLabel} | #{formatedValue}"
