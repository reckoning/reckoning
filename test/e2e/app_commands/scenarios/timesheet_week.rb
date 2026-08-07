# Seeds a signed-in-able user with the `new_timesheet` Flipper flag on
# and one task that already has a timer in the CURRENT ISO week, so the
# week-view grid renders a row.
#
# The tasks API (`Api::V1::TasksController#index`) inner-joins timers for
# the current user + requested week when `weekDate` is given, so a task
# with no timer that week is invisible in the grid — hence the seeded
# timer. `save(validate: false)` mirrors `signed_out_user.rb`: the
# Account/Project validations need Stripe setup the e2e env omits.
account = Account.find_or_initialize_by(name: "Enterprise")
account.save(validate: false)

email = "will@star.fleet"
user = User.find_by(email: email)
unless user
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

Flipper.enable(:new_timesheet)

customer = account.customers.build(name: "E2E Customer")
customer.save(validate: false)

project = customer.projects.build(name: "E2E Project", rate: 100)
project.save(validate: false)

task = project.tasks.build(name: "E2E Task")
task.save(validate: false)

# Monday of the current week: always inside the default week view, and a
# known cell (index 0) so the spec can edit a different, empty day.
timer = Timer.new(user: user, task: task, date: Date.current.beginning_of_week, value: 1.0)
timer.save(validate: false)
