module Charts
  class BaseService
    attr_accessor :labels, :scope, :datasets

    def initialize(scope)
      @scope = scope
      @datasets = []

      generate_labels
      generate_datasets
    end

    def data
      {
        labels: labels,
        datasets: datasets
      }
    end

    def generate_labels
      raise NotImplementedError
    end

    def generate_datasets
      raise NotImplementedError
    end

    private def new_dataset(label, colorset = random_colorset)
      {
        label: label,
        fillColor: colorset[:fill_color],
        strokeColor: colorset[:stroke_color],
        pointColor: colorset[:point_color],
        pointStrokeColor: colorset[:point_stroke_color],
        pointHighlightFill: colorset[:point_highlight_fill],
        pointHighlightStroke: colorset[:point_highlight_stroke]
      }
    end

    private def colorsets
      @colorsets ||= [
        {
          fill_color: "rgba(220,220,220,0.2)",
          stroke_color: "rgba(220,220,220,1)",
          point_color: "rgba(220,220,220,1)",
          point_stroke_color: "#fff",
          point_highlight_fill: "#fff",
          point_highlight_stroke: "rgba(220,220,220,1)"
        },
        {
          fill_color: "rgba(151,187,205,0.2)",
          stroke_color: "rgba(151,187,205,1)",
          point_color: "rgba(151,187,205,1)",
          point_stroke_color: "#fff",
          point_highlight_fill: "#fff",
          point_highlight_stroke: "rgba(151,187,205,1)"
        }
      ]
    end

    private def random_colorset
      colorsets[rand(0..1)]
    end
  end
end
