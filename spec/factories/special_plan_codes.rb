FactoryGirl.define do

factory :promo_code, class: Billingly::SpecialPlanCode do 
  association :plan, factory: :pro_50_monthly
  bonus_amount 5
  code '1714714777552'
end

end
