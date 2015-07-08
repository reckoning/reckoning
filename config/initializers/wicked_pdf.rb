if Rails.env.development?
  WickedPdf.config = {
    exe_path: '/usr/local/bin/wkhtmltopdf'
  }
end
