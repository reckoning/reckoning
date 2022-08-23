# frozen_string_literal: true

set :stage, :production
set :rails_env, 'production'
set :appsignal_env, :production
set :branch, 'main'
set :branch_spec, ->(rev) { available_tags.include?(rev) }
set :branch_spec_type, 'a git tag'

server 'reckoning.mortik.xyz', user: 'reckoning', roles: %w[web app db migration]

def available_tags
  `git tag --list --sort=version:refname`.split("\n").select { |tag| tag.match(/^\d/) }
end
