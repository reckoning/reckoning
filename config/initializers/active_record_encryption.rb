# frozen_string_literal: true

# ActiveRecord encryption keys.
#
# Production / staging / dev read these from `config/credentials.yml.enc`
# (decrypted by `RAILS_MASTER_KEY`). CI runners triggered by Dependabot
# PRs and forks don't inherit repo secrets, so `RAILS_MASTER_KEY` is
# blank and credentials decrypt to nil — which then 500s any controller
# that touches a model with `encrypts` (e.g. `devise-two-factor`'s
# `otp_secret`). This env-var fallback lets those CI runs boot Rails
# with throwaway keys.
#
# The fallback runs in `after_initialize` and mutates the already-built
# `ActiveRecord::Encryption.config` because Rails applies encryption
# config from credentials inside an `on_load(:active_record_encryption)`
# hook that fires *before* `config/initializers/*` load — assigning to
# `config.active_record.encryption.*` here would be too late to reach it.
# We only fill keys credentials left blank, so real environments keep
# using their credential-backed keys untouched.

Rails.application.config.after_initialize do
  encryption = ActiveRecord::Encryption.config

  # `has_*?` reads the raw ivar (`.presence`); the plain readers raise when a
  # key is blank, so we must not touch them before deciding to fall back.
  unless encryption.has_primary_key?
    encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"].presence
  end
  unless encryption.has_deterministic_key?
    encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"].presence
  end
  unless encryption.has_key_derivation_salt?
    encryption.key_derivation_salt = ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"].presence
  end
end
