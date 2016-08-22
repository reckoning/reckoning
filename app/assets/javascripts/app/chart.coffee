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

  generateCategories: (labels) ->
    categories = []
    for month, i in labels
      date = moment(month)
      dateFormattedShort = I18n.l("date.formats.month_short", date.toDate())
      dateFormattedLong = I18n.l("date.formats.month", date.toDate())
      dateFormatted = I18n.l("date.formats.chart", date.toDate())
      console.log(dateFormatted)
      console.log(dateFormattedShort)
      console.log(dateFormattedLong)
      categories.push {
        short: dateFormattedShort,
        long: dateFormattedLong,
        date: dateFormatted
      }
    categories

  getCurrentWeek: (labels) ->
    currentWeek = {start: 0, end: 0}
    for month, i in labels
      date = moment(month)
      if date >= moment()
        currentWeek.start = i - 1.5
        currentWeek.end = i - 0.5
        break
    currentWeek

  baseChartOptions: (id, data) ->
    currentWeek = @getCurrentWeek(data.labels)
    {
      chart:
        type: 'line'
      credits:
        enabled: false
      title:
        text: null
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
      xAxis:
        categories: @generateCategories(data.labels)
        title:
          text: null
        labels:
          format: '{value.short}'
          useHTML: true
          reserveSpace: false
          autoRotation: 0
          step: 1
        plotBands: [{
          color: 'rgba(155, 200, 255, 0.2)'
          from: currentWeek.start
          to: currentWeek.end
        }]
      yAxis:
        startOnTick: false
        title:
          text: null
      tooltip:
        useHTML: true
        backgroundColor: null
        borderWidth: 0
        shadow: false
        style:
          padding: 0
        shared: true
        crosshairs: [{
          color: 'rgba(200, 200, 200, 0.2)'
        }]
        headerFormat: '<div class="highcharts-tooltip-header"><b>{point.key.long}</b></div>'
        pointFormatter: ->
          value = accounting.formatMoney(@y)
          "<div><div style='float: left;'><span style='color:#{@color}'>\u25CF</span> #{@series.name}: </div><div style='float: right;'><b>#{value}</b></div></div>"
      navigation:
        buttonOptions:
          enabled: false
      legend:
        enabled: false
      series: @generateSeries(data.datasets)
    }

  invoicesChart: (id, data) ->
    options = @baseChartOptions(id, data)
    options.yAxis['labels'] =
      format: '{value}k €'
      formatter: ->
        value = if @value < 1000 then @value else "#{@value / 1000.0}k"
        "#{value} €"

    $(id).highcharts(options)

  budgetChart: (id, data) ->
    options = @baseChartOptions(id, data)
    options.chart['events'] =
      load: (e) ->
        return unless data.datasets[0]
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
    options.xAxis['tickPositions'] = data.ticks
    options.yAxis['min'] = if data.datasets[0] && parseInt(data.datasets[0].data[0], 10) is 0 then undefined else 0
    options.yAxis.startOnTick = false
    options.yAxis['labels'] =
      useHTML: true
      format: '{value}k €'
      formatter: ->
        value = if @value < 1000 then @value else "#{@value / 1000.0}k"
        "#{value} €"
    options.yAxis['plotLines'] = [{
      value: data.budget
      color: '#777777'
      width: 2
      label:
        useHTML: true
        style:
          fontSize: null
        text: "<span class='label label-default highcharts-plotline-budget'>#{I18n.t("labels.chart.project.budget_estimate")}: #{accounting.formatMoney(data.budget)}</span>"
    }]
    options.tooltip.headerFormat = '<div class="highcharts-tooltip-header"><b>{point.key.date}</b></div>'

    $(id).highcharts(options)

$(document).on 'mouseleave', '.chart', ->
  $(@).find('.highcharts-xaxis-labels span').removeClass('hover')


document.addEventListener "turbolinks:load", ->
  Highcharts.setOptions
    lang:
      noData: I18n.t("labels.chart.no_data")

  if $('#invoices-chart').length && invoicesChartData
    Chart.invoicesChart('#invoices-chart', invoicesChartData)

  if $('#project-budget-chart').length && projectBudgetChartData
    Chart.budgetChart('#project-budget-chart', projectBudgetChartData)
