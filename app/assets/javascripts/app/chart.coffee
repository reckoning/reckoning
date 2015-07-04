window.Chart =
  maxValue: (datasets) ->
    maxValue = 0;
    $.each datasets, (index, dataset) ->
      return if dataset.disabled
      $.each dataset.values, (_i, value) ->
        newValue = parseFloat(value.y)
        if maxValue < newValue
          maxValue = newValue

    maxValue
  ticks: (datasets) ->
    ticks = []
    $.each datasets, (_i, dataset) ->
      return if dataset.disabled
      $.each dataset.values, (index, value) ->
        if index % 2 is 0 && ticks.indexOf(value.x) is -1
          ticks.push value.x

    ticks

  loadInvoices: ->
    if $('#invoices-chart').length && invoicesChartData
      data = invoicesChartData

      nv.addGraph ->
        chart = nv.models.lineChart()
          .margin({top: 20, right: 10, bottom: 40, left: 70})
          .useInteractiveGuideline(true)
          .options
            transitionDuration: 300

        chart.forceY([0, Chart.maxValue(data)])

        chart.interactiveLayer.tooltip.headerFormatter (data) ->
          '<h3>' + data + '</h3>'

        chart.xAxis
          .showMaxMin(false)
          .tickValues(Chart.ticks(data, true))
          .tickFormat (d) ->
            moment(d).startOf('month').format('MMMM')

        chart.yAxis
          .tickFormat (d) ->
            accounting.formatMoney(d, {symbol: '€', format: '%v %s', decimal: ',', thousand: '.'})

        chart.dispatch.on 'stateChange', (e) ->
          chart.forceY([0, Chart.maxValue(data)])

        d3.select('#invoices-chart svg')
          .datum(data)
          .call(chart)

        nv.utils.windowResize(chart.update)

        chart

  loadProject: ->
    if $('#project-budget-chart').length && projectBudgetChartData
      data = projectBudgetChartData

      nv.addGraph ->
        chart = nv.models.lineChart()
          .margin({top: 20, right: 10, bottom: 40, left: 70})
          .options
            transitionDuration: 300

        chart.forceY([0, Chart.maxValue(data)])

        chart.tooltip.headerFormatter (data) ->
          '<h3>' + moment(data).format('MMMM') + '</h3>'

        chart.xAxis
          .showMaxMin(false)
          .tickValues(Chart.ticks(data, true))
          .tickFormat (d) ->
            moment(d).format('MMMM')

        chart.yAxis
          .tickFormat (d) ->
            accounting.formatMoney(d, {symbol: '€', format: '%v %s', decimal: ',', thousand: '.'})

        d3.select('#project-budget-chart svg')
          .datum(projectBudgetChartData)
          .call(chart)

        nv.utils.windowResize(chart.update)

        chart

    if $('#project-timers-chart').length && projectTimersChartData
      data = projectTimersChartData

      console.log projectTimersChartData
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

        d3.select('#project-timers-chart svg')
          .datum(data)
          .transition().duration(500)
          .call(chart)

        nv.utils.windowResize(chart.update)

        chart
