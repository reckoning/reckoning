if Rails.env.development? || Rails.env.test?
  WickedPdf.config = if ENV["TRAVIS_CI"]
                       {
                         exe_path: "/usr/bin/wkhtmltopdf"
                       }
                     else
                       {
                         exe_path: `which wkhtmltopdf`.strip
                       }
                     end
end
