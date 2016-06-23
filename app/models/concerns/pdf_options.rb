require 'active_support/concern'

module PdfOptions
  extend ActiveSupport::Concern
  included do
    def pdf_options(file)
      {
        pdf: file
      }.merge(inline_pdf_options).merge(whicked_pdf_options)
    end

    def inline_pdf_options
      {
        layout: "layouts/pdf",
        locals: { resource: self }
      }
    end

    def whicked_pdf_options
      {
        header: {
          content: ApplicationController.new.render_to_string("shared/pdf_header", inline_pdf_options)
        },
        footer: {
          content: ApplicationController.new.render_to_string("shared/pdf_footer", inline_pdf_options)
        },
        margin: {
          top: 30,
          bottom: 38,
          left: 18,
          right: 18
        }
      }
    end
  end
end
