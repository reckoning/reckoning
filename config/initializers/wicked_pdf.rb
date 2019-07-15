# frozen_string_literal: true

WickedPdf.config = { exe_path: `which wkhtmltopdf`.strip } if Rails.env.development? || Rails.env.test?
