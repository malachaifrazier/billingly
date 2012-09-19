module Billingly
  require 'has_duration'
  class Plan < ActiveRecord::Base
    attr_accessible :name, :plan_code, :description, :periodicity,
      :amount, :payable_upfront, :grace_period
    
    has_duration :grace_period
    validates :grace_period, presence: true

    has_duration :periodicity
    validates :periodicity, presence: true
  end
end
