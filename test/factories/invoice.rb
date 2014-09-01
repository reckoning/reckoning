FactoryGirl.define do
  factory :invoice do
    project
    date Time.now
  end
end
