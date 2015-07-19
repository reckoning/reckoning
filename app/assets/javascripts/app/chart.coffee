window.Chart =
  generateSeries: (datasets, suffix) ->
    suffix ?= ' €'
    series = []
    for dataset, i in datasets
      data = _.map dataset.data, (value) -> parseFloat(value)
      series.push
        color: dataset.color
        name: dataset.name
        marker:
          symbol: 'circle'
          enabled: false
        data: data
        tooltip:
          valueSuffix: suffix
        zoneAxis: 'x'
        zones: [
          {value: dataset.zone}
          {dashStyle: 'shortdash'}
        ]
    series

  generateMonthCategories: (labels) ->
    categories = []
    for month, i in labels
      date = moment(month)
      categories.push {short: date.format("MMM"), long: date.format("MMMM"), date: date.format("DD. MMMM")}
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
      plotOptions:
        series:
          point:
            events:
              mouseOver: ->
                $("#{id} .highcharts-xaxis-labels span").removeClass('hover')
                $("#{id} .highcharts-xaxis-labels span:contains(#{@category.short})").addClass('hover')
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
        events:
          load: (e) ->
            segments = []
            width = @plotWidth / @pointCount
            lastPosition = -1
            for position in @xAxis[0].tickPositions
              segmentPosition = @plotLeft
              segmentWidth = 0
              for i in [0..@pointCount - 1]
                if i <= position
                  segmentPosition += width
                  if i > lastPosition
                    segmentWidth += width

              segments.push
                position: segmentPosition
                width: segmentWidth

              lastPosition = position

            for segment, i in segments
              $label = $($(id).find('.highcharts-xaxis-labels span')[i])
              $label.css('left', segment.position - (segment.width / 2) - ($label.width() / 2) - 1)

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
      plotOptions:
        series:
          point:
            events:
              mouseOver: ->
                $("#{id} .highcharts-xaxis-labels span").removeClass('hover')
                $("#{id} .highcharts-xaxis-labels span:contains(#{@category.short})").addClass('hover')
      xAxis: [{
        categories: @generateMonthCategories(data.labels),
        crosshair: true,
        title:
          text: null
        labels:
          format: '{value.short}'
          useHTML: true
        tickPositions: data.ticks
      }],
      yAxis:
        min: if parseInt(data.datasets[0].data[0], 10) is 0 then undefined else 0
        startOnTick: false
        labels:
          useHTML: true
          format: '{value}k €'
          formatter: ->
            value = if @value < 1000 then @value else "#{@value / 1000.0}k"
            "#{value} €"
        title:
          text: null
        plotLines: [{
          value: data.budget
          color: '#d9534f'
          width: 2
          label:
            text: "#{I18n.t("labels.chart.project.budget_estimate")}: #{accounting.formatMoney(data.budget, {symbol: '€', format: '%v %s', decimal: ',', thousand: '.'})}"
        }]
      tooltip:
        shared: true
        headerFormat: '<div class="highcharts-tooltip-header"><b>{point.key.date}</b></div>'
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

$(document).on 'mouseleave', '.chart', ->
  $(@).find('.highcharts-xaxis-labels span').removeClass('hover')


$ ->
  Highcharts.setOptions
    lang:
      noData: I18n.t("labels.chart.no_data")

  if $('#invoices-chart').length && invoicesChartData
    Chart.invoicesChart('#invoices-chart', invoicesChartData)

  if $('#project-budget-chart').length && projectBudgetChartData
    Chart.budgetChart('#project-budget-chart', projectBudgetChartData)

