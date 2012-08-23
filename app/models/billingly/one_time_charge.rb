module Billingly
  class OneTimeCharge < ActiveRecord::Base
    attr_accessible :charge_on, :amount, :description
  end
end
