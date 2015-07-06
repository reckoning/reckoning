window.Chart =
  maxValue: (datasets, steps) ->
    steps ?= 1
    maxValue = 0
    $.each datasets, (index, dataset) ->
      return if dataset.disabled
      $.each dataset.values, (_i, value) ->
        newValue = parseFloat(value.y)
        if maxValue < newValue
          maxValue = Math.ceil(newValue / steps) * steps

    maxValue
  ticks: (datasets) ->
    ticks = []
    $.each datasets, (_i, dataset) ->
      return if dataset.disabled
      $.each dataset.values, (index, value) ->
        if ticks.indexOf(value.x) is -1
          ticks.push value.x

    ticks

  currencyChart: (id, data) ->
    nv.addGraph ->
      chart = nv.models.lineChart()
        .margin({top: 20, right: 10, bottom: 30, left: 40})
        .options
          transitionDuration: 300

      chart.forceY([0, Chart.maxValue(data, 500)])

      chart.tooltip.headerFormatter (d) ->
        '<h3>' + moment(d).format('MMMM') + '</h3>'

      chart.tooltip.valueFormatter (d) ->
        accounting.formatMoney(d, {symbol: '€', format: '%v %s', decimal: ',', thousand: '.'}) if d

      chart.xAxis
        .tickPadding(10)
        .showMaxMin(false)
        .tickValues(Chart.ticks(data, true))
        .tickFormat (d) ->
          moment(d).startOf('month').format('MMM.')

      chart.yAxis
        .tickPadding(10)
        .tickFormat (d) ->
          d / 1000 + 'k' if d

      chart.dispatch.on 'stateChange', (e) ->
        chart.forceY([0, Chart.maxValue(data, 500)])

      d3.select(id).append('svg')
        .datum(data)
        .call(chart)

      nv.utils.windowResize(chart.update)

      chart

  timersChart: (id, data) ->
    nv.addGraph ->
      chart = nv.models.multiBarChart()
        .margin({top: 20, right: 10, bottom: 30, left: 40})
        .showControls(false)

      chart.forceY([0, Chart.maxValue(data)])

      chart.tooltip.headerFormatter (data) ->
        '<h3>' + moment(data).format('MMMM') + '</h3>'

      chart.tooltip.valueFormatter (data) ->
        (decimalToTime(data) || "0:00") + "h "

      chart.xAxis
        .tickPadding(10)
        .showMaxMin(false)
        .tickFormat (d) ->
          moment(d).format('MMM. YYYY')

      chart.yAxis
        .tickPadding(10)
        .tickFormat (d) ->
          d3.format('d')(d || 0)

      chart.dispatch.on 'stateChange', (e) ->
        chart.forceY([0, Chart.maxValue(data)])

      d3.select(id).append('svg')
        .datum(data)
        .transition().duration(500)
        .call(chart)

      nv.utils.windowResize(chart.update)

      chart

$ ->
  if $('#invoices-chart').length && invoicesChartData
    Chart.currencyChart('#invoices-chart', invoicesChartData)

  if $('#project-budget-chart').length && projectBudgetChartData
    Chart.currencyChart('#project-budget-chart', projectBudgetChartData)

  if $('#project-timers-chart').length && projectTimersChartData
    Chart.timersChart('#project-timers-chart', projectTimersChartData)
