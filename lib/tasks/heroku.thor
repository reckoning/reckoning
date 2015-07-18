require "thor"

class Heroku < Thor
  include Thor::Actions

  desc "deploy", "Start Deployment"
  option :migrate, type: :boolean, default: false, aliases: :m
  def deploy
    create_backup

    p "Deploying..."
    run_clean "git push heroku live:master"

    run_migrate if options[:migrate]

    run_reindex if options[:reindex]

    restart_app if options[:migrate]

    p "Deployment finished"
  end

  desc "download_backup", "Start Backup Download"
  def download_backup
    p "Starting Download for App #{app}"
    run_clean "curl -o lastest.dump $(heroku pg:backups public-url --app #{app})"
    p "Download for App #{app} finished"
  end

  desc "import_local", "Import Dump into Local DB"
  def import_local
    run "pg_restore --verbose --clean --no-acl --no-owner -h localhost -d reckoning_dev latest.dump"
  end

  desc "c", "Start Rails Console"
  def c
    invoke :console
  end

  desc "console", "Start Rails Console"
  def console
    run_clean "heroku run rails c --app #{app}"
  end

  desc "logs", "Show Logs"
  option :n, type: :numeric, default: 300
  def logs
    run_clean "heroku logs -n #{options[:n]} -t --app #{app}"
  end

  desc "migrate", "Migrate Database"
  def migrate
    run_migrate
    restart_app
  end

  desc "restart", "Restart App"
  def restart
    restart_app
  end

  desc "backup", "Backup Database"
  def backup
    create_backup
  end

  no_commands do
    private def run_migrate
      p "Migrate DB"
      run_clean "heroku maintenance:on --app #{app}"
      run_clean "heroku run rake db:migrate --app #{app}"
      run_clean "heroku maintenance:off --app #{app}"
    end

    private def restart_app
      p "Restart #{app}"
      run_clean "heroku restart --app #{app}"
    end

    private def create_backup
      p "Backup DB"
      run_clean "heroku pg:backups capture DATABASE_URL --app #{app}"
    end

    private def app
      @app ||= "reckoningio"
    end

    private def run_clean(command)
      Bundler.with_clean_env { run(command) }
    end
  end
end
