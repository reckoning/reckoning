# This will guess the User class
FactoryGirl.define do
  factory :user do
    after :create, &:confirm!
    email "will@star.fleet"
    password "jlpicard"
  end

  factory :admin, class: User do
    email "jeanluc@star.fleet"
    password "enterprise"
    admin true
  end
end
