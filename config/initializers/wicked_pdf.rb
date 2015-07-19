if Rails.env.development? || Rails.env.test?
  WickedPdf.config = {
    exe_path: '/usr/local/bin/wkhtmltopdf'
  }
end
