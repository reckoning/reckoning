class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.admin?
      can :manage, :all
    end

    can :update, User, id: user.id

    can :manage, Invoice, user_id: user.id
    can :manage, Customer, user_id: user.id
    can :manage, Project, customer: { user_id: user.id }
    can :manage, Week, user_id: user.id
    can :manage, Task, project: { customer: { user_id: user.id } }
    can :manage, Timer, week: { user_id: user.id }
  end
end
