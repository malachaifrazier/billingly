module Billingly
  class Plan < ActiveRecord::Base
    attr_accessible :name, :description, :periodicity, :amount, :payable_upfront
  end
end
