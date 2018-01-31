# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    can :update, User, id: user.id
    can :update, Account, id: user.account_id

    can :connect, :dropbox

    setup_invoice_abilities(user)

    can :two_factor_qrcode, User
    can :manage, Customer, account_id: user.account_id
    can :manage, Project, customer: { account_id: user.account_id }
    can :manage, Task, project: { customer: { account_id: user.account_id } }
    can :manage, Timer, user_id: user.id
    can :manage, :timesheet

    setup_expenses_abilities(user.account_id) if user.account.feature_expenses?

    setup_logbook_abilities(user.account_id) if user.account.feature_logbook?

    setup_admin_abilities if user.admin?
  end

  def setup_invoice_abilities(user)
    can %i[read create destroy check archive send], Invoice, account_id: user.account_id

    can :update, Invoice do |invoice|
      %i[created charged].include?(invoice.current_state.to_sym) && invoice.account_id == user.account_id
    end

    can :pay, Invoice do |invoice|
      %i[charged].include?(invoice.current_state.to_sym) && invoice.account_id == user.account_id
    end

    can :charge, Invoice do |invoice|
      %i[created].include?(invoice.current_state.to_sym) && invoice.account_id == user.account_id
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

  def setup_admin_abilities
    can :manage, Account
    can :manage, User
  end
end
