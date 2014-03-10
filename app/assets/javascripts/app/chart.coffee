window.loadChart = ->
  if $('#timers-chart').length && chartData
    data = [
      {
        key: i18n.t("labels.chart.timers"),
        values: chartData
      }
    ]

    nv.addGraph ->
      chart = nv.models.multiBarChart()
        .margin({top: 20, right: 0, bottom: 40, left: 15})
        .noData(i18n.t("labels.chart.no_data"))
        .showControls(false)
        .stacked(true)
        .tooltip (key, x, y, e, graph) ->
          return "<h3>#{key}</h3><p>#{decimalToTime(e.value) || "0:00"}h #{i18n.t('labels.chart.on_date')} #{x}</p>"

      chart.xAxis
        .showMaxMin(false)
        .scale(d3.time.scale())
        .tickFormat (d) ->
          return moment(d).format("D. MMM YY")

      chart.yAxis
        .tickFormat (d) ->
          return d3.format('d')(d || 0)

      d3.select('#timers-chart svg')
        .datum(chartData)
        .transition().duration(500).call(chart)

      nv.utils.windowResize(chart.update)

      return chart
