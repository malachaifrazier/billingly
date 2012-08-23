FactoryGirl.define do

factory :plan, class: Billingly::Plan do 
  factory :pro_50_monthly do 
    name 'Pro 50'
    description '50GB for 9,99 a month.'
    length :monthly
    amount 9.9
    payable_upfront false
  end
    
  factory :pro_50_yearly do
    name 'Pro 50'
    description '50GB for 99,99 yearly.'
    length :yearly
    amount 99.99
    payable_upfront true
  end

  factory :pro_100_monthly do 
    name 'Pro 100'
    description '100GB for 19,99 a month.'
    length :monthly
    amount 19.9
    payable_upfront false
  end
    
  factory :pro_100_yearly do
    name 'Pro 100'
    description '100GB for 199,99 yearly.'
    length :yearly
    amount 199.99
    payable_upfront true
  end
end

end
