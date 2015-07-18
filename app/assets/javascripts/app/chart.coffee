window.Chart =
  generateSeries: (datasets, suffix) ->
    suffix ?= ' €'
    series = []
    for dataset, i in datasets
      data = _.map dataset.data, (value) -> parseFloat(value) if value
      series.push
        color: dataset.color
        name: dataset.name
        marker:
          symbol: 'circle'
        data: data
        tooltip:
          valueSuffix: suffix
        zoneAxis: 'x'
        zones: [
          {
            value: dataset.zone
          }
          {
            dashStyle: 'shortdash'
          }
        ]
    series

  generateMonthCategories: (labels) ->
    categories = []
    for month, i in labels
      date = moment(month)
      categories.push {short: date.format("MMM"), long: date.format("MMMM")}
    categories


  invoicesChart: (id, data) ->
    $(id).highcharts
      chart:
        type: 'line'
      credits:
        enabled: false
      title:
        text: null
        useHTML: true
      noData:
        style:
          fontSize: "18px"
          fontWeight: "bold"
          color: "#ccc"
      xAxis: [{
        categories: @generateMonthCategories(data.labels),
        crosshair: true,
        title:
          text: null
        labels:
          format: '{value.short}'
          useHTML: true
      }],
      yAxis:
        startOnTick: false
        labels:
          format: '{value}k €'
          formatter: ->
            value = if @value < 1000 then @value else "#{@value / 1000.0}k"
            "#{value} €"
        title:
          text: null
      tooltip:
        shared: true
        headerFormat: '<div class="highcharts-tooltip-header"><b>{point.key.long}</b></div>'
        pointFormatter: ->
          value = accounting.formatMoney(@y, {symbol: '€', format: '%v %s', decimal: ',', thousand: '.'})
          "<div><div style='float: left;'><span style='color:#{@color}'>\u25CF</span> #{@series.name}: </div><div style='float: right;'><b>#{value}</b></div></div>"
        useHTML: true
      navigation:
        buttonOptions:
          enabled: false
      legend:
        enabled: false
        useHTML: true
        verticalAlign: 'top'
      series: @generateSeries(data.datasets)

  budgetChart: (id, data) ->
    $(id).highcharts
      chart:
        type: 'line'
      credits:
        enabled: false
      title:
        text: null
        useHTML: true
      noData:
        style:
          fontSize: "18px"
          fontWeight: "bold"
          color: "#ccc"
      xAxis: [{
        categories: @generateMonthCategories(data.labels),
        crosshair: true,
        title:
          text: null
        labels:
          format: '{value.short}'
          useHTML: true
      }],
      yAxis:
        labels:
          format: '{value}k €'
          formatter: ->
            value = if @value < 1000 then @value else "#{@value / 1000.0}k"
            "#{value} €"
        title:
          text: null
      tooltip:
        shared: true
        headerFormat: '<div class="highcharts-tooltip-header"><b>{point.key.long}</b></div>'
        pointFormatter: ->
          value = accounting.formatMoney(@y, {symbol: '€', format: '%v %s', decimal: ',', thousand: '.'})
          point = "<div>"
          point = "#{point}<div style='float: left;'><span style='color:#{@color}'>\u25CF</span> #{@series.name}: </div>"
          point = "#{point}<div style='float: right;'><b>#{value}</b></div>"
          point = "#{point}</div>"
          point
        useHTML: true
      navigation:
        buttonOptions:
          enabled: false
      legend:
        enabled: false
        useHTML: true
        verticalAlign: 'top'
      series: @generateSeries(data.datasets)

$ ->
  Highcharts.setOptions
    lang:
      noData: I18n.t("labels.chart.no_data")

  if $('#invoices-chart').length && invoicesChartData
    Chart.invoicesChart('#invoices-chart', invoicesChartData)

  if $('#project-budget-chart').length && projectBudgetChartData
    Chart.budgetChart('#project-budget-chart', projectBudgetChartData)
