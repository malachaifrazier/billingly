FactoryGirl.define do
  factory :subscription, class: Billingly::Subscription do 
    customer
    
    factory :monthly do
      periodicity :monthly
      description 'monthly subscription for 9.9'
      amount BigDecimal.new('9.9')
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
      amount BigDecimal.new('99.99')
      payable_upfront true
      
      factory :first_year do
        subscribed_on Date.today

        trait :overdue do
          subscribed_on 30.days.ago
        end

        trait :deactivated do
          association :customer, factory: :deactivated_customer
        end

        after :create do |it, _|
          from = it.subscribed_on
          to = from + 1.year
          it.invoices.create!(
            customer: it.customer,
            amount: it.amount,
            period_start: from,
            period_end: to,
            due_on: from + 10.days
         )
        end
      end

      factory :fourth_year do
        subscribed_on 4.years.ago
        after :create do |it, _|
          (0..3).each do |index|
            from = it.subscribed_on + index.years
            to = from + 1.year
            it.invoices.create!(
              customer: it.customer,
              amount: it.amount,
              period_start: from,
              period_end: to,
              due_on: from + 10.days
           )
          end
        end
      end
    end
  end
end
