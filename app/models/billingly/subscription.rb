module Billingly
  class Subscription < ActiveRecord::Base
    has_many :invoices
  end
end
