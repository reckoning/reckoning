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
        "#dcdcdc",
        "#c3c3c3",
        "#428bca",
        "#3071a9"
      ]
    end

    private def random_color
      colors[rand(0..3)]
    end
  end
end
