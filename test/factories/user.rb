FactoryGirl.define do
  factory :user do
    after :create, &:confirm!
    email "will@star.fleet"
    password "jlpicard"
    enabled true
    address

    trait :without_address do
      address { nil }
    end

    trait :admin do
      email "jeanluc@star.fleet"
      password "enterprise"
      admin true
    end

    trait :disabled do
      enabled false
    end
  end
end
