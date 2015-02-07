# Reckoning

[![Codeship Status for reckoning/app](https://codeship.com/projects/929e0e70-9089-0132-4c0b-66130ee6610f/status?branch=master)](https://codeship.com/projects/61545)

Reckoning is a simple tool for invoicing

## Features
- Customer and Project Database
- Create basic Invoices with multiple Positions
- Generate PDFs for Invoices
- Basic Dashboard with Current Invoices and their current states (Charged, Paid) and information about due payments.
- Send Invoices via E-Mail to Customers
  - Mail Templates for each Customer
- Time tracking and Import of Timesheets (beta)

## Setup

See [provisioning Repo](https://github.com/reckoning/provisioning) for a basic Setup.

To run Reckoning on your local machine you need to install:

- postgresql with activated hstore on the used database
- [weasyprint](http://weasyprint.org/) to generate Invoices 

## ToDo:

- Translations
- Tests

## Future features

- Templates for Invoices
- Offer generation
- Bank account support
- ...
  
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
6. 
