# frozen_string_literal: true

require 'typhoeus'

class Schema < Thor
  include Thor::Actions

  def self.exit_on_failure?
    true
  end

  desc 'update', 'Fetch Schema and regenerate ts client'
  def update
    invoke :fetch

    run('yarn run generate-api-client')
  end

  desc 'fetch', 'Fetch Schema Stoplight'
  def fetch
    require './config/environment'

    raw_data = fetch_remote(api_schema_url)

    File.write(Rails.root.join("public/schema-#{api_version}.yaml"), raw_data)
  end

  no_commands do
    private def fetch_remote(url)
      response = Typhoeus.get(url, followlocation: true)

      unless response.success?
        puts "Unable to fetch URL: \"#{url}\"!"
        exit 1
      end

      response.body
    end

    private def api_schema_url
      ENV['API_SCHEMA_BASE_URL'] ||
      "https://stoplight.io/api/v1/projects/reckoning/reckoning/nodes/reference/schema-#{api_version}.yaml?deref=optimizedBundle"
    end

    private def api_version
      Rails.configuration.app.api_version
    end
  end
end
