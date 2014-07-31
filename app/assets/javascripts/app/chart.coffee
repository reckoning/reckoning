window.loadInvoicesChart = ->
  if $('#invoices-chart').length && invoicesChartData
    data = invoicesChartData

    nv.addGraph ->
      chart = nv.models.lineChart()
        .margin({top: 20, right: 10, bottom: 40, left: 70})
        .noData(I18n.t("labels.chart.no_data"))
        .x (d) ->
          return d[0]
        .y (d) ->
          return d[1]
        .useInteractiveGuideline(true)
        .transitionDuration(500)

      chart.xAxis
        .showMaxMin(false)
        .staggerLabels(true)
        .tickFormat (d) ->
          return moment(d).startOf('month').format("MMMM")

      chart.yAxis
        .tickFormat (d) ->
          return accounting.formatMoney(d, {symbol: "€", format: "%v %s", decimal: ',', thousand: '.'})

      d3.select('#invoices-chart svg')
        .datum(invoicesChartData)
        .transition().duration(500).call(chart)

      nv.utils.windowResize(chart.update)

      return chart

window.loadTimersChart = ->
  if $('#timers-chart').length && timersChartData
    data = [
      {
        key: I18n.t("labels.chart.timers.headline"),
        values: timersChartData
      }
    ]

    nv.addGraph ->
      chart = nv.models.multiBarChart()
        .margin({top: 20, right: 10, bottom: 40, left: 15})
        .noData(I18n.t("labels.chart.no_data"))
        .showControls(false)
        .stacked(true)
        .tooltip (key, x, y, e, graph) ->
          return "<h3>#{key}</h3><p>#{decimalToTime(e.value) || "0:00"}h #{I18n.t('labels.chart.on_date')} #{x}</p>"

      chart.xAxis
        .showMaxMin(false)
        .scale(d3.time.scale())
        .tickFormat (d) ->
          return moment(d).format("D. MMM YY")

      chart.yAxis
        .tickFormat (d) ->
          return d3.format('d')(d || 0)

      d3.select('#timers-chart svg')
        .datum(timersChartData)
        .transition().duration(500).call(chart)

      nv.utils.windowResize(chart.update)

      return chart
