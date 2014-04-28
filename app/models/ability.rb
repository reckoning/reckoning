class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    can :update, User, id: user.id

    can [:read, :create, :destroy, :check], Invoice, user_id: user.id
    can :update, Invoice do |invoice|
      %w(created charged).include?(invoice.state) && invoice.user_id == user.id
    end
    can :pay, Invoice do |invoice|
      %w(charged).include?(invoice.state) && invoice.user_id == user.id
    end
    can :charge, Invoice do |invoice|
      %w(created).include?(invoice.state) && invoice.user_id == user.id
    end

    can :manage, Customer, user_id: user.id
    can :manage, Project, customer: { user_id: user.id }
    can :manage, Week, user_id: user.id
    can :manage, Task, project: { customer: { user_id: user.id } }
    can :manage, Timer, week: { user_id: user.id }
  end
end
