# frozen_string_literal: true

class Plan < ApplicationRecord
  validates :code, :quantity, :base_price, :interval, :stripe_plan_id, presence: true

  before_validation :prefill_from_base_plan, on: :create

  def self.base
    @base ||= find_by(code: 'basic')
  end

  def prefill_from_base_plan
    stripe_plan = Stripe::Plan.retrieve(stripe_plan_id)
    begin
      stripe_discount = Stripe::Coupon.retrieve(code)
    rescue Stripe::InvalidRequestError => _e
      Rails.logger.info 'Discount Coupon not present'
    end

    self.base_price = stripe_plan.amount
    self.interval = stripe_plan.interval
    self.discount = stripe_discount.percent_off if stripe_discount.present?
  rescue Stripe::InvalidRequestError => _e
    errors.add(:stripe_plan_id, 'Invalid')
    false
  end

  def description
    I18n.t("plans.name.#{code}", price: price)
  end

  def amount
    base_price * quantity
  end

  def name
    code.capitalize
  end

  def price
    if discount
      Money.new(amount * (100 - discount))
    else
      Money.new(amount)
    end
  end

  def to_builder
    Jbuilder.new do |plan|
      plan.id id
      plan.code code
      plan.name name
      plan.description description
      plan.price price.cents
      plan.quantity quantity
      plan.interval interval
      plan.featured featured
    end
  end
end
