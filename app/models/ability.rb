class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    can :update, User, id: user.id

    can :manage, Invoice, user_id: user.id
    can :manage, Customer, user_id: user.id
    can :manage, Project, customer: { user_id: user.id }
  end
end
