# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Reckoning::Application.config.secret_token = 'c7ec5574e14b42fd7220c237ffe5742976be1cdd78143f5434990db749de10afe23baa8bc6a646d251fc1a4daeb62132dbac26582128737293f8aafb14e3fd81'
Reckoning::Application.config.secret_key_base = Secrets.secret_key_base
