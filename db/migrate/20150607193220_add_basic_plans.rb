class AddBasicPlans < ActiveRecord::Migration
  def up
    [
      { code: "basic", quantity: 1 },
      { code: "plus", quantity: 5, featured: true, discount: "plus" },
      { code: "premium", quantity: 10, discount: "premium" }
    ].each do |plan_data|
      plan = Plan.new(
        stripe_plan_id: "base",
        code: plan_data[:code],
        featured: plan_data[:featured] || false,
        quantity: plan_data[:quantity]
      )
      if plan.save
        puts "Creating Plan #{plan_data}"
      else
        raise "Error Creating Plan #{plan_data[:code]} with Errors: #{plan.errors.to_yaml}"
      end
    end
  end

  def down
  end
end
