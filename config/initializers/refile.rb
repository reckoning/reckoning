# encoding: utf-8
# frozen_string_literal: true
if Rails.env.production?
  require "refile/s3"

  aws = {
    access_key_id: Rails.application.secrets[:aws_s3]["key_id"],
    secret_access_key: Rails.application.secrets[:aws_s3]["access_key"],
    region: "eu-central-1",
    bucket: Rails.application.secrets[:aws_s3]["bucket"],
  }

  Refile.cache = Refile::S3.new(prefix: "cache", **aws)
  Refile.store = Refile::S3.new(prefix: "store", **aws)
end
