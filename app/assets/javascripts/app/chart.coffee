Chart.defaults.global.responsive = true;

window.loadInvoicesChart = ->
  d3.locale
    decimal: ".",
    thousands: ",",
    grouping: [3],
    currency: ["", "€"],
    dateTime: "%a %b %e %X %Y",
    date: "%m/%d/%Y",
    time: "%H:%M:%S",
    periods: ["AM", "PM"],
    days: ["Sonntag", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
    shortDays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
    months: ["Jannuar", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"],
    shortMonths: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dec"]

  if $('#new-invoices-chart').length && newInvoicesChartData
    for i in [0...newInvoicesChartData.data.length]
      newInvoicesChartData.data[i] = MG.convert.date(newInvoicesChartData.data[i], 'date')

    MG.data_graphic
      data: newInvoicesChartData.data
      full_width: true
      height: 300
      target: '#new-invoices-chart'
      legend: newInvoicesChartData.labels
      legend_target: '.legend'
      x_accessor: 'date'
      y_accessor: ['value_month', 'value_sum', 'value_month_prev', 'value_sum_prev']
      aggregate_rollover: true
      animate_on_load: true
      interpolate: 'linear'
      point_size: 3
      xax_format: d3.time.format('%b')
      top: 20
      left: 30
      show_secondary_x_label: false


  if $('#invoices-chart').length && invoicesChartData
    ctx = document.getElementById("invoices-chart").getContext("2d")
    invoicesChart = new Chart(ctx).Line invoicesChartData,
      bezierCurve: false
      pointDotRadius: 4
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
      pointDotRadius: 4
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
