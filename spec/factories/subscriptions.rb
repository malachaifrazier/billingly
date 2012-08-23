FactoryGirl.define do

factory :subscription do 
  name 'plan name, plan description'
  customer 

  factory :monthly_in_advance do 
    length :monthly
    amount 9.9
  end
    
  factory :yearly_in_advance do 
    length :yearly
    amount 99.99
  end
end

end
