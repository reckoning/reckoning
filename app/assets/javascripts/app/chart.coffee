window.Chart =
  maxValue: (datasets) ->
    maxValue = 0;
    $.each datasets, (index, dataset) ->
      return if dataset.disabled
      $.each dataset.values, (_i, value) ->
        newValue = parseFloat(value.y)
        if maxValue < newValue
          maxValue = Math.ceil(newValue / 500) * 500

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

      chart.forceY([0, Chart.maxValue(data)])

      chart.tooltip.headerFormatter (d) ->
        '<h3>' + moment(d).format('MMMM') + '</h3>'

      chart.tooltip.valueFormatter (d) ->
        accounting.formatMoney(d, {symbol: '€', format: '%v %s', decimal: ',', thousand: '.'})

      chart.xAxis
        .tickPadding(10)
        .showMaxMin(false)
        .tickValues(Chart.ticks(data, true))
        .tickFormat (d) ->
          moment(d).startOf('month').format('MMM')

      chart.yAxis
        .tickPadding(10)
        .tickFormat (d) ->
          d / 1000 + 'k' if d

      chart.dispatch.on 'stateChange', (e) ->
        chart.forceY([0, Chart.maxValue(data)])

      d3.select(id + ' svg')
        .datum(data)
        .call(chart)

      nv.utils.windowResize(chart.update)

      chart

  timersChart: (id, data) ->
    nv.addGraph ->
      chart = nv.models.multiBarChart()
        .margin({top: 20, right: 10, bottom: 40, left: 15})
        .showControls(false)
        .stacked(true)

      chart.tooltip.headerFormatter (data) ->
        '<h3>' + moment(data).format('MMMM') + '</h3>'
    #     .tooltip(function(key, x, y, e, graph) {
    # #           return "<h3>" + key + "</h3><p>" + (decimalToTime(e.value) || "0:00") + "h " + I18n.t('labels.chart.on_date') + " " + x + "</p>";
    # #         });
    # #
      chart.xAxis
        .showMaxMin(false)
        .tickFormat (d) ->
          moment(d).format('D. MMM YY')

      chart.yAxis
        .tickFormat (d) ->
          d3.format('d')(d || 0)

      d3.select(id + ' svg')
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
