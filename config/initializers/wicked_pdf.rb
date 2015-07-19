if Rails.env.development? || Rails.env.test?
  WickedPdf.config = {
    exe_path: `which wkhtmltopdf`.strip
  }
end
