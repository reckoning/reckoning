# frozen_string_literal: true

require "capistrano/setup"
require "capistrano/deploy"
require "capistrano/rbenv"
require "capistrano/rails"
require "capistrano/rails/console"
require "capistrano/data_migrate"

# Sends a deploy marker to AppSignal on `deploy:finished`; the revision and
# environment come from `current_revision` and `:appsignal_env`.
require "appsignal/capistrano"

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
