# Reckoning

[![Circle CI](https://circleci.com/gh/reckoning/app.svg?style=svg)](https://circleci.com/gh/reckoning/app)
[![Code Climate](https://codeclimate.com/github/reckoning/app/badges/gpa.svg)](https://codeclimate.com/github/reckoning/app)
[![Test Coverage](https://codeclimate.com/github/reckoning/app/badges/coverage.svg)](https://codeclimate.com/github/reckoning/app)

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

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

To run Reckoning on your local machine you need to install:

- postgresql with activated hstore on the used database
- WKHTMLTOPDF to generate Invoices

## ToDo:

- Tests

## Future features

[![Stories in Ready](https://badge.waffle.io/mortik/reckoning.png?label=ready&title=Ready)](http://waffle.io/mortik/reckoning)

- Project Landingpages
- Integrations: Google Drive, Harvest Import etc.
- Custom Logos and Colors for Invoices
- Templates for Invoices
- Expanses
- ...

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
6.
