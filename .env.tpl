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

# No ACTIVE_RECORD_ENCRYPTION_* here on purpose: config/credentials.yml.enc
# already supplies them, and credentials win over the initializer's ENV fallback.
