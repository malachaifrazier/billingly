class CreatePlans < ActiveRecord::Migration
  def up
    Billingly::Plan.create!(
      name: 'Good Guy',
      description: 'The world would be a better place with more people like you.',
      periodicity: 1.month,
      amount: 10.0,
      payable_upfront: true,
      grace_period: 5.days,
      awesomeness_level: 2
    )
    Billingly::Plan.create!(
      name: 'Awesome',
      description: 'Children look up to you, and if they try hard the may end up being half as awesome as you are now',
      periodicity: 6.months,
      amount: 50.0,
      payable_upfront: true,
      grace_period: 5.days,
      awesomeness_level: 10
    )
    Billingly::Plan.create!(
      name: 'Excelent',
      description: 'Democrats, Republicans and Anarchists would all agree in supporting you running for president at the same time.',
      periodicity: 9.months,
      amount: 80.0,
      payable_upfront: true,
      grace_period: 5.days,
      awesomeness_level: 50
    )
    Billingly::Plan.create!(
      name: 'A Saint',
      description: 'Your highness, your holiness, we are not worthy.',
      periodicity: 1.year,
      amount: 100.0,
      payable_upfront: true,
      grace_period: 5.days,
      awesomeness_level: 100
    )
  end

  def down
    Billingly::Plan.destroy_all
  end
end
