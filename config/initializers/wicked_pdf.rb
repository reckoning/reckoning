# frozen_string_literal: true

if Rails.env.development? || Rails.env.test?
  WickedPdf.config = {
    exe_path: `which wkhtmltopdf`.strip
  }
end
