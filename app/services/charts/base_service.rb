module Charts
  class BaseService
    attr_accessor :scope, :datasets

    def initialize(scope)
      @scope = scope
      @datasets = []

      generate_datasets
    end

    def generate_datasets
      raise NotImplementedError
    end

    private def new_dataset(key, color = random_color, area = true)
      {
        key: key,
        values: [],
        color: color,
        area: area
      }
    end

    private def colors
      @colors ||= [
        "#428bca",
        "#3071a9"
      ]
    end

    private def background_colors
      @background_colors ||= [
        "#dcdcdc",
        "#c3c3c3"
      ]
    end

    private def random_color
      colors[rand(0..1)]
    end
  end
end
