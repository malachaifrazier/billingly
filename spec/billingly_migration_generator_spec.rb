require 'spec_helper'

describe BillinglyMigrationGenerator do
end


=begin
Generamos Invoice (1): (period_start, period_end, etc)
  r+ expenses                       200
  p+ debt                                200

Recibimos payment:
  a+ cash                           300
  g+ income                              300

----- Check: debt < cash
  p- debt                           200
  a- cash                                200

Generamos Invoice (2): (period_start, period_end, etc)
  a+ ioweyou                        200
  p+ services_to_provide                 200

Recibimos payment:
  a+ cash                           300
  g+ income                              300

----- Check: services_to_provide < cash
  a+ paid_upfront                   200
  p- services_to_provide            200
  a- cash                                200
  a- ioweyou                             200

Upfront-paid subscription period ends.
  r+ expense                       200
  a- paid_upfront                       200 

=end
