class Plan < ActiveRecord::Base
  validates :code, :quantity, :base_price, :interval, :stripe_plan_id, presence: true

  before_validation :prefill_from_base_plan, on: :create

  def self.base
    @base ||= find_by(code: "basic")
  end

  def prefill_from_base_plan
    stripe_plan = Stripe::Plan.retrieve(stripe_plan_id)
    begin
      stripe_discount = Stripe::Coupon.retrieve(code)
    rescue Stripe::InvalidRequestError => _e
      # ignore if no discount present
    end

    self.base_price = stripe_plan.amount
    self.interval = stripe_plan.interval
    self.discount = stripe_discount.percent_off if stripe_discount.present?
  rescue Stripe::InvalidRequestError => _e
    errors.add(:stripe_plan_id, "Invalid")
    return false
  end

  def amount
    base_price * quantity
  end

  def name
    code.capitalize
  end

  def price
    if discount
      format("%g", Money.new(amount * (100 - discount) / 100))
    else
      format("%g", Money.new(amount))
    end
  end

  def to_serialized_json
    PlanSerializer.new(self, {}).to_json
  end
end
