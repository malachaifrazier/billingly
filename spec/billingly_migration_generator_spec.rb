require 'spec_helper'

describe BillinglyMigrationGenerator do
  it 'Creates the migration file' do
    `rm -rf spec/dummy/db/*`
    Dir['spec/dummy/db/migrate/*.rb'].none? do |name|
      name =~ /create_billingly_tables.rb$/
    end.should be_true

    `cd spec/dummy; rails generate billingly_migration`
    Dir['spec/dummy/db/migrate/*.rb'].any? do |name|
      name =~ /create_billingly_tables.rb$/
    end.should be_true

    `rm -rf spec/dummy/db/*`
  end
  
end


=begin

Generamos Invoice (1): (period_start, period_end, etc)
  :charge:
    | name: 5mb for $1 dolar a day.
    | kind: subscription
    | price: $1
    | started_using_on: 1 ene 2012
    | stopped_using_on: null
    :payment_request
      | invoice: (1)
      | amount: +31
    :expense
      | invoice: (1)
      | amount: -31

  :payment_request
    | invoice: (1)
    | amount: +100
    | charge:
      | name: Setup fee
      | kind: one-time
      | price: $1
      | started_using_on: 1 ene 2012
      | stopped_using_on: null
  :balance
    | invoice: (1)
    | amount: -100

  :payment_request
    | invoice: (1)
    | amount: +180
    | charge:
      | name: 5mb for $0.5 dolars a day, paid upfront
      | kind: one-time
      | price: $0.5
      | started_using_on: 1 ene 2012
      | stopped_using_on: 1 ene 2013
  :balance
    | invoice: (1)
    | amount: -180
  
Recibimos payment:
  * Usuario pago 400 via paypal.
  Dinero                                  |     800 |
  deuda en balance del usuario            |         |      800

Saldamos cuenta (y mandamos receipt):
  deuda en balance del usurio             |     200 |
  pago a cobrar por uso                             |      200

  deuda a contraer en balance del usuario |     100 |
  deuda en balance del usuario                      |     100

  deuda en balance del usurio             |     100 |
  pago a cobrar                                     |     100

  deuda en balance del usuario            |     300 |     
  Pago a cobrar por adelantado anual      |         |     300

  deuda a contraer en balance del usuario |     300 |
  deuda por pago adel. anual              |         |     300
    
Mayor:

    Dinero                                  |     800 |

    Pago a cobrar por uso                   |       0 |
    Pago a cobrar                           |       0 |
    Pago a cobrar por adelantado anual      |       0 |

    Servicios prestados                     |         |      200
    deuda en balance del usuario            |         |      300
    deuda por pago adel. anual              |         |      300

Generamos Invoice (facturacion):
  Pago a cobrar por uso                   |     200 |
  Pago a cobrar                           |     100 |
  Pago a cobrar por adelantado anual      |     300 |      
  Servicios prestados                     |         |      200
  deuda a contraer en balance del usuario |         |      400 
  
Recibimos payment:
  * Usuario pago 400 via paypal.
  Dinero                                  |     800 |
  deuda en balance del usuario            |         |      800


Generamos Invoice (facturacion):
  Dinero                                  |     800 |
  Pago a cobrar por uso                   |       0 |
  Pago a cobrar                           |       0 |
  Pago a cobrar por adelantado anual      |       0 |      
  deuda por pago adel. anual              |         |      300
  Servicios prestados                     |         |      200
  balance                                 |         |      300 
=end
