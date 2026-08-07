# Development environment, with secrets referenced from the Reckoning 1Password
# vault rather than stored in plaintext. Resolved by `bin/op`:
#
#   bin/op rails server
#   bin/op rails console
#
# This file is committed — it contains references, not secrets. Put machine- or
# worktree-specific overrides (ports, WORKTREE_SUFFIX) in .env.local, which is
# gitignored and read after this file.

RAILS_ENV=development
PORT=8240
DB_PORT=8241
REDIS_URL=redis://localhost:8242
APP_DIR=.
SHARED_DIR=.

SECRET_KEY_BASE=op://Reckoning/SECRET_KEY_BASE_DEV/credential

DEVISE_SECRET=op://Reckoning/DEVISE_DEV/secret
DEVISE_JWT_SECRET=op://Reckoning/DEVISE_DEV/jwt_secret
DEVISE_OTP_SECRET=op://Reckoning/DEVISE_DEV/otp_secret

# Development keys only — production reads its encryption keys from
# config/credentials/production.yml.enc. These will not decrypt production data.
ACTIVE_RECORD_ENCRYPTION__PRIMARY_KEY=op://Reckoning/ACTIVE_RECORD_ENCRYPTION_DEV/primary_key
ACTIVE_RECORD_ENCRYPTION__DETERMINISTIC_KEY=op://Reckoning/ACTIVE_RECORD_ENCRYPTION_DEV/deterministic_key
ACTIVE_RECORD_ENCRYPTION__KEY_DERIVATION_SALT=op://Reckoning/ACTIVE_RECORD_ENCRYPTION_DEV/key_derivation_salt

RECAPTCHA_KEY=op://Reckoning/RECAPTCHA_DEV/credential
GOOGLE_API_KEY=op://Reckoning/GOOGLE_API_KEY_DEV/credential
