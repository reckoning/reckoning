# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class ActionDispatch::Routing::Mapper
  def template(name)
    get name => "templates#show"
  end
end
# rubocop:enable Style/ClassAndModuleChildren
