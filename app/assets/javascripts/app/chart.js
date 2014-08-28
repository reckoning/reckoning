window.loadInvoicesChart = function() {
  if ($('#invoices-chart').length && invoicesChartData) {
    var data = invoicesChartData;
    var maxValues = invoicesMaxValues;

    nv.addGraph(function() {
      chart = nv.models.lineChart()
        .margin({top: 20, right: 10, bottom: 40, left: 70})
        .noData(I18n.t('labels.chart.invoices.no_data'))
        .x(function(d) {
          return d[0];
        })
        .y(function(d) {
          return d[1];
        })
        .useInteractiveGuideline(true)
        .transitionDuration(500)
        .forceY([0, maxValues[0]]);

      chart.xAxis
        .showMaxMin(false)
        .staggerLabels(true)
        .tickFormat(function(d) {
          return moment(d).startOf('month').format('MMMM');
        });

      chart.yAxis
        .staggerLabels(true)
        .tickFormat(function(d) {
          return accounting.formatMoney(d, {symbol: '€', format: '%v %s', decimal: ',', thousand: '.'});
        });

      chart.dispatch.on('stateChange', function() {
        var maxValue = 0;
        $.each(maxValues, function(index, value) {
          if (!chart.state().disabled[index]) {
            if (maxValue < value) {
              maxValue = value;
            }
          }
        });

        chart.forceY([0, maxValue]);
      });

      d3.select('#invoices-chart svg')
        .datum(invoicesChartData)
        .transition().duration(500).call(chart);

      nv.utils.windowResize(chart.update);

      return chart;
    });
  }
};

window.loadTimersChart = function() {
  if ($('#timers-chart').length && timersChartData) {
    var data = [
      {
        key: I18n.t('labels.chart.timers.headline'),
        values: timersChartData
      }
    ];

    nv.addGraph(function() {
      chart = nv.models.multiBarChart()
        .margin({top: 20, right: 10, bottom: 40, left: 15})
        .noData(I18n.t('labels.chart.timers.no_data'))
        .showControls(false)
        .stacked(true)
        .tooltip(function(key, x, y, e, graph) {
          return "<h3>" + key + "</h3><p>" + (decimalToTime(e.value) || "0:00") + "h " + I18n.t('labels.chart.on_date') + " " + x + "</p>";
        });

      chart.xAxis
        .showMaxMin(false)
        .scale(d3.time.scale())
        .tickFormat(function(d) {
          return moment(d).format('D. MMM YY');
        });

      chart.yAxis
        .tickFormat(function(d) {
          return d3.format('d')(d || 0);
        });

      d3.select('#timers-chart svg')
        .datum(timersChartData)
        .transition().duration(500).call(chart);

      nv.utils.windowResize(chart.update);

      return chart;
    });
  }
};
