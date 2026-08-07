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

# These are the PRODUCTION values, byte-identical to
# config/credentials/production.yml.enc. They are injected here so a production
# dump works locally — DEVISE_OTP_SECRET is the otp_secret_encryption_key, so
# without it live OTP tokens cannot be validated against imported accounts.
#
# The shared config/credentials.yml.enc holds different values, and ENV wins over
# credentials for all four (ENV.fetch(..., credentials.x)), so removing these
# changes local behaviour. Drop them once local production-dump work stops.
#
# The live server sets none of these — it reads them from production credentials
# via RAILS_MASTER_KEY. Confirmed against reckoning/infrastructure-legacy.
SECRET_KEY_BASE=op://Reckoning/SECRET_KEY_BASE_LIVE/credential

DEVISE_SECRET=op://Reckoning/DEVISE_LIVE/secret
DEVISE_JWT_SECRET=op://Reckoning/DEVISE_LIVE/jwt_secret
DEVISE_OTP_SECRET=op://Reckoning/DEVISE_LIVE/otp_secret

# No ACTIVE_RECORD_ENCRYPTION_* here: config/credentials.yml.enc already supplies
# the same values production uses, and credentials win over the initializer's
# ENV fallback.
