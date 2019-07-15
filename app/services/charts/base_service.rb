# frozen_string_literal: true

module Charts
  class BaseService
    attr_accessor :scope, :datasets, :labels

    def initialize(scope)
      @scope = scope
      @datasets = []
      @labels = []

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

    private def new_dataset(name, color = random_color)
      {
        name: name,
        data: [],
        zone: nil,
        color: color
      }
    end

    private def colors
      @colors ||= [
        '#428bca',
        '#3071a9'
      ]
    end

    private def background_colors
      @background_colors ||= [
        '#dcdcdc',
        '#c3c3c3'
      ]
    end

    private def random_color
      colors[rand(0..1)]
    end
  end
end
