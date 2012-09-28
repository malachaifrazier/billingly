# This module serves as an example on how to extend Billingly::Plan

require Billingly::Engine.model_path :plan

class Billingly::Plan
  attr_accessible :awesomeness_level
end
