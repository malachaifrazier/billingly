FactoryGirl.define do

factory :plan, class: Billingly::Plan do 
  grace_period 10.days

  factory :pro_50_monthly do 
    name 'Pro 50'
    description '50GB for 9,99 a month.'
    periodicity 1.month
    amount BigDecimal.new('9.9')
    payable_upfront false
  end
    
  factory :pro_50_yearly do
    name 'Pro 50'
    description '50GB for 99,99 yearly.'
    periodicity 1.year
    amount BigDecimal.new('99.99')
    payable_upfront true
  end

  factory :pro_100_monthly do 
    name 'Pro 100'
    description '100GB for 19,99 a month.'
    periodicity 1.month
    amount BigDecimal.new('19.99')
    payable_upfront false
  end
    
  factory :pro_100_yearly do
    name 'Pro 100'
    description '100GB for 199,99 yearly.'
    periodicity 1.year
    amount BigDecimal.new('199.99')
    payable_upfront true
  end
end

end
