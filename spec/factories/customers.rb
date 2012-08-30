FactoryGirl.define do

factory :customer, class: Billingly::Customer do
  
  factory :deactivated_customer do
    deactivated_since 10.days.ago
  end
end

end
