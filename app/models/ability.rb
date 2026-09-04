# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.account&.trial_expired?
      setup_expired_trial_abilities(user)
      setup_admin_abilities if user.admin?
      return
    end

    can %i[read update], User, id: user.id
    can :update, Account, id: user.account_id

    setup_invoice_abilities(user)
    setup_offer_abilities(user)

    can :two_factor_qrcode, User
    can :manage, Customer, account_id: user.account_id
    can :manage, Project, customer: {account_id: user.account_id}
    can :manage, Task, project: {customer: {account_id: user.account_id}}
    can :manage, Timer, user_id: user.id
    can :manage, :timesheet

    setup_expenses_abilities(user.account_id) if user.account.feature_expenses?

    # setup_logbook_abilities(user.account_id) if user.account.feature_logbook?

    setup_admin_abilities if user.admin?
  end

  def setup_invoice_abilities(user)
    can %i[read create update destroy check send], Invoice, account_id: user.account_id

    can :pay, Invoice do |invoice|
      %i[charged].include?(invoice.current_state.to_sym) && invoice.account_id == user.account_id
    end

    can :charge, Invoice do |invoice|
      %i[created].include?(invoice.current_state.to_sym) && invoice.account_id == user.account_id
    end
  end

  def setup_offer_abilities(user)
    can %i[read create destroy check], Offer, account_id: user.account_id

    can :update, Offer do |offer|
      (offer.created? || offer.bided?) && offer.account_id == user.account_id
    end
  end

  def setup_expenses_abilities(account_id)
    can :read, :expenses

    can :manage, Expense do |expense|
      expense.account_id == account_id
    end

    can :manage, ExpenseImport
  end

  def setup_logbook_abilities(account_id)
    can :read, :logbook

    can :manage, Vessel do |vessel|
      vessel.account_id == account_id
    end

    can :manage, Tour do |tour|
      tour.account_id == account_id
    end

    can :manage, Waypoint do |waypoint|
      waypoint.tour && waypoint.tour.account_id == account_id
    end

    can :index, :manufacturer
  end

  # An expired trial keeps everything readable — the data belongs to the
  # account either way — and stops it being changed. Written out rather than
  # layered on top of the normal rules with `cannot`, because `can :manage`
  # grants custom actions too: a blanket `cannot %i[create update destroy]`
  # would leave `send` on an invoice, `stop` on a timer and every other verb
  # wide open. Missing a `can` here costs a screen; missing a `cannot` there
  # costs the whole feature.
  #
  # Account settings stay editable so the account can be put right.
  def setup_expired_trial_abilities(user)
    can %i[read two_factor_qrcode], User, id: user.id
    can %i[read update], Account, id: user.account_id

    can :read, Customer, account_id: user.account_id
    can :read, Project, customer: {account_id: user.account_id}
    can :read, Task, project: {customer: {account_id: user.account_id}}
    can :read, Timer, user_id: user.id
    can :read, Invoice, account_id: user.account_id
    can :read, Offer, account_id: user.account_id
    can :show, :timesheet

    return unless user.account.feature_expenses?

    can :read, :expenses
    can :read, Expense, account_id: user.account_id
  end

  def setup_admin_abilities
    can :manage, Account
    can :manage, User
  end
end
