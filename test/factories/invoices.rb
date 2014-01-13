FactoryGirl.define do
  factory :invoice do
    project
    date Time.now
  end

  factory :customer do
    address
  end

  factory :project do
    customer
    name "Project"
    rate 99.0
  end

  factory :position do
    description "Description"
    hours 50.0
  end
end
