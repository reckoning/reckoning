# encoding: utf-8
# frozen_string_literal: true
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    can :update, User, id: user.id
    can :update, Account, id: user.account_id

    can :connect, :dropbox

    can [:read, :create, :destroy, :check, :archive, :send], Invoice, account_id: user.account_id
    can :update, Invoice do |invoice|
      %i(created charged).include?(invoice.current_state.to_sym) && invoice.account_id == user.account_id
    end
    can :pay, Invoice do |invoice|
      %i(charged).include?(invoice.current_state.to_sym) && invoice.account_id == user.account_id
    end
    can :charge, Invoice do |invoice|
      %i(created).include?(invoice.current_state.to_sym) && invoice.account_id == user.account_id
    end

    can :two_factor_qrcode, User
    can :manage, Customer, account_id: user.account_id
    can :manage, Project, customer: { account_id: user.account_id }
    can :manage, Task, project: { customer: { account_id: user.account_id } }
    can :manage, Timer, user_id: user.id
    can :manage, :timesheet

    can :read, :expenses do
      user.account.feature_expenses?
    end

    can :manage, Expense do |expense|
      expense.account_id == user.account_id && user.account.feature_expenses?
    end

    can :manage, ExpenseImport do |_expense|
      user.account.feature_expenses?
    end

    setup_admin_abilities if user.admin?
  end

  def setup_admin_abilities
    can :manage, Account
    can :manage, User
  end
end
