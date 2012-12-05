FactoryGirl.define do

factory :customer, class: Billingly::Customer do
  email 'user@example.com'
  
  factory :deactivated_customer do
    deactivated_since 10.days.ago
    deactivation_reason 'debtor'
  end

  factory :trial_expired_customer do
    deactivated_since 10.days.ago
    deactivation_reason 'trial_expired'
  end
end

end
