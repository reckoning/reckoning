# frozen_string_literal: true

require "highline/import"

class Db < Thor
  include Thor::Actions

  desc "dump", "Create new Database dump"
  def dump
    require "./config/environment"

    database_url = ENV.fetch("DATABASE_URL", nil)

    run %(pg_dump -Fc --no-acl --no-owner #{database_url} -f dumps/latest.dump)
  end
end
