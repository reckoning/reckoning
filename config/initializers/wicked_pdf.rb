if Rails.env.development? || Rails.env.test?
  if ENV["TRAVIS_CI"]
    WickedPdf.config = {
      exe_path: "/usr/bin/wkhtmltopdf"
    }
  else
    WickedPdf.config = {
      exe_path: `which wkhtmltopdf`.strip
    }
  end
end
