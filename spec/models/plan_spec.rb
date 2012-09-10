require 'spec_helper'

describe Billingly::Plan do
  it 'creates a plan' do
    Billingly::Plan.create(
      name: 'A plan',
      description: 'the description',
      periodicity: 'monthly',
      amount: 10.0,
      payable_upfront: false
    )
  end
end
