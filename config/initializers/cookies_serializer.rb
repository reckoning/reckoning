# Be sure to restart your server when you modify this file.

# `:marshal` is RCE-risky: an attacker who exfiltrates `secret_key_base`
# (or who finds a deserialization gadget in any loaded gem) can craft a
# cookie that pops a shell on deserialize. `:json` is the safe default
# and what Rails 7.0+ ships with on new apps.
#
# Migration note: active sessions live in Rails.cache (Redis), not in
# cookies, so this switch doesn't log anyone out. The Devise "remember
# me" cookie and any other signed/encrypted cookies created with the
# marshal serializer become unreadable — users who had "remember me"
# set will need to log in once.
Rails.application.config.action_dispatch.cookies_serializer = :json
