# Seeds a confirmed user on a minimal Account so a spec can drive
# Devise sign-in end-to-end. Mirrors the Minitest fixture
# (`test/fixtures/users.yml` — Will Riker on the Enterprise account
# with password "enterprise"). Both `save(validate: false)` calls
# match how Rails fixtures load the same records — the underlying
# Account validations (plan, stripe) need real Stripe setup that
# the e2e environment intentionally doesn't have.
account = Account.find_or_initialize_by(name: "Enterprise")
account.save(validate: false)

email = "will@star.fleet"
unless User.exists?(email: email)
  user = User.new(
    account: account,
    name: "Will Riker",
    email: email,
    encrypted_password: User.new.send(:password_digest, "enterprise"),
    confirmed_at: Time.now,
    enabled: true
  )
  user.save(validate: false)
end
