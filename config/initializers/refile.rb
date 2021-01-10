# frozen_string_literal: true

if Rails.env.production?
  require 'fog/aws'
  require "refile/fog"

  credentials = {
    provider: 'AWS',
    aws_access_key_id: Rails.application.secrets.s3_key,
    aws_secret_access_key: Rails.application.secrets.s3_secret,
    region: Rails.application.secrets.s3_region,
    endpoint: Rails.application.secrets.s3_endpoint,
    directory: Rails.application.secrets.s3_space
  }

  Refile.cache = Refile::Fog::Backend.new(prefix: 'cache', **credentials)
  Refile.store = Refile::Fog::Backend.new(prefix: 'store', **credentials)
end
