module Billingly
  class Invoice < ActiveRecord::Base
    belongs_to :subscription
  end
end
