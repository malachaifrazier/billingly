FactoryGirl.define do
  factory :subscription, class: Billingly::Subscription do 
    customer
    
    factory :monthly do
      periodicity :monthly
      description 'monthly subscription for 9.9'
      amount 9.9
      payable_upfront false
      
      factory :first_month do
        subscribed_on 1.month.ago
      end
      
      factory :fourth_month do
        subscribed_on 4.month.ago
        after :create do |it, _|
          (0..2).each do |index|
            from = it.subscribed_on + index.months
            to = from + 1.month
            it.invoices.create!(
              customer: it.customer,
              amount: it.amount,
              period_start: from,
              period_end: to,
              due_on: to + 10.days
           )
          end
        end
      end
    end

    factory :yearly do
      periodicity :yearly
      description 'yearly subscription for 99.99'
      amount 99.99
      payable_upfront true

      factory :first_year do
        subscribed_on Date.today
      end

      factory :fourth_year do
        subscribed_on 4.years.ago
        after :create do |it, _|
          (0..2).each do |index|
            from = it.subscribed_on + index.years
            to = from + 1.year
            it.invoices.create!(
              customer: it.customer,
              amount: it.amount,
              period_start: from,
              period_end: to,
              due_on: to + 10.days
           )
          end
        end
      end
    end

  end
end
