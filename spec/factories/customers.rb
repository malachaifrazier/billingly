FactoryGirl.define do

factory :customer, class: Billingly::Customer do
  customer_since Date.today
end

end
