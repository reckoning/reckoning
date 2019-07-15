# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class ActionDispatch::Routing::Mapper
  # rubocop:enable Style/ClassAndModuleChildren
  def draw(routes_name)
    instance_eval(File.read(Rails.root.join('config', 'routes', "#{routes_name}.rb")))
  end

  def template(name)
    get name => 'templates#show'
  end
end
