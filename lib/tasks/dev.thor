require 'highline/import'

class Dev < Thor
  include Thor::Actions

  desc "pre_push", "Pre Push Check"
  def pre_push
    run "bundle exec rake"
    run "bundle exec rubocop"
  end
end
