require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rvm'

set :user, 'reckoning'
set :forward_agent, true

set :deploy_to, '/home/reckoning'
set :domain, '10.0.0.10'
set :branch, 'master'
set :repository, 'git@github.com:reckoning/app.git'

if ENV['on'] == "live"
  set :domain, 'reckoning.io'
  set :branch, 'live'
  set :repository, 'git@github.com:mortik/reckoning.git'
end

set :shared_paths, [
  '.wti',
  'public/assets',
  'public/uploads',
  'files',
  'log',
  'config/secrets.yml',
  'config/database.yml',
]

task :environment do
  invoke :"rvm:use[ruby-2.2.2@default]"
end

desc "Deploys the current version to the server."
task deploy: :environment do
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'deploy:cleanup'

    to :launch do
      queue "sudo supervisorctl restart reckoning:*"
    end
  end
end

task restart: :environment do
  queue "sudo supervisorctl restart reckoning:*"
end
