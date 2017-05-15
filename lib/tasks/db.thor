# frozen_string_literal: true

require 'highline/import'

class Db < Thor
  include Thor::Actions

  desc "dump", "Create new Database dump"
  def dump
    require "yaml"

    config = YAML.safe_load(IO.read("config/database.yml"))
    database_url = config["production"]["url"]

    run %(pg_dump -Fc --no-acl --no-owner #{database_url} -f dumps/latest.dump)
  end
end
