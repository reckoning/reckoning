# frozen_string_literal: true

# ActiveRecord encryption keys.
#
# Production / staging / dev read these from `config/credentials.yml.enc`
# (decrypted by `RAILS_MASTER_KEY`). CI runners triggered by Dependabot
# PRs and forks don't inherit repo secrets, so `RAILS_MASTER_KEY` is
# blank and credentials decrypt to nil — which then 500s any controller
# that touches a model with `encrypts` (e.g. `devise-two-factor`'s
# `otp_secret`). This env-var fallback lets those CI runs boot Rails
# with throwaway keys. Real environments override neither path because
# the env vars aren't set; credentials win.

primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"]
deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"]
key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"]

if primary_key.present?
  Rails.application.config.active_record.encryption.primary_key = primary_key
end

if deterministic_key.present?
  Rails.application.config.active_record.encryption.deterministic_key = deterministic_key
end

if key_derivation_salt.present?
  Rails.application.config.active_record.encryption.key_derivation_salt = key_derivation_salt
end
