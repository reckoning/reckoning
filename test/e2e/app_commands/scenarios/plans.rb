# The plans the welcome page prices and the signup form offers. Created
# without validations for the same reason `signed_out_user` does it:
# `Plan#prefill_from_base_plan` reads the plan back from Stripe on create,
# and the e2e environment deliberately has no Stripe setup.
[
  {code: "basic", base_price: 900, quantity: 1, interval: "month", featured: false},
  {code: "plus", base_price: 1900, quantity: 1, interval: "month", featured: true}
].each do |attributes|
  next if Plan.exists?(code: attributes[:code])

  plan = Plan.new(attributes.merge(stripe_plan_id: "plan_#{attributes[:code]}"))
  plan.save(validate: false)
end
